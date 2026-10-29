import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";

import { recomputeCollectionCounts } from "./approve.js";
import { useFirebaseCliCredential } from "./cliCredential.js";
import { slug } from "./resolveAuthors.js";

const fields = new Set(["leadership", "science", "business", "sports", "arts", "resilience", "other"]);

export interface GoodreadsQuote {
  id: string;
  text: string;
  author: string;
  book: string;
  url: string;
}

export function parseGoodreadsQuotes(html: string): GoodreadsQuote[] {
  const quotes: GoodreadsQuote[] = [];
  const seen = new Set<string>();
  for (const chunk of html.split(/<div class=['"]quote['"]>/).slice(1)) {
    const textBlock = chunk.match(/<div class="quoteText">([\s\S]*?)<\/div>/)?.[1] ?? "";
    const text = goodreadsQuoteText(textBlock);
    const author = decode(chunk.match(/<span class="authorOrTitle">([\s\S]*?)<\/span>/)?.[1] ?? "")
      .replace(/,\s*$/, "")
      .trim();
    const book = decode(
      chunk.match(/<a class="authorOrTitle"[^>]*>([\s\S]*?)<\/a>/)?.[1] ?? "",
    ).trim();
    const path = chunk.match(/href="(\/quotes\/(\d+)[^"]*)"/)?.[1] ?? "";
    const id = path.match(/\/quotes\/(\d+)/)?.[1] ?? "";
    if (!id || text.length < 2 || !author || seen.has(id)) continue;
    seen.add(id);
    quotes.push({
      id,
      text,
      author,
      book,
      url: `https://www.goodreads.com${path}`,
    });
  }
  return quotes;
}

export function goodreadsQuoteText(textBlock: string): string {
  const beforeAuthor = textBlock.split(/<span class="authorOrTitle"/i)[0] ?? textBlock;
  const withoutRule = beforeAuthor.replace(
    /<br\s*\/?>\s*(?:&#8213;|&mdash;|&#8212;|—|–)+\s*/gi,
    " ",
  );
  return decode(withoutRule.replace(/<br\s*\/?>/gi, " "))
    .replace(/^[“"\s]+|[”"\s]+$/g, "")
    .trim();
}

function decode(value: string): string {
  return value
    .replace(/<[^>]+>/g, "")
    .replace(/&#(\d+);/g, (_, digits: string) => {
      const code = Number(digits);
      return Number.isFinite(code) ? String.fromCodePoint(code) : "";
    })
    .replace(/&#x([0-9a-f]+);/gi, (_, digits: string) => {
      const code = Number.parseInt(digits, 16);
      return Number.isFinite(code) ? String.fromCodePoint(code) : "";
    })
    .replace(/&ldquo;|&rdquo;|&quot;/g, '"')
    .replace(/&lsquo;|&rsquo;/g, "'")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&nbsp;/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

async function fetchPage(page: number): Promise<string> {
  const url = page <= 1 ? "https://www.goodreads.com/quotes" : `https://www.goodreads.com/quotes?page=${page}`;
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

interface RosterHit {
  id: string;
  field: string;
  role: string;
  imageUrl: string;
  imageCredit: { artist: string; license: string; sourceUrl: string } | null;
}

function rosterKey(name: string): string {
  return slug(name).replace(/-/g, "");
}

async function main() {
  const pages = Math.min(
    20,
    Math.max(1, Number(process.argv.find((arg) => arg.startsWith("--pages="))?.slice("--pages=".length) ?? "10")),
  );
  useFirebaseCliCredential();
  initializeApp({ projectId: "motiscroll", storageBucket: "motiscroll.firebasestorage.app" });
  const db = getFirestore();
  const authors = await db.collection("authors").get();
  const roster = new Map<string, RosterHit>();
  for (const doc of authors.docs) {
    const data = doc.data();
    const name = String(data.name ?? "");
    if (!name) continue;
    const showPhoto = data.isLiving !== true || data.livingPhotoAllowed === true;
    const image = showPhoto ? (data.image as Record<string, unknown> | undefined) : undefined;
    const imageUrl = typeof image?.downloadUrl === "string" ? image.downloadUrl : "";
    const field = fields.has(String(data.field ?? "")) ? String(data.field) : "other";
    const hit: RosterHit = {
      id: doc.id,
      field,
      role: String(data.role ?? ""),
      imageUrl,
      imageCredit: imageUrl
        ? {
            artist: String(image?.artist ?? ""),
            license: String(image?.license ?? ""),
            sourceUrl: String(image?.sourceUrl ?? ""),
          }
        : null,
    };
    roster.set(rosterKey(name), hit);
  }

  const found: GoodreadsQuote[] = [];
  for (let page = 1; page <= pages; page += 1) {
    const html = await fetchPage(page);
    const quotes = parseGoodreadsQuotes(html);
    console.log(`page ${page}: ${quotes.length}`);
    found.push(...quotes);
    if (quotes.length === 0) break;
    await new Promise((resolve) => setTimeout(resolve, 400));
  }

  let batch = db.batch();
  let pending = 0;
  let written = 0;
  const matched = new Set<string>();
  for (const quote of found) {
    const hit = roster.get(rosterKey(quote.author));
    if (hit) matched.add(quote.author);
    const ref = db.collection("publishedItems").doc(`gr-${quote.id}`);
    batch.set(ref, {
      text: quote.text,
      type: "quote",
      field: hit?.field ?? "other",
      moods: [],
      rand: Math.random(),
      authorId: hit?.id ?? slug(quote.author),
      authorName: quote.author,
      authorRole: hit?.role ?? "",
      authorImageUrl: hit?.imageUrl || null,
      imageCredit: hit?.imageCredit ?? null,
      primarySource: {
        title: quote.book ? `Goodreads · ${quote.book}` : "Goodreads",
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
    written += 1;
    if (pending === 400) {
      await batch.commit();
      batch = db.batch();
      pending = 0;
    }
  }
  if (pending > 0) await batch.commit();
  await recomputeCollectionCounts();
  console.log(`Published ${written} Goodreads quotes. Roster matches: ${matched.size}.`);
}

if (require.main === module) {
  main().catch((error: unknown) => {
    console.error(error);
    process.exit(1);
  });
}
