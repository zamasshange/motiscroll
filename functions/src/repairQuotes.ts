import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

import { useFirebaseCliCredential } from "./cliCredential.js";
import { parseGoodreadsQuotes } from "./importGoodreads.js";

const notesPath = join(__dirname, "../../scripts/speaker_notes.json");

interface WikiNote {
  extract: string;
  title: string;
}

function clip(value: string): string {
  const text = value.replace(/\s+/g, " ").trim();
  if (text.length <= 480) return text;
  const cut = text.slice(0, 480);
  const sentence = cut.lastIndexOf(". ");
  if (sentence > 180) return cut.slice(0, sentence + 1);
  return `${cut.replace(/\s+\S*$/, "").trim()}…`;
}

function contextFor(author: string, title: string, url: string): string {
  const book = title.startsWith("Goodreads · ")
    ? title.slice("Goodreads · ".length).trim()
    : "";
  if (book) {
    return `${author} is the person named on the Goodreads page for this line. Goodreads lists it from ${book}.`;
  }
  if (url.includes("goodreads.com")) {
    return `${author} is the person named on the Goodreads page for this line.`;
  }
  if (url.includes("shakespeare.org.uk")) {
    return `William Shakespeare wrote this line. The Shakespeare Birthplace Trust lists it as ${title}.`;
  }
  if (title) {
    return `${author} is the person named with this line. The page that lists it is ${title}.`;
  }
  return `${author} is the person named with this line.`;
}

async function fetchPage(page: number): Promise<string> {
  const url =
    page <= 1
      ? "https://www.goodreads.com/quotes"
      : `https://www.goodreads.com/quotes?page=${page}`;
  const response = await fetch(url, {
    headers: {
      "User-Agent":
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36",
      Accept: "text/html",
    },
  });
  if (!response.ok) throw new Error(`${response.status} from ${url}`);
  return response.text();
}

async function wikiNote(name: string): Promise<WikiNote | null> {
  const title = encodeURIComponent(name.trim().replace(/ /g, "_"));
  const response = await fetch(
    `https://en.wikipedia.org/api/rest_v1/page/summary/${title}`,
    {
      headers: {
        accept: "application/json",
        "User-Agent": "MotiScroll/1.0 (quote catalog; editor@example.com)",
      },
    },
  );
  if (!response.ok) return null;
  const body = (await response.json()) as {
    type?: string;
    extract?: string;
    title?: string;
  };
  if (body.type === "disambiguation") return null;
  const extract = clip(body.extract ?? "");
  const pageTitle = (body.title ?? "").trim();
  if (!extract || !pageTitle) return null;
  return { extract, title: pageTitle };
}

function loadNotes(): Record<string, WikiNote | { reason: string }> {
  if (!existsSync(notesPath)) return {};
  return JSON.parse(readFileSync(notesPath, "utf8")) as Record<
    string,
    WikiNote | { reason: string }
  >;
}

async function main() {
  useFirebaseCliCredential();
  initializeApp({
    projectId: "motiscroll",
    storageBucket: "motiscroll.firebasestorage.app",
  });
  const db = getFirestore();

  const fresh = new Map<string, string>();
  for (let page = 1; page <= 100; page += 1) {
    const html = await fetchPage(page);
    const quotes = parseGoodreadsQuotes(html);
    for (const quote of quotes) fresh.set(`gr-${quote.id}`, quote.text);
    console.log(`goodreads page ${page}: ${quotes.length}, kept ${fresh.size}`);
  }

  const snap = await db.collection("publishedItems").get();
  const notes = loadNotes();
  const names = new Set<string>();
  for (const doc of snap.docs) {
    const data = doc.data();
    const author = String(data.authorName ?? "").trim();
    const did = String(data.deeper?.didYouKnow ?? "").trim();
    if (!author || did) continue;
    if (/^(unknown|anonymous)$/i.test(author)) continue;
    names.add(author);
  }

  const pending = [...names].filter((name) => !notes[name.toLowerCase()]);
  console.log(`wikipedia notes needed for ${pending.length} of ${names.size} speakers`);
  let cursor = 0;
  let looked = 0;
  async function resolveName(name: string) {
    const key = name.toLowerCase();
    try {
      const note = await wikiNote(name);
      notes[key] = note ?? { reason: "no-summary" };
    } catch (error) {
      notes[key] = {
        reason: error instanceof Error ? error.message : "lookup failed",
      };
    }
    looked += 1;
    if (looked % 40 === 0) {
      writeFileSync(notesPath, JSON.stringify(notes));
      console.log(`notes checked ${looked} of ${pending.length}`);
    }
  }
  async function worker() {
    while (cursor < pending.length) {
      const name = pending[cursor];
      cursor += 1;
      await resolveName(name);
    }
  }
  await Promise.all(Array.from({ length: 8 }, () => worker()));
  writeFileSync(notesPath, JSON.stringify(notes));
  console.log(`notes checked ${looked} of ${pending.length}`);

  let batch = db.batch();
  let pendingWrites = 0;
  let textUpdates = 0;
  let contextUpdates = 0;
  let noteUpdates = 0;
  for (const doc of snap.docs) {
    const data = doc.data();
    const author = String(data.authorName ?? "").trim();
    const title = String(data.primarySource?.title ?? "").trim();
    const url = String(data.primarySource?.url ?? "").trim();
    const storedText = String(data.text ?? "");
    const storedContext = String(data.deeper?.context ?? "").trim();
    const storedDid = String(data.deeper?.didYouKnow ?? "").trim();
    const update: Record<string, string> = {};
    const longer = fresh.get(doc.id);
    if (longer && longer.length > storedText.length) {
      update.text = longer;
      textUpdates += 1;
    }
    if (!storedContext && author) {
      update["deeper.context"] = contextFor(author, title, url);
      contextUpdates += 1;
    }
    if (!storedDid && author) {
      const note = notes[author.toLowerCase()];
      if (note && "extract" in note && note.extract) {
        update["deeper.didYouKnow"] =
          `${note.extract} (English Wikipedia, ${note.title}.)`;
        noteUpdates += 1;
      }
    }
    if (Object.keys(update).length === 0) continue;
    batch.update(doc.ref, update);
    pendingWrites += 1;
    if (pendingWrites === 400) {
      await batch.commit();
      batch = db.batch();
      pendingWrites = 0;
    }
  }
  if (pendingWrites > 0) await batch.commit();
  console.log(
    `Updated text ${textUpdates}, context ${contextUpdates}, did you know ${noteUpdates}.`,
  );
}

if (require.main === module) {
  main().catch((error: unknown) => {
    console.error(error);
    process.exit(1);
  });
}
