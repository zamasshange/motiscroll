import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

import { useFirebaseCliCredential } from "./cliCredential.js";
import { eraDisagreement } from "./resolveAuthors.js";

const aggregatorHosts = [
  "brainyquote.com",
  "goodreads.com",
  "azquotes.com",
  "quotes.net",
  "quotefancy.com",
  "keepinspiring.me",
  "everydaypower.com",
  "goalcast.com",
];

const fields = ["leadership", "science", "business", "sports", "arts", "resilience"];

async function main(): Promise<void> {
  if (!process.env.FIRESTORE_EMULATOR_HOST) useFirebaseCliCredential();
  initializeApp({ projectId: process.env.GCLOUD_PROJECT || "motiscroll" });
  const db = getFirestore();
  const authors = await db.collection("authors").get();
  const items = await db.collection("items").select("authorId", "status").get();
  const published = await db.collection("publishedItems").select("authorId", "authorName", "field").get();
  const sources = await db.collectionGroup("sources").select("url").get();
  const watch = await db.collection("misattributionWatchlist").get();

  const byAuthor = new Map<string, { candidates: number; needsReview: number; approved: number; published: number }>();
  const blank = () => ({ candidates: 0, needsReview: 0, approved: 0, published: 0 });
  for (const doc of authors.docs) byAuthor.set(doc.id, blank());
  for (const doc of items.docs) {
    const authorId = String(doc.data().authorId ?? "");
    const row = byAuthor.get(authorId) ?? blank();
    const status = String(doc.data().status ?? "");
    if (status === "candidate") row.candidates += 1;
    else if (status === "needs_review") row.needsReview += 1;
    else if (status === "approved") row.approved += 1;
    byAuthor.set(authorId, row);
  }
  const publishedByAuthor = new Map<string, number>();
  const publishedByField = new Map<string, number>();
  for (const doc of published.docs) {
    const authorId = String(doc.data().authorId ?? "");
    publishedByAuthor.set(authorId, (publishedByAuthor.get(authorId) ?? 0) + 1);
    const field = String(doc.data().field ?? "other");
    publishedByField.set(field, (publishedByField.get(field) ?? 0) + 1);
    const row = byAuthor.get(authorId) ?? blank();
    row.published += 1;
    byAuthor.set(authorId, row);
  }

  const authorOfItem = new Map<string, string>();
  for (const doc of items.docs) authorOfItem.set(doc.id, String(doc.data().authorId ?? ""));
  const sourceHosts = new Map<string, { aggregator: number; other: number }>();
  for (const doc of sources.docs) {
    const itemId = doc.ref.parent.parent?.id ?? "";
    const authorId = authorOfItem.get(itemId) ?? "";
    if (!authorId) continue;
    const host = hostname(String(doc.data().url ?? ""));
    const row = sourceHosts.get(authorId) ?? { aggregator: 0, other: 0 };
    if (aggregatorHosts.some((name) => host === name || host.endsWith(`.${name}`))) row.aggregator += 1;
    else if (host) row.other += 1;
    sourceHosts.set(authorId, row);
  }

  console.log("Author\tfield\tera\ttracks\tcandidates\tneeds_review\tapproved\tpublished");
  const zero: string[] = [];
  const diffs: string[] = [];
  const aggregatorFlags: string[] = [];
  let era20 = 0;
  let eraModern = 0;
  for (const doc of authors.docs) {
    const data = doc.data();
    const counts = byAuthor.get(doc.id) ?? blank();
    const tracks = Array.isArray(data.sourcingTrack) ? data.sourcingTrack.join(",") : "";
    console.log(
      `${data.name ?? doc.id}\t${data.field ?? ""}\t${data.era ?? ""}\t${tracks}\t${counts.candidates}\t${counts.needsReview}\t${counts.approved}\t${counts.published}`,
    );
    if (counts.published === 0 && data.field) zero.push(String(data.name ?? doc.id));
    if (data.era === "20th") era20 += 1;
    if (data.era === "modern") eraModern += 1;
    const note = eraDisagreement(
      String(data.era ?? ""),
      typeof data.bornYear === "number" ? data.bornYear : null,
      typeof data.diedYear === "number" ? data.diedYear : null,
      data.isLiving === true,
    );
    if (note) diffs.push(`${data.name}: ${note}`);
    const hosts = sourceHosts.get(doc.id);
    if (hosts && hosts.aggregator > hosts.other) {
      aggregatorFlags.push(`${data.name}: ${hosts.aggregator} aggregator sources, ${hosts.other} other`);
    }
  }

  console.log("\nPublished by field");
  for (const field of fields) {
    const count = publishedByField.get(field) ?? 0;
    console.log(`${field}\t${count}${count < 5 ? "\tUNDER 5" : ""}`);
  }

  const totalPublished = published.size;
  console.log(`\nPublished items: ${totalPublished}`);
  console.log("Authors over 5% of published items");
  let over = 0;
  for (const [authorId, count] of publishedByAuthor) {
    if (totalPublished === 0 || count / totalPublished <= 0.05) continue;
    over += 1;
    const name = authors.docs.find((doc) => doc.id === authorId)?.data().name ?? authorId;
    console.log(`${name}\t${count}\t${((count / totalPublished) * 100).toFixed(1)}%`);
  }
  if (over === 0) console.log("None");

  const eraTotal = era20 + eraModern;
  console.log(
    `\nEra split among roster authors: 20th ${era20}, modern ${eraModern}` +
      (eraTotal === 0 ? "" : ` (${Math.round((era20 / eraTotal) * 100)}% / ${Math.round((eraModern / eraTotal) * 100)}%)`),
  );
  console.log("\nWatchlist");
  for (const doc of watch.docs) console.log(doc.data().name ?? doc.id);
  console.log("\nAuthors with zero published items");
  for (const name of zero) console.log(name);
  console.log("\nEra or living disagreements");
  for (const line of diffs) console.log(line);
  if (diffs.length === 0) console.log("None");
  console.log("\nAuthors whose found sources are mostly quote aggregators");
  for (const line of aggregatorFlags) console.log(line);
  if (aggregatorFlags.length === 0) console.log("None");
}

function hostname(url: string): string {
  try {
    return new URL(url).hostname.replace(/^www\./, "").toLowerCase();
  } catch {
    return "";
  }
}

main().catch((error: unknown) => {
  console.error(error);
  process.exit(1);
});
