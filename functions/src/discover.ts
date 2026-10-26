import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";

import { assertEditor } from "./authz.js";
import { wordCount } from "./gate.js";
import { fetchText } from "./http.js";
import { contactEmail, enforceAppCheck, youtubeApiKey } from "./secrets.js";

const callable = { enforceAppCheck: enforceAppCheck(), secrets: [contactEmail, youtubeApiKey], timeoutSeconds: 300 };

const skipHeading = /misattribut|disput|unsourc|quotes about/i;
const keepHeading = /quote|sourced|speech/i;

export async function runWikiquote() {
  const db = getFirestore();
  const authors = await db.collection("authors").where("wikiquoteTitle", "!=", "").limit(25).get();
  let added = 0;
  let skipped = 0;
  const errors: string[] = [];
  for (const author of authors.docs) {
    const title = String(author.data().wikiquoteTitle ?? "");
    if (!title) continue;
    try {
      const url =
        "https://en.wikiquote.org/w/api.php?action=parse&prop=wikitext&format=json&redirects=1&page=" +
        encodeURIComponent(title);
      const body = JSON.parse(await fetchText(url)) as { parse?: { wikitext?: { "*"?: string } } };
      const wiki = body.parse?.wikitext?.["*"] ?? "";
      for (const section of splitSections(wiki)) {
        if (skipHeading.test(section.title) || !keepHeading.test(section.title)) {
          skipped += 1;
          continue;
        }
        for (const line of section.body.split("\n")) {
          if (!line.startsWith("*")) continue;
          const text = cleanQuote(line);
          if (!text || wordCount(text) > 40) {
            skipped += 1;
            continue;
          }
          const id = `wq-${author.id}-${hash(text)}`;
          const ref = db.collection("items").doc(id);
          const existing = await ref.get();
          if (existing.exists) {
            skipped += 1;
            continue;
          }
          await ref.set({
            type: "quote",
            text,
            authorId: author.id,
            field: "other",
            moods: [],
            language: "en",
            status: "candidate",
            verified: false,
            discoveredVia: "wikiquote",
            sourceHint: line.slice(0, 500),
            wordCount: wordCount(text),
            warnings: [],
            rand: Math.random(),
            createdAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          });
          added += 1;
        }
      }
    } catch (error) {
      errors.push(`${title}: ${error instanceof Error ? error.message : "failed"}`);
    }
  }
  await logImport("wikiquote", authors.size, added, skipped, errors);
}

export const discoverWikiquote = onCall(callable, async (request) => {
  assertEditor(request);
  await runWikiquote();
  return { ok: true };
});

export const discoverWikiquoteNightly = onSchedule(
  { schedule: "every 24 hours", secrets: [contactEmail], timeoutSeconds: 540 },
  async () => {
    await runWikiquote();
  },
);

export async function runPublicDomain() {
  const db = getFirestore();
  const sources = await db.collection("importSources").where("type", "==", "public_domain").limit(10).get();
  let added = 0;
  let skipped = 0;
  const errors: string[] = [];
  for (const source of sources.docs) {
    const url = String(source.data().url ?? "");
    try {
      const text = await fetchText(url);
      const sentences = text
        .replace(/<[^>]+>/g, " ")
        .split(/(?<=[.!?])\s+/)
        .map((sentence) => sentence.trim())
        .filter((sentence) => wordCount(sentence) > 4 && wordCount(sentence) <= 40);
      for (const sentence of sentences.slice(0, 15)) {
        const id = `pd-${source.id}-${hash(sentence)}`;
        const ref = db.collection("items").doc(id);
        if ((await ref.get()).exists) {
          skipped += 1;
          continue;
        }
        await ref.set({
          type: "quote",
          text: sentence,
          authorId: source.data().authorId ?? "unknown",
          field: "other",
          moods: [],
          language: "en",
          status: "candidate",
          verified: false,
          discoveredVia: "public_domain_import",
          wordCount: wordCount(sentence),
          warnings: [],
          rand: Math.random(),
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
        await ref.collection("sources").doc("registered").set({
          title: source.data().title ?? url,
          url,
          sourceType: "primary",
          confidence: "probable",
          pageOrTimestamp: "",
        });
        added += 1;
      }
      await source.ref.set({ lastRunAt: FieldValue.serverTimestamp() }, { merge: true });
    } catch (error) {
      errors.push(`${url}: ${error instanceof Error ? error.message : "failed"}`);
    }
  }
  await logImport("public_domain", sources.size, added, skipped, errors);
}

export const importPublicDomain = onCall(callable, async (request) => {
  assertEditor(request);
  await runPublicDomain();
  return { ok: true };
});

export async function runFeeds() {
  const db = getFirestore();
  const feeds = await db.collection("importSources").where("type", "in", ["podcast", "youtube"]).limit(10).get();
  let added = 0;
  const errors: string[] = [];
  for (const feed of feeds.docs) {
    try {
      if (feed.data().type === "youtube") {
        const key = youtubeApiKey.value();
        if (!key) throw new Error("YOUTUBE_API_KEY is not set.");
        const channel = encodeURIComponent(String(feed.data().channelId ?? ""));
        const url =
          `https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&order=date&maxResults=5&channelId=${channel}&key=${key}`;
        const body = JSON.parse(await fetchText(url)) as {
          items?: { id?: { videoId?: string }; snippet?: { title?: string; publishedAt?: string } }[];
        };
        for (const item of body.items ?? []) {
          const videoId = item.id?.videoId;
          if (!videoId) continue;
          const id = `yt-${videoId}`;
          const ref = db.collection("items").doc(id);
          if ((await ref.get()).exists) continue;
          await ref.set({
            type: "speech",
            text: "",
            authorId: feed.data().authorId ?? feed.id,
            field: "other",
            moods: [],
            language: "en",
            status: "candidate",
            verified: false,
            discoveredVia: "youtube_feed",
            episode: item.snippet?.title ?? videoId,
            wordCount: 0,
            warnings: ["metadata_only"],
            rand: Math.random(),
            createdAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          });
          await ref.collection("speech").doc("main").set({
            durationSec: 0,
            watchUrl: `https://www.youtube.com/watch?v=${videoId}`,
            embedAllowed: false,
            rightsStatus: "unknown",
            rightsNotes: "Metadata only. An editor adds the excerpt and timestamp after listening.",
          });
          added += 1;
        }
      } else {
        const xml = await fetchText(String(feed.data().url ?? ""));
        const titles = [...xml.matchAll(/<title>([^<]+)<\/title>/g)].slice(1, 6);
        const links = [...xml.matchAll(/<link>([^<]+)<\/link>/g)].slice(0, 5);
        for (let i = 0; i < titles.length; i += 1) {
          const title = titles[i][1];
          const link = links[i]?.[1] ?? "";
          const id = `pod-${hash(link || title)}`;
          const ref = db.collection("items").doc(id);
          if ((await ref.get()).exists) continue;
          await ref.set({
            type: "speech",
            text: "",
            authorId: feed.data().authorId ?? feed.id,
            episode: title,
            field: "other",
            moods: [],
            language: "en",
            status: "candidate",
            verified: false,
            discoveredVia: "podcast_feed",
            wordCount: 0,
            warnings: ["metadata_only"],
            rand: Math.random(),
            createdAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          });
          await ref.collection("speech").doc("main").set({
            durationSec: 0,
            watchUrl: link,
            embedAllowed: false,
            rightsStatus: "unknown",
            rightsNotes: "Metadata only. Do not download the audio.",
          });
          added += 1;
        }
      }
    } catch (error) {
      errors.push(`${feed.id}: ${error instanceof Error ? error.message : "failed"}`);
    }
  }
  await logImport("feeds", feeds.size, added, 0, errors);
}

export const discoverFeeds = onCall(callable, async (request) => {
  assertEditor(request);
  await runFeeds();
  return { ok: true };
});

export const importItems = onCall({ ...callable, timeoutSeconds: 120 }, async (request) => {
  assertEditor(request);
  const rows = Array.isArray(request.data?.items) ? request.data.items : null;
  if (!rows) throw new HttpsError("invalid-argument", "Pass { items: [...] }.");
  if (rows.length > 100) throw new HttpsError("invalid-argument", "Import at most 100 rows at a time.");
  const db = getFirestore();
  let added = 0;
  const errors: string[] = [];
  for (const row of rows) {
    const text = String(row?.text ?? "").trim();
    const authorId = String(row?.authorId ?? "").trim();
    const sourceUrl = String(row?.sourceUrl ?? "").trim();
    const sourceTitle = String(row?.sourceTitle ?? "").trim();
    if (!text || !authorId || !sourceUrl || !sourceTitle) {
      errors.push("A row is missing text, authorId, sourceTitle, or sourceUrl.");
      continue;
    }
    const id = String(row.id ?? `manual-${hash(authorId + text)}`).slice(0, 120);
    await db.collection("items").doc(id).set(
      {
        type: row.type === "speech" ? "speech" : "quote",
        text: text.slice(0, 2000),
        authorId,
        field: String(row.field ?? "other"),
        moods: Array.isArray(row.moods) ? row.moods.slice(0, 6) : [],
        language: "en",
        status: "draft",
        verified: false,
        discoveredVia: "manual",
        wordCount: wordCount(text),
        warnings: [],
        rand: Math.random(),
        related: Array.isArray(row.related) ? row.related : [],
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    await db.collection("items").doc(id).collection("sources").doc("primary").set({
      title: sourceTitle.slice(0, 300),
      url: sourceUrl.slice(0, 500),
      year: typeof row.year === "number" ? row.year : null,
      pageOrTimestamp: String(row.pageOrTimestamp ?? "").slice(0, 120),
      sourceType: "primary",
      confidence: "probable",
    });
    added += 1;
  }
  await logImport("manual", rows.length, added, rows.length - added, errors);
  return { added, errors };
});

function splitSections(wiki: string): { title: string; body: string }[] {
  const chunks = wiki.split(/\n(?==+[^=]+=+)/);
  return chunks.map((chunk) => {
    const match = chunk.match(/^=+\s*(.*?)\s*=+/);
    return { title: match?.[1] ?? "", body: chunk };
  });
}

function cleanQuote(line: string): string {
  return line
    .replace(/^\*\s*/, "")
    .replace(/\{\{[^}]+\}\}/g, "")
    .replace(/\[\[(?:[^|\]]+\|)?([^\]]+)\]\]/g, "$1")
    .replace(/'''?/g, "")
    .trim();
}

function hash(value: string): string {
  let hashValue = 0;
  for (const code of value) hashValue = (hashValue * 31 + code.charCodeAt(0)) >>> 0;
  return hashValue.toString(36);
}

async function logImport(source: string, rowsFound: number, rowsAdded: number, rowsSkipped: number, errors: string[]) {
  await getFirestore().collection("importLog").add({
    source,
    runAt: FieldValue.serverTimestamp(),
    rowsFound,
    rowsAdded,
    rowsSkipped,
    rowsFailed: errors.length,
    errors: errors.slice(0, 20),
  });
}
