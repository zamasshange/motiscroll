import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";

import { useFirebaseCliCredential } from "./cliCredential.js";
import { fetchMissingAuthorImages } from "./images.js";
import {
  ConfirmRow,
  loadAuthorSeeds,
  lookupWikipediaPrimary,
  slug,
  watchlistNames,
  writeAuthor,
} from "./resolveAuthors.js";

const write = process.argv.includes("--write");

async function main(): Promise<void> {
  useFirebaseCliCredential();
  initializeApp({ projectId: "motiscroll", storageBucket: "motiscroll.firebasestorage.app" });
  const db = getFirestore();
  const seeds = loadAuthorSeeds();
  const confirmPath = join(process.cwd(), "..", "scripts", "authors_needs_confirm.json");
  const pending = JSON.parse(readFileSync(confirmPath, "utf8")) as ConfirmRow[];
  const still: ConfirmRow[] = [];
  let accepted = 0;
  for (const row of pending) {
    const seed = seeds.find((candidate) => candidate.name === row.name);
    const found = await lookupWikipediaPrimary(row.name);
    if (!found.ok) {
      console.log(`KEEP\t${row.name}\t${found.reason}`);
      still.push({ name: row.name, reason: `${row.reason} ${found.reason}` });
    } else {
      console.log(`MATCH\t${row.name}\t${seed?.field ?? "watchlist"}\t${found.id}\t${found.title}\t${found.description}`);
      accepted += 1;
      if (write) {
        if (seed) {
          const written = await writeAuthor(seed, found, "enwiki_primary_topic");
          if (written.note) console.log(`DIFF\t${row.name}\t${written.note}`);
          if (!written.hasWikiquote) console.log(`NO_WIKIQUOTE\t${row.name}`);
        }
        if (watchlistNames.includes(row.name)) {
          await db.collection("misattributionWatchlist").doc(slug(row.name)).set(
            { wikidataId: found.id, updatedAt: FieldValue.serverTimestamp() },
            { merge: true },
          );
        }
      }
    }
    await new Promise((resolve) => setTimeout(resolve, 300));
  }
  console.log(`Matched by English Wikipedia title: ${accepted}`);
  console.log(`Still needs confirm: ${still.length}`);
  if (!write) {
    console.log("Preview only. Run with --write to save.");
    return;
  }
  writeFileSync(confirmPath, `${JSON.stringify(still, null, 2)}\n`);
  console.log(`Images fetched: ${await fetchMissingAuthorImages()}`);
}

main().catch((error: unknown) => {
  console.error(error);
  process.exit(1);
});
