import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

import { useFirebaseCliCredential } from "./cliCredential.js";

const envArg = process.argv.find((arg) => arg.startsWith("--env="))?.slice("--env=".length) ?? "prod";
if (envArg === "emulator") process.env.FIRESTORE_EMULATOR_HOST ||= "127.0.0.1:8080";
if (envArg === "prod") useFirebaseCliCredential();

initializeApp({ projectId: process.env.GCLOUD_PROJECT || "motiscroll" });

const fields = ["sports", "business", "science", "arts", "leadership", "resilience", "other"];

main().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
});

async function main() {
const db = getFirestore();
const snap = await db.collection("publishedItems").get();
const byField = new Map<string, number>(fields.map((field) => [field, 0]));
const byAuthor = new Map<string, number>();
let speeches = 0;
let quotes = 0;
let missingImage = 0;
let missingLocation = 0;
let unreviewedDeeper = 0;
const blocked: string[] = [];

for (const doc of snap.docs) {
  const data = doc.data();
  const field = String(data.field ?? "other");
  byField.set(field, (byField.get(field) ?? 0) + 1);
  const author = String(data.authorName ?? data.authorId ?? "unknown");
  byAuthor.set(author, (byAuthor.get(author) ?? 0) + 1);
  if (data.type === "speech") speeches += 1;
  else quotes += 1;
  if (!data.authorImageUrl) missingImage += 1;
  const source = data.primarySource ?? {};
  if (!String(source.pageOrTimestamp ?? "").trim()) missingLocation += 1;
  const deeper = data.deeper ?? {};
  if (deeper.humanReviewed === false || deeper.generatedBy === "ai") unreviewedDeeper += 1;
  const host = hostOf(String(source.url ?? ""));
  if (host.endsWith("wikiquote.org") || host.endsWith("wikipedia.org")) blocked.push(doc.id);
}

const authors = await db.collection("authors").get();
let authorsMissingImage = 0;
for (const author of authors.docs) {
  const data = author.data();
  if (data.speakerType === "character") continue;
  if (data.isLiving === true && data.livingPhotoAllowed !== true) continue;
  if (!data.image?.storagePath) authorsMissingImage += 1;
}

const items = await db.collection("items").where("status", "==", "approved").get();
let approvedUnreviewed = 0;
for (const item of items.docs) {
  const deeper = await item.ref.collection("deeper").doc("main").get();
  if (deeper.exists && deeper.data()?.humanReviewed !== true && deeper.data()?.generatedBy === "ai") {
    approvedUnreviewed += 1;
  }
}

console.log(`Published: ${snap.size}`);
console.log(`Quotes: ${quotes}  Speeches: ${speeches}`);
for (const field of fields) console.log(`  ${field}: ${byField.get(field) ?? 0}`);
console.log("Authors:");
for (const [name, count] of [...byAuthor.entries()].sort((a, b) => b[1] - a[1])) {
  console.log(`  ${name}: ${count}`);
}
console.log(`Published items missing an author image URL: ${missingImage}`);
console.log(`Authors with no stored image (living people excluded): ${authorsMissingImage}`);
console.log(`Published items missing page or timestamp: ${missingLocation}`);
console.log(`Published items whose deeper block is still an unreviewed AI draft: ${unreviewedDeeper + approvedUnreviewed}`);
console.log(`Published items sourced from wikiquote.org or wikipedia.org: ${blocked.length}`);

const thin = fields.filter((field) => field !== "other" && (byField.get(field) ?? 0) < 5);
const ready = snap.size >= 150 && thin.length === 0 && blocked.length === 0 && approvedUnreviewed === 0;
if (ready) {
  console.log("READY");
} else {
  console.log("NOT READY");
  if (snap.size < 150) console.log(`- Need ${150 - snap.size} more published items (have ${snap.size}).`);
  for (const field of thin) console.log(`- ${field} has ${byField.get(field) ?? 0} published items; need 5.`);
  if (blocked.length > 0) console.log(`- Blocked source domains: ${blocked.join(", ")}`);
  if (approvedUnreviewed > 0) console.log("- An approved item still has unreviewed AI deeper text.");
}
process.exit(ready ? 0 : 1);
}

function hostOf(raw: string): string {
  try {
    return new URL(raw).hostname.toLowerCase();
  } catch {
    return "";
  }
}
