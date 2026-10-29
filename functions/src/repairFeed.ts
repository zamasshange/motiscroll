import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

import { useFirebaseCliCredential } from "./cliCredential.js";
import { firstAllowedPortrait } from "./images.js";
import { lookupExactHuman, lookupWikipediaPrimary } from "./resolveAuthors.js";

const cachePath = join(process.cwd(), "../scripts/speaker_portraits.json");

function personKey(name: string): string {
  return name.toLowerCase().replace(/[^a-z0-9]+/g, "");
}

function decodeText(value: string): string {
  let text = value;
  for (let pass = 0; pass < 4; pass += 1) {
    const next = text
      .replace(/&amp;/g, "&")
      .replace(/&#x([0-9a-f]+);/gi, (_, hex: string) => {
        const code = Number.parseInt(hex, 16);
        return Number.isFinite(code) ? String.fromCodePoint(code) : _;
      })
      .replace(/&#(\d+);/g, (_, digits: string) => {
        const code = Number(digits);
        return Number.isFinite(code) ? String.fromCodePoint(code) : _;
      })
      .replace(/&quot;/g, '"')
      .replace(/&apos;/g, "'")
      .replace(/&lt;/g, "<")
      .replace(/&gt;/g, ">")
      .replace(/&nbsp;/g, " ");
    if (next === text) break;
    text = next;
  }
  return text;
}

interface Portrait {
  downloadUrl: string;
  artist: string;
  license: string;
  sourceUrl: string;
}

function loadCache(): Record<string, Portrait | { reason: string }> {
  if (!existsSync(cachePath)) return {};
  return JSON.parse(readFileSync(cachePath, "utf8")) as Record<string, Portrait | { reason: string }>;
}

function p18Files(entity: { claims?: Record<string, { mainsnak?: { datavalue?: { value?: unknown } } }[]> }): string[] {
  return (entity.claims?.P18 ?? [])
    .map((claim) => claim.mainsnak?.datavalue?.value)
    .filter((value): value is string => typeof value === "string" && value.length > 0);
}

async function portraitFor(name: string, cache: Record<string, Portrait | { reason: string }>): Promise<Portrait | null> {
  const key = name.trim().toLowerCase();
  const cached = cache[key];
  if (cached && "downloadUrl" in cached && cached.downloadUrl) return cached;
  const exact = await lookupExactHuman(name);
  const found = exact.ok ? exact : await lookupWikipediaPrimary(name);
  if (!found.ok) {
    cache[key] = { reason: found.reason };
    return null;
  }
  const portrait = await firstAllowedPortrait(p18Files(found.entity));
  cache[key] = portrait ?? { reason: "no-usable-portrait" };
  return portrait;
}

async function portraitsOnly(db: ReturnType<typeof getFirestore>) {
  const authors = await db.collection("publishedAuthors").get();
  const cache = loadCache();
  const needing = authors.docs.filter((doc) => !String(doc.data().imageUrl ?? ""));
  console.log(`Portraits needed for ${needing.length} people.`);
  let cursor = 0;
  let stored = 0;
  const found = new Map<string, { id: string; name: string; portrait: Portrait }>();
  async function worker() {
    while (cursor < needing.length) {
      const doc = needing[cursor];
      cursor += 1;
      const name = String(doc.data().name ?? "");
      if (!name) continue;
      try {
        const portrait = await portraitFor(name, cache);
        if (!portrait) continue;
        found.set(doc.id, { id: doc.id, name, portrait });
        stored += 1;
        if (stored % 15 === 0) console.log(`portraits found ${stored}`);
      } catch (error) {
        console.error("portrait failed", name, error instanceof Error ? error.message : error);
      }
    }
  }
  await Promise.all(Array.from({ length: 4 }, () => worker()));
  writeFileSync(cachePath, JSON.stringify(cache));
  let batch = db.batch();
  let writes = 0;
  for (const entry of found.values()) {
    batch.set(
      db.collection("publishedAuthors").doc(entry.id),
      {
        imageUrl: entry.portrait.downloadUrl,
        imageCredit: {
          artist: entry.portrait.artist,
          license: entry.portrait.license,
          sourceUrl: entry.portrait.sourceUrl,
        },
      },
      { merge: true },
    );
    writes += 1;
    if (writes === 400) {
      await batch.commit();
      batch = db.batch();
      writes = 0;
    }
  }
  if (writes > 0) await batch.commit();
  console.log(`Saved portraits for ${stored} people.`);
}

async function main() {
  useFirebaseCliCredential();
  initializeApp({ projectId: "motiscroll", storageBucket: "motiscroll.firebasestorage.app" });
  const db = getFirestore();
  if (process.argv.includes("--portraits-only")) {
    await portraitsOnly(db);
    return;
  }

  const items = await db.collection("publishedItems").get();
  let batch = db.batch();
  let writes = 0;
  let decoded = 0;
  for (const doc of items.docs) {
    const data = doc.data();
    const update: Record<string, string> = {};
    const text = decodeText(String(data.text ?? ""));
    const author = decodeText(String(data.authorName ?? ""));
    const title = decodeText(String(data.primarySource?.title ?? ""));
    const artist = decodeText(String(data.imageCredit?.artist ?? ""));
    const context = decodeText(String(data.deeper?.context ?? ""));
    const did = decodeText(String(data.deeper?.didYouKnow ?? ""));
    if (text !== String(data.text ?? "")) update.text = text;
    if (author !== String(data.authorName ?? "")) update.authorName = author;
    if (title !== String(data.primarySource?.title ?? "")) update["primarySource.title"] = title;
    if (data.imageCredit && artist !== String(data.imageCredit.artist ?? "")) update["imageCredit.artist"] = artist;
    if (context !== String(data.deeper?.context ?? "")) update["deeper.context"] = context;
    if (did !== String(data.deeper?.didYouKnow ?? "")) update["deeper.didYouKnow"] = did;
    if (Object.keys(update).length === 0) continue;
    batch.update(doc.ref, update);
    decoded += 1;
    writes += 1;
    if (writes === 400) {
      await batch.commit();
      batch = db.batch();
      writes = 0;
    }
  }
  if (writes > 0) await batch.commit();
  console.log(`Decoded text on ${decoded} lines.`);

  const authors = await db.collection("publishedAuthors").get();
  const cache = loadCache();
  const needing = authors.docs.filter((doc) => !String(doc.data().imageUrl ?? ""));
  console.log(`Portraits needed for ${needing.length} people.`);
  let cursor = 0;
  let stored = 0;
  const found = new Map<string, Portrait>();
  async function worker() {
    while (cursor < needing.length) {
      const doc = needing[cursor];
      cursor += 1;
      const name = String(doc.data().name ?? "");
      if (!name) continue;
      try {
        const portrait = await portraitFor(name, cache);
        if (!portrait) continue;
        found.set(doc.id, portrait);
        stored += 1;
      } catch (error) {
        console.error("portrait failed", name, error instanceof Error ? error.message : error);
      }
      if (stored % 20 === 0 && stored > 0) {
        writeFileSync(cachePath, JSON.stringify(cache));
        console.log(`portraits stored ${stored} of ${needing.length}`);
      }
    }
  }
  await Promise.all(Array.from({ length: 6 }, () => worker()));
  writeFileSync(cachePath, JSON.stringify(cache));
  console.log(`portraits found ${stored}`);

  batch = db.batch();
  writes = 0;
  for (const [id, portrait] of found) {
    batch.set(
      db.collection("publishedAuthors").doc(id),
      {
        imageUrl: portrait.downloadUrl,
        imageCredit: {
          artist: portrait.artist,
          license: portrait.license,
          sourceUrl: portrait.sourceUrl,
        },
      },
      { merge: true },
    );
    writes += 1;
    if (writes === 400) {
      await batch.commit();
      batch = db.batch();
      writes = 0;
    }
  }
  if (writes > 0) await batch.commit();

  const byKey = new Map<string, Portrait>();
  for (const doc of authors.docs) {
    const name = String(doc.data().name ?? "");
    const portrait = found.get(doc.id);
    if (name && portrait) byKey.set(personKey(name), portrait);
  }
  batch = db.batch();
  writes = 0;
  let itemPhotos = 0;
  for (const doc of items.docs) {
    const data = doc.data();
    if (String(data.authorImageUrl ?? "")) continue;
    const portrait = byKey.get(personKey(String(data.authorName ?? "")));
    if (!portrait) continue;
    batch.set(
      doc.ref,
      {
        authorImageUrl: portrait.downloadUrl,
        imageCredit: {
          artist: portrait.artist,
          license: portrait.license,
          sourceUrl: portrait.sourceUrl,
        },
      },
      { merge: true },
    );
    itemPhotos += 1;
    writes += 1;
    if (writes === 400) {
      await batch.commit();
      batch = db.batch();
      writes = 0;
    }
  }
  if (writes > 0) await batch.commit();
  console.log(`Added a portrait to ${itemPhotos} lines and ${stored} people.`);
}

if (require.main === module) {
  main().catch((error: unknown) => {
    console.error(error);
    process.exit(1);
  });
}
