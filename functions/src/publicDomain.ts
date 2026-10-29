import { FieldValue, getFirestore } from "firebase-admin/firestore";

import { approveItemById } from "./approve.js";
import { fetchText } from "./http.js";
import { slug } from "./resolveAuthors.js";

export interface WorkQuery {
  title: string;
  authorName: string;
  field: string;
  kind: "speech" | "text";
}

export interface ImportLog {
  todos: string[];
  counts: { found: number; added: number; skipped: number; failed: number; needsReview: number; approved: number };
}

export function emptyImportLog(): ImportLog {
  return { todos: [], counts: { found: 0, added: 0, skipped: 0, failed: 0, needsReview: 0, approved: 0 } };
}

export async function importWork(work: WorkQuery, log: ImportLog, limit = 30) {
  const { todos, counts } = log;
  const db = getFirestore();
  const authorId = slug(work.authorName);
  const author = await db.collection("authors").doc(authorId).get();
  if (!author.exists || !author.data()?.wikidataId) {
    todos.push(`${work.title}: ${work.authorName} has no resolved Wikidata id, so no text was imported.`);
    counts.failed += 1;
    return;
  }
  let located = await locateWork(work, log);
  let fetched = located ? await fetchText(located.textUrl) : "";
  if (located?.publisher === "Wikisource" && excerptSentences(fetched, work.authorName).length === 0) {
    const fallback = await locateGutenberg(work);
    if (fallback) {
      located = fallback;
      fetched = await fetchText(fallback.textUrl);
    }
  }
  if (!located) {
    todos.push(`${work.title}: no single Wikisource or Gutenberg page matched the title.`);
    counts.failed += 1;
    return;
  }
  await db.collection("importSources").doc(slug(located.pageTitle)).set(
    {
      url: located.pageUrl,
      type: "public_domain",
      rightsNote: `Hosted by ${located.publisher}, which only carries texts it lists as public domain in the US. An editor still confirms rights per text.`,
      title: located.pageTitle,
      lastRunAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  const translator = /translated by ([^.<\n|]{3,80})/i.exec(fetched)?.[1]?.replace(/\[\[|\]\]/g, "").trim() ?? "";
  const watchUrl = work.kind === "speech" ? await firstOfficialLink(fetched) : "";
  if (work.kind === "speech" && !watchUrl) {
    todos.push(`${work.title}: no official watch URL on the fetched page returned HTTP 200.`);
  }
  const sentences = excerptSentences(fetched, work.authorName);
  counts.found += sentences.length;
  const sourceTitle = translator ? `${located.pageTitle}, translated by ${translator}` : located.pageTitle;
  const picks = spread(sentences, limit);
  let kept = 0;
  for (const sentence of picks) {
    const id = `pd-${authorId}-${hash(sentence.text)}`;
    const ref = db.collection("items").doc(id);
    if ((await ref.get()).exists) {
      counts.skipped += 1;
      continue;
    }
    const speech = work.kind === "speech" && watchUrl.length > 0;
    await ref.set({
      type: speech ? "speech" : "quote",
      text: sentence.text,
      authorId,
      field: work.field,
      moods: [],
      language: "en",
      status: "needs_review",
      verified: false,
      discoveredVia: "public_domain_import",
      wordCount: sentence.words,
      warnings: [],
      rand: Math.random(),
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    await ref.collection("sources").doc("primary").set({
      title: sourceTitle,
      publisher: located.publisher,
      year: null,
      url: located.pageUrl,
      pageOrTimestamp: `sentence ${sentence.index}`,
      sourceType: "primary",
      confidence: "confirmed",
    });
    if (speech) {
      await ref.collection("speech").doc("main").set({
        durationSec: 0,
        watchUrl,
        embedAllowed: false,
        rightsStatus: "public_domain",
        rightsNotes: `Official link found on the fetched page ${located.pageUrl} and checked for HTTP 200.`,
      });
    }
    counts.added += 1;
    kept += 1;
    try {
      await approveItemById(id, "public_domain_import", "", { recount: false });
      counts.approved += 1;
    } catch (error) {
      const reason = error instanceof Error ? error.message : "approval refused";
      await ref.set(
        { status: "needs_review", rejectionReason: reason.slice(0, 500), updatedAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
      counts.needsReview += 1;
      todos.push(`${id}: ${reason}`);
    }
  }
  if (kept === 0 && picks.length === 0) {
    todos.push(`${work.title}: the fetched page produced no excerpt between 8 and 40 words.`);
  }
  return { pageTitle: located.pageTitle, publisher: located.publisher, kept };
}

/// Takes excerpts from across the whole text instead of only the opening pages.
function spread<T>(items: T[], limit: number): T[] {
  if (items.length <= limit) return items;
  const step = items.length / limit;
  return Array.from({ length: limit }, (_, index) => items[Math.floor(index * step)]);
}

async function locateWork(
  work: WorkQuery,
  log: ImportLog,
): Promise<{ pageTitle: string; pageUrl: string; textUrl: string; publisher: string } | null> {
  const searchUrl =
    "https://en.wikisource.org/w/api.php?action=query&list=search&srnamespace=0&srlimit=5&format=json&srsearch=" +
    encodeURIComponent(`${work.title} ${work.authorName}`);
  const body = JSON.parse(await fetchText(searchUrl)) as { query?: { search?: { title: string }[] } };
  const hits = body.query?.search ?? [];
  const exact = hits.filter((hit) => hit.title.toLowerCase() === work.title.toLowerCase());
  const contains = hits.filter((hit) => hit.title.toLowerCase().includes(work.title.toLowerCase()));
  const chosen = exact[0] ?? (contains.length === 1 ? contains[0] : undefined);
  if (chosen && exact.length <= 1) {
    const pageUrl = `https://en.wikisource.org/wiki/${encodeURIComponent(chosen.title.replace(/ /g, "_"))}`;
    const textUrl =
      "https://en.wikisource.org/w/api.php?action=parse&prop=wikitext&format=json&redirects=1&page=" +
      encodeURIComponent(chosen.title);
    return { pageTitle: chosen.title, pageUrl, textUrl, publisher: "Wikisource" };
  }
  if (hits.length > 1 && !chosen) {
    log.todos.push(`${work.title}: Wikisource returned several pages (${hits.map((hit) => hit.title).join("; ")}).`);
  }
  return locateGutenberg(work);
}

async function locateGutenberg(work: WorkQuery) {
  const url = `https://gutendex.com/books?search=${encodeURIComponent(`${work.title} ${work.authorName}`)}`;
  const body = JSON.parse(await fetchText(url)) as {
    results?: {
      id?: number;
      title?: string;
      authors?: { name?: string }[];
      formats?: Record<string, string>;
    }[];
  };
  const results = body.results ?? [];
  const surname = work.authorName.split(" ").slice(-1)[0].toLowerCase();
  const matches = results.filter((result) => {
    const title = (result.title ?? "").toLowerCase();
    const author = (result.authors ?? []).some((person) => (person.name ?? "").toLowerCase().includes(surname));
    return author && title.includes(work.title.toLowerCase());
  });
  const ids = new Set(matches.map((match) => (match.title ?? "").toLowerCase()));
  if (matches.length === 0 || ids.size !== 1 || !matches[0].id) return null;
  const book = matches[0];
  const formats = book.formats ?? {};
  const textUrl =
    formats["text/plain; charset=utf-8"] || formats["text/plain; charset=us-ascii"] || formats["text/plain"] || "";
  if (!textUrl) return null;
  return {
    pageTitle: book.title ?? work.title,
    pageUrl: `https://www.gutenberg.org/ebooks/${book.id}`,
    textUrl,
    publisher: "Project Gutenberg",
  };
}

/// Keeps sentences that read on their own and are in the author's voice.
/// Front matter, introductions by other people, and speaker labels are skipped.
function excerptSentences(raw: string, authorName: string): { text: string; words: number; index: number }[] {
  let plain = wikiToText(raw)
    .split(/\*\*\* START OF[^*]*\*\*\*/i)
    .pop()!
    .split(/\*\*\* END OF/i)[0];
  const body = /\n\s*CHAPTER\s+(I|1|ONE)\b[.:\s]/i.exec(plain);
  if (body && body.index < plain.length * 0.5) plain = plain.slice(body.index);
  const surname = authorName.split(" ").slice(-1)[0];
  const thirdPerson = new RegExp(`\\b${surname.replace(/[^A-Za-z]/g, "")}\\b`, "i");
  const leansOnContext =
    /^(These|Those|This|That|They|He|She|It|His|Her|Their|Its|In fact|But|And|Yet|So|Here|There|Such|Thus|Hence|Then|Thirdly|Secondly|Firstly)\b/;
  const parts = plain
    .split(/(?<=[.!?])\s+(?=[A-Z“"])/)
    .map((part) => part.replace(/\s+/g, " ").trim())
    .filter(Boolean);
  const junk =
    /project gutenberg|wikisource|public domain|copyright|produced by|end of the project|category:|this (ebook|file)|transcribed by|illustration|chapter [ivxlc\d]+|^\W*$/i;
  const sentences: { text: string; words: number; index: number }[] = [];
  let index = 0;
  for (const part of parts) {
    index += 1;
    if (junk.test(part) || /[{}|<>_\[\]♦*]/.test(part)) continue;
    if (thirdPerson.test(part) || leansOnContext.test(part)) continue;
    if (/^[A-Z][A-Z .]+:/.test(part) || /[A-Z]{5,}/.test(part)) continue;
    const quotes = (part.match(/["“”]/g) ?? []).length;
    if (quotes % 2 === 1) continue;
    if (!/^[A-Z“"]/.test(part) || !/[.!?]["”]?$/.test(part)) continue;
    if (/\b(Fig|pp?|ibid|op\. cit)\b\.?/i.test(part)) continue;
    const words = part.split(/\s+/).length;
    if (words < 8 || words > 40) continue;
    sentences.push({ text: part, words, index });
  }
  return sentences;
}

function wikiToText(wiki: string): string {
  let text = wiki;
  try {
    const body = JSON.parse(wiki) as { parse?: { wikitext?: { "*"?: string } } };
    if (body.parse?.wikitext?.["*"]) text = body.parse.wikitext["*"];
  } catch {
    text = wiki;
  }
  for (let pass = 0; pass < 8; pass += 1) text = text.replace(/\{\{[^{}]*\}\}/g, " ");
  text = text.replace(/\[\[(?:File|Image):[\s\S]*?\]\]/gi, " ");
  text = text.replace(/\[\[(?:[^|\]]+\|)?([^\]]+)\]\]/g, "$1");
  text = text.replace(/<[^>]+>/g, " ");
  text = text.replace(/'{2,}/g, "");
  text = text.replace(/^=+.*=+$/gm, " ");
  text = text.replace(/&[a-z]+;/gi, " ");
  return text;
}

async function firstOfficialLink(raw: string): Promise<string> {
  const hosts = ["loc.gov", "archives.gov", "americanrhetoric.com", "presidency.ucsb.edu"];
  const urls = [...raw.matchAll(/https?:\/\/[^\s\]"|<>]+/g)].map((match) => match[0].replace(/\\u0026/g, "&"));
  for (const url of urls) {
    let host = "";
    try {
      host = new URL(url).hostname.toLowerCase();
    } catch {
      continue;
    }
    if (!hosts.some((allowed) => host === allowed || host.endsWith(`.${allowed}`))) continue;
    try {
      const response = await fetch(url, {
        method: "GET",
        redirect: "follow",
        headers: { "User-Agent": `MotiScroll/1.0 (${process.env.CONTACT_EMAIL || "editor@example.com"})` },
      });
      if (response.status === 200) return response.url || url;
    } catch {
      continue;
    }
  }
  return "";
}

function hash(value: string): string {
  let hashValue = 0;
  for (const code of value) hashValue = (hashValue * 31 + code.charCodeAt(0)) >>> 0;
  return hashValue.toString(36);
}
