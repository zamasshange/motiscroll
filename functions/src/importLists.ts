import { createHash } from "node:crypto";
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";

import { recomputeCollectionCounts } from "./approve.js";
import { useFirebaseCliCredential } from "./cliCredential.js";
import { firstAllowedPortrait } from "./images.js";
import { parseGoodreadsQuotes } from "./importGoodreads.js";
import { lookupExactHuman, lookupWikipediaPrimary, slug } from "./resolveAuthors.js";

export interface ListedQuote {
  id: string;
  text: string;
  author: string;
  sourceTitle: string;
  url: string;
}

const fields = new Set(["leadership", "science", "business", "sports", "arts", "resilience", "other"]);

function quoteId(url: string, text: string): string {
  return createHash("sha1").update(`${url}\n${text}`).digest("hex").slice(0, 12);
}

function clean(value: string): string {
  return value.replace(/<[^>]+>/g, "").replace(/\s+/g, " ").trim();
}

export function parseReadersDigest(markdown: string): ListedQuote[] {
  const url = "https://www.rd.com/article/quotes-from-famous-people/";
  const quotes: ListedQuote[] = [];
  const re = /[“"]([^”"]+)[”"][\s_]*—[\s_]*([^(_\n]+?)(?:_|\s*\()/g;
  for (const match of markdown.matchAll(re)) {
    const text = clean(match[1]);
    const author = clean(match[2]).replace(/_/g, "").trim();
    if (text.length < 2 || !author) continue;
    quotes.push({ id: `q-${quoteId(url, text)}`, text, author, sourceTitle: "Reader's Digest", url });
  }
  return quotes;
}

export function parseAddicted2Success(markdown: string): ListedQuote[] {
  const url = "https://addicted2success.com/quotes/111-inspirational-celebrity-quotes-on-success-life-and-love/";
  const quotes: ListedQuote[] = [];
  const re = /[“"]([^”"]+)[”"]\s*[–—-]\s*\*\*([^*]+)\*\*/g;
  for (const match of markdown.matchAll(re)) {
    const text = clean(match[1]);
    const author = clean(match[2]);
    if (text.length < 2 || !author) continue;
    quotes.push({ id: `q-${quoteId(url, text)}`, text, author, sourceTitle: "Addicted2Success", url });
  }
  return quotes;
}

export function parseMyPicture(markdown: string): ListedQuote[] {
  const url = "https://www.my-picture.co.uk/blog/best-inspirational-quotes.jsf";
  const quotes: ListedQuote[] = [];
  const re = /^\*\s+"([^"]+)"\s+[—–-]\s+(.+)$/gm;
  for (const match of markdown.matchAll(re)) {
    const text = clean(match[1]);
    const author = clean(match[2]).replace(/\s*\(attributed\)\s*$/i, "");
    if (text.length < 2 || !author) continue;
    quotes.push({ id: `q-${quoteId(url, text)}`, text, author, sourceTitle: "MYPICTURE", url });
  }
  return quotes;
}

export function parseEfQuotes(html: string): ListedQuote[] {
  const url = "https://www.ef.com/wwen/english-resources/english-quotes/famous/";
  const quotes: ListedQuote[] = [];
  const skipped: string[] = [];
  const re = /<tr>\s*<td>\s*([^<]+?)\s*<\/td>\s*<td>\s*([^<]+?)\s*<\/td>/g;
  for (const match of html.matchAll(re)) {
    const text = clean(match[1]);
    const author = clean(match[2]);
    if (!text || !author || author === "Who") continue;
    if (/character/i.test(author)) {
      skipped.push(author);
      continue;
    }
    quotes.push({ id: `q-${quoteId(url, text)}`, text, author, sourceTitle: "EF Famous quotes in English", url });
  }
  return quotes;
}

export function parseShakespeare(html: string): ListedQuote[] {
  const url = "https://www.shakespeare.org.uk/explore-shakespeare/shakespedia/shakespeare-quotes-theme/shakespeare-quotes-life/";
  const quotes: ListedQuote[] = [];
  const re = /<p class="blockquote-text">([\s\S]*?)<\/p>\s*<cite class="blockquote-cite">([\s\S]*?)<\/cite>/g;
  for (const match of html.matchAll(re)) {
    const text = clean(match[1].replace(/&#x27;/g, "'").replace(/\s*\/\s*/g, " "));
    const cite = clean(match[2].replace(/&#x27;/g, "'")).replace(/^[—–-]\s*/, "");
    if (text.length < 2) continue;
    quotes.push({
      id: `q-${quoteId(url, text)}`,
      text,
      author: "William Shakespeare",
      sourceTitle: cite || "Shakespeare Quotes on Life",
      url,
    });
  }
  return quotes;
}

export function parseBrainyQuote(rows: { text?: string; author?: string; url?: string }[]): ListedQuote[] {
  const quotes: ListedQuote[] = [];
  for (const row of rows) {
    const text = clean(row.text ?? "");
    const author = clean(row.author ?? "");
    const url = row.url || "https://www.brainyquote.com/";
    if (text.length < 2 || !author) continue;
    quotes.push({ id: `q-${quoteId("brainyquote", text + author)}`, text, author, sourceTitle: "BrainyQuote", url });
  }
  return quotes;
}

async function fetchHtml(url: string): Promise<string> {
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

async function goodreadsPages(pages: number): Promise<ListedQuote[]> {
  const quotes: ListedQuote[] = [];
  for (let page = 1; page <= pages; page += 1) {
    const url = page === 1 ? "https://www.goodreads.com/quotes" : `https://www.goodreads.com/quotes?page=${page}`;
    const html = await fetchHtml(url);
    const found = parseGoodreadsQuotes(html);
    console.log(`goodreads page ${page}: ${found.length}`);
    if (found.length === 0) break;
    for (const quote of found) {
      quotes.push({
        id: `gr-${quote.id}`,
        text: quote.text,
        author: quote.author,
        sourceTitle: quote.book ? `Goodreads · ${quote.book}` : "Goodreads",
        url: quote.url,
      });
    }
    await new Promise((resolve) => setTimeout(resolve, 350));
  }
  return quotes;
}

interface Portrait {
  downloadUrl: string;
  artist: string;
  license: string;
  sourceUrl: string;
}

interface CacheEntry extends Partial<Portrait> {
  reason?: string;
}

function p18Files(entity: { claims?: Record<string, { mainsnak?: { datavalue?: { value?: unknown } } }[]> }): string[] {
  return (entity.claims?.P18 ?? [])
    .map((claim) => claim.mainsnak?.datavalue?.value)
    .filter((value): value is string => typeof value === "string" && value.length > 0);
}

function isLiving(entity: { claims?: Record<string, unknown[]> }): boolean {
  const died = entity.claims?.P570;
  return !died || died.length === 0;
}

async function main() {
  const pages = Math.min(
    100,
    Math.max(1, Number(process.argv.find((arg) => arg.startsWith("--pages="))?.slice("--pages=".length) ?? "100")),
  );
  useFirebaseCliCredential();
  initializeApp({ projectId: "motiscroll", storageBucket: "motiscroll.firebasestorage.app" });
  const db = getFirestore();

  const uploadDir = join(
    process.env.HOME ?? "",
    ".cursor/projects/Users-stratida-Projects-moti-scroll/uploads",
  );
  const readUpload = (name: string) => readFileSync(join(uploadDir, name), "utf8");
  const quotes: ListedQuote[] = [
    ...parseReadersDigest(readUpload("quotes-from-famous-people-1.md")),
    ...parseAddicted2Success(readUpload("111-inspirational-celebrity-quotes-on-success-life-and-love-6.md")),
    ...parseMyPicture(readUpload("best-inspirational-quotes.jsf-7.md")),
  ];
  console.log(`saved pages: ${quotes.length}`);

  const ef = await fetchHtml("https://www.ef.com/wwen/english-resources/english-quotes/famous/");
  const efQuotes = parseEfQuotes(ef);
  console.log(`ef: ${efQuotes.length}`);
  quotes.push(...efQuotes);

  const shakes = await fetchHtml(
    "https://www.shakespeare.org.uk/explore-shakespeare/shakespedia/shakespeare-quotes-theme/shakespeare-quotes-life/",
  );
  const shakeQuotes = parseShakespeare(shakes);
  console.log(`shakespeare: ${shakeQuotes.length}`);
  quotes.push(...shakeQuotes);

  const brainyPath = "/tmp/bq-quotes.json";
  if (existsSync(brainyPath)) {
    const rows = JSON.parse(readFileSync(brainyPath, "utf8")) as { text?: string; author?: string; url?: string }[];
    const brainy = parseBrainyQuote(rows);
    console.log(`brainyquote: ${brainy.length}`);
    quotes.push(...brainy);
  } else {
    console.log("brainyquote: page blocked, nothing saved");
  }

  const forbesPath = "/tmp/forbes-quotes.json";
  if (existsSync(forbesPath)) {
    const rows = JSON.parse(readFileSync(forbesPath, "utf8")) as { text?: string; author?: string }[];
    const url = "https://www.forbes.com/sites/kevinkruse/2013/05/28/inspirational-quotes/";
    let added = 0;
    for (const row of rows) {
      const text = clean(row.text ?? "");
      const author = clean(row.author ?? "");
      if (text.length < 2 || !author) continue;
      quotes.push({ id: `q-${quoteId(url, text)}`, text, author, sourceTitle: "Forbes", url });
      added += 1;
    }
    console.log(`forbes: ${added}`);
  } else {
    console.log("forbes: page blocked, nothing saved");
  }

  quotes.push(...(await goodreadsPages(pages)));
  const unique = new Map<string, ListedQuote>();
  for (const quote of quotes) unique.set(quote.id, quote);
  const list = [...unique.values()];
  console.log(`unique quotes: ${list.length}`);

  const authors = await db.collection("authors").get();
  const roster = new Map<string, { id: string; field: string; role: string; imageUrl: string; imageCredit: Portrait | null; living: boolean }>();
  for (const doc of authors.docs) {
    const data = doc.data();
    const name = String(data.name ?? "");
    if (!name) continue;
    const showPhoto = data.isLiving !== true || data.livingPhotoAllowed === true;
    const image = showPhoto ? (data.image as Record<string, unknown> | undefined) : undefined;
    const imageUrl = typeof image?.downloadUrl === "string" ? image.downloadUrl : "";
    roster.set(slug(name).replace(/-/g, ""), {
      id: doc.id,
      field: fields.has(String(data.field ?? "")) ? String(data.field) : "other",
      role: String(data.role ?? ""),
      imageUrl,
      living: data.isLiving === true,
      imageCredit: imageUrl
        ? {
            downloadUrl: imageUrl,
            artist: String(image?.artist ?? ""),
            license: String(image?.license ?? ""),
            sourceUrl: String(image?.sourceUrl ?? ""),
          }
        : null,
    });
  }

  const cachePath = join(process.cwd(), "../scripts/speaker_portraits.json");
  const cache = existsSync(cachePath)
    ? (JSON.parse(readFileSync(cachePath, "utf8")) as Record<string, CacheEntry>)
    : {};
  const names = [...new Set(list.map((quote) => quote.author))];
  let looked = 0;
  let pictured = 0;
  let livingSkipped = 0;
  let cursor = 0;
  async function resolveName(name: string) {
    const key = name.trim().toLowerCase();
    if (cache[key]) {
      if (cache[key].downloadUrl) pictured += 1;
      if (cache[key].reason === "living") livingSkipped += 1;
      return;
    }
    const known = roster.get(slug(name).replace(/-/g, ""));
    if (known?.imageUrl && known.imageCredit) {
      cache[key] = known.imageCredit;
      pictured += 1;
      return;
    }
    if (known?.living || /character|the bible|anonymous|unknown|proverb/i.test(name)) {
      cache[key] = { reason: known?.living ? "living" : "not-a-person" };
      if (known?.living) livingSkipped += 1;
      return;
    }
    looked += 1;
    try {
      const exact = await lookupExactHuman(name);
      const found = exact.ok ? exact : await lookupWikipediaPrimary(name);
      if (!found.ok) cache[key] = { reason: found.reason };
      else if (isLiving(found.entity)) {
        cache[key] = { reason: "living" };
        livingSkipped += 1;
      } else {
        const portrait = await firstAllowedPortrait(p18Files(found.entity));
        cache[key] = portrait ?? { reason: "no-usable-portrait" };
        if (portrait) pictured += 1;
      }
    } catch (error) {
      cache[key] = { reason: error instanceof Error ? error.message : "lookup failed" };
    }
    if (looked % 40 === 0) {
      writeFileSync(cachePath, JSON.stringify(cache));
      console.log(`portraits checked ${looked} of ${names.length}, with a photo ${pictured}, living skipped ${livingSkipped}`);
    }
  }
  async function worker() {
    while (cursor < names.length) {
      const name = names[cursor];
      cursor += 1;
      await resolveName(name);
    }
  }
  await Promise.all(Array.from({ length: 8 }, () => worker()));
  writeFileSync(cachePath, JSON.stringify(cache));
  console.log(`portraits checked ${looked} of ${names.length}, with a photo ${pictured}, living skipped ${livingSkipped}`);

  let batch = db.batch();
  let pending = 0;
  for (const quote of list) {
    const known = roster.get(slug(quote.author).replace(/-/g, ""));
    const portrait = cache[quote.author.trim().toLowerCase()];
    const imageUrl = portrait?.downloadUrl || known?.imageUrl || "";
    batch.set(db.collection("publishedItems").doc(quote.id), {
      text: quote.text,
      type: "quote",
      field: known?.field ?? "other",
      moods: [],
      rand: Math.random(),
      authorId: known?.id ?? slug(quote.author),
      authorName: quote.author,
      authorRole: known?.role ?? "",
      authorImageUrl: imageUrl || null,
      imageCredit: imageUrl
        ? {
            artist: portrait?.artist || known?.imageCredit?.artist || "",
            license: portrait?.license || known?.imageCredit?.license || "",
            sourceUrl: portrait?.sourceUrl || known?.imageCredit?.sourceUrl || "",
          }
        : null,
      primarySource: {
        title: quote.sourceTitle,
        year: null,
        url: quote.url,
        pageOrTimestamp: "",
      },
      deeper: { context: "", didYouKnow: "", takeaway: "" },
      related: [],
      speech: null,
      publishedAt: FieldValue.serverTimestamp(),
    });
    pending += 1;
    if (pending === 400) {
      await batch.commit();
      batch = db.batch();
      pending = 0;
    }
  }
  if (pending > 0) await batch.commit();
  await recomputeCollectionCounts();
  console.log(`Published ${list.length} quotes from the lists.`);
}

if (require.main === module) {
  main().catch((error: unknown) => {
    console.error(error);
    process.exit(1);
  });
}
