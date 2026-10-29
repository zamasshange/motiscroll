import { writeFileSync } from "node:fs";
import { join } from "node:path";

import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";

import { useFirebaseCliCredential } from "./cliCredential.js";
import { fetchMissingAuthorImages } from "./images.js";
import {
  loadAuthorSeeds,
  lookupExactHuman,
  resolveAuthorRoster,
  slug,
  watchlistNames,
} from "./resolveAuthors.js";

const outsideRoster = ["Marilyn Monroe", "Mark Twain", "Abraham Lincoln", "Buddha"];

async function main(): Promise<void> {
  useFirebaseCliCredential();
  initializeApp({
    projectId: "motiscroll",
    storageBucket: "motiscroll.firebasestorage.app",
  });
  const seeds = loadAuthorSeeds();
  if (seeds.length !== 250) {
    throw new Error(`authors_seed.json has ${seeds.length} entries. Expected 250.`);
  }
  const roster = await resolveAuthorRoster(seeds);
  const db = getFirestore();
  for (const name of outsideRoster) {
    const found = await lookupExactHuman(name);
    if (!found.ok) {
      roster.manualConfirm.push({
        name,
        reason: `Watchlist name, not one of the 250 authors. ${found.reason}`,
      });
    } else {
      await db.collection("misattributionWatchlist").doc(slug(name)).set(
        {
          name,
          slug: slug(name),
          onRoster: false,
          wikidataId: found.id,
          reason: "Named on the roster watchlist.",
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }
    await new Promise((resolve) => setTimeout(resolve, 350));
  }
  for (const name of watchlistNames) {
    const ambiguous = roster.manualConfirm.some((row) => row.name === name);
    const author = await db.collection("authors").doc(slug(name)).get();
    const data = author.data();
    const wikidataId = typeof data?.wikidataId === "string" ? data.wikidataId : "";
    await db.collection("misattributionWatchlist").doc(slug(name)).set(
      {
        name,
        slug: slug(name),
        onRoster: seeds.some((seed) => seed.name === name),
        wikidataId: ambiguous || !wikidataId ? FieldValue.delete() : wikidataId,
        reason: "Named on the roster watchlist.",
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }
  const confirmPath = join(process.cwd(), "..", "scripts", "authors_needs_confirm.json");
  writeFileSync(confirmPath, `${JSON.stringify(roster.manualConfirm, null, 2)}\n`);
  console.log(`Resolved: ${roster.resolved}`);
  console.log(`Needs confirm: ${roster.manualConfirm.length}`);
  console.log(`No Wikiquote page: ${roster.noWikiquote.length}`);
  for (const row of roster.manualConfirm) console.log(`CONFIRM\t${row.name}\t${row.reason}`);
  for (const row of roster.labelDiffs) console.log(`DIFF\t${row.name}\t${row.note}`);
  for (const name of roster.noWikiquote) console.log(`NO_WIKIQUOTE\t${name}`);
  const photos = await fetchMissingAuthorImages();
  console.log(`Images fetched: ${photos}`);
}

main().catch((error: unknown) => {
  console.error(error);
  process.exit(1);
});
