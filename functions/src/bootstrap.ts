import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";

import { recomputeCollectionCounts } from "./approve.js";
import { useFirebaseCliCredential } from "./cliCredential.js";
import { fetchMissingAuthorImages } from "./images.js";
import { backfillDaily } from "./notify.js";
import { emptyImportLog, importWork, WorkQuery } from "./publicDomain.js";
import { loadAuthorSeeds, resolveAuthorRoster } from "./resolveAuthors.js";
import { runWikiquote } from "./discover.js";

const envArg = process.argv.find((arg) => arg.startsWith("--env="))?.slice("--env=".length) ?? "";
if (envArg !== "prod" && envArg !== "emulator") {
  console.error("Usage: npm run bootstrap -- --env=prod|emulator");
  process.exit(1);
}

loadLocalEnv();
if (envArg === "prod") useFirebaseCliCredential();
if (envArg === "emulator") {
  process.env.FIRESTORE_EMULATOR_HOST ||= "127.0.0.1:8080";
  process.env.FIREBASE_STORAGE_EMULATOR_HOST ||= "127.0.0.1:9199";
}

initializeApp({
  projectId: process.env.GCLOUD_PROJECT || "motiscroll",
  storageBucket: "motiscroll.firebasestorage.app",
});

const works: WorkQuery[] = [
  { title: "Gettysburg Address", authorName: "Abraham Lincoln", field: "leadership", kind: "speech" },
  { title: "Abraham Lincoln's Second Inaugural Address", authorName: "Abraham Lincoln", field: "leadership", kind: "speech" },
  { title: "Franklin Roosevelt's First Inaugural Address", authorName: "Franklin D. Roosevelt", field: "leadership", kind: "speech" },
  { title: "Citizenship in a Republic", authorName: "Theodore Roosevelt", field: "leadership", kind: "speech" },
  { title: "What to the Slave Is the Fourth of July?", authorName: "Frederick Douglass", field: "leadership", kind: "speech" },
  { title: "Self-Reliance", authorName: "Ralph Waldo Emerson", field: "resilience", kind: "text" },
  { title: "Walden", authorName: "Henry David Thoreau", field: "resilience", kind: "text" },
  { title: "Meditations", authorName: "Marcus Aurelius", field: "resilience", kind: "text" },
  { title: "Moral letters to Lucilius", authorName: "Seneca", field: "resilience", kind: "text" },
  { title: "Enchiridion", authorName: "Epictetus", field: "resilience", kind: "text" },
  { title: "Song of Myself", authorName: "Walt Whitman", field: "arts", kind: "text" },
  { title: "Up from Slavery", authorName: "Booker T. Washington", field: "leadership", kind: "text" },
  { title: "Women's Right to the Suffrage", authorName: "Susan B. Anthony", field: "leadership", kind: "speech" },
  { title: "The Story of My Life", authorName: "Helen Keller", field: "resilience", kind: "text" },
  { title: "The Story of My Experiments with Truth", authorName: "Mahatma Gandhi", field: "leadership", kind: "text" },
];

const log = emptyImportLog();
const { todos, counts } = log;

main().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
});

async function main() {
  const db = getFirestore();
  const seeds = loadAuthorSeeds();
  const roster = await resolveAuthorRoster(seeds);
  console.log(`Authors resolved: ${roster.resolved}`);
  for (const row of roster.manualConfirm) {
    console.log(`Manual confirm: ${row.name} — ${row.reason}`);
    todos.push(`Author ${row.name}: ${row.reason}`);
  }

  await db.collection("config").doc("flags").set(
    { charactersEnabled: false, livingFiguresEnabled: true, updatedAt: FieldValue.serverTimestamp() },
    { merge: true },
  );

  for (const work of works) {
    try {
      await importWork(work, log);
    } catch (error) {
      counts.failed += 1;
      const message = error instanceof Error ? error.message : "fetch failed";
      todos.push(`${work.title}: ${message}`);
      console.log(`Failed ${work.title}: ${message}`);
    }
  }

  try {
    await runWikiquote();
    const waiting = await db.collection("items").where("status", "==", "candidate").get();
    for (const doc of waiting.docs) {
      await doc.ref.set({ status: "needs_review", updatedAt: FieldValue.serverTimestamp() }, { merge: true });
      counts.needsReview += 1;
    }
  } catch (error) {
    counts.failed += 1;
    todos.push(`Wikiquote: ${error instanceof Error ? error.message : "failed"}`);
  }

  const review = await db.collection("items").where("status", "==", "needs_review").get();
  counts.needsReview = review.size;

  try {
    const photos = await fetchMissingAuthorImages();
    console.log(`Author images stored: ${photos}`);
  } catch (error) {
    todos.push(`Author images: ${error instanceof Error ? error.message : "failed"}`);
  }

  await recomputeCollectionCounts();
  const daily = await backfillDaily(30);
  console.log(`Daily documents written: ${daily}`);
  console.log(
    `Summary found=${counts.found} added=${counts.added} skipped=${counts.skipped} failed=${counts.failed} needs_review=${counts.needsReview} approved=${counts.approved}`,
  );
  writeTodos();
}

function loadLocalEnv() {
  for (const file of [
    join(process.cwd(), ".env.local"),
    join(process.cwd(), ".env"),
    join(process.cwd(), "../.env"),
  ]) {
    try {
      const text = readFileSync(file, "utf8");
      for (const line of text.split("\n")) {
        const match = /^([A-Z0-9_]+)=(.*)$/.exec(line.trim());
        if (match && !process.env[match[1]]) process.env[match[1]] = match[2];
      }
    } catch {
      // Missing env files are expected until secrets are set.
    }
  }
}

function writeTodos() {
  const body = [
    "# TODO for humans",
    "",
    "Nothing in this file was published. These items could not be fetched or verified.",
    "",
    "- Living and recent figures (Kanye West, Lionel Messi, LeBron James, Steven Bartlett, Nelson Mandela, Oprah Winfrey, Steve Harvey, Maya Angelou, Muhammad Ali, Michael Jordan, and anyone else on the manual track) need a human to copy the exact line plus book, show, or interview page or timestamp into `content/manual_items.csv`. The example rows are labels, not quotations.",
    "- The name in the request was “steve batlet”. The roster uses Steven Bartlett and leaves the Wikidata match for the resolver. If that match is ambiguous, it is listed below.",
    "- Sports, business, and science need at least five published lines each before Feed and Discover leave the preparing screen. Public-domain texts do not supply those fields. Do not invent lines to fill them.",
    "- Winston Churchill and Martin Luther King Jr. were not queried for speech text. Their speeches are still under copyright. A licensed source has to be added by hand.",
    "- Privacy Policy and Terms still need a lawyer.",
    "- Register the iOS and Android apps with FlutterFire and enable Google, Apple, and email-link sign-in in the Firebase console. The mobile app ids in `lib/firebase_options.dart` are still the web app id.",
    "- Set a Blaze budget alert before deploying functions.",
    "",
    "## This run",
    "",
    ...todos.map((line) => `- ${line}`),
    "",
  ].join("\n");
  writeFileSync(join(process.cwd(), "../TODO_for_humans.md"), body);
}
