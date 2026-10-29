import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

import { recomputeCollectionCounts } from "./approve.js";
import { useFirebaseCliCredential } from "./cliCredential.js";
import { emptyImportLog, importWork } from "./publicDomain.js";
import { publishAuthors } from "./publishAuthors.js";
import { slug } from "./resolveAuthors.js";

const perAuthor = 15;

const works: { title: string; authorName: string; kind: "speech" | "text" }[] = [
  { title: "My Inventions", authorName: "Nikola Tesla", kind: "text" },
  { title: "Pierre Curie", authorName: "Marie Curie", kind: "text" },
  { title: "Dream Psychology", authorName: "Sigmund Freud", kind: "text" },
  { title: "A General Introduction to Psychoanalysis", authorName: "Sigmund Freud", kind: "text" },
  { title: "The Montessori Method", authorName: "Maria Montessori", kind: "text" },
  { title: "My Life and Work", authorName: "Henry Ford", kind: "text" },
  { title: "Franklin D. Roosevelt's First Inaugural Address", authorName: "Franklin D. Roosevelt", kind: "speech" },
  { title: "Franklin Delano Roosevelt's Eighth State of the Union Address", authorName: "Franklin D. Roosevelt", kind: "speech" },
  { title: "The Story of My Experiments with Truth", authorName: "Mahatma Gandhi", kind: "text" },
  { title: "Indian Home Rule", authorName: "Mahatma Gandhi", kind: "text" },
  { title: "The Story of My Life", authorName: "Helen Keller", kind: "text" },
  { title: "Optimism", authorName: "Helen Keller", kind: "text" },
  { title: "Jacob's Room", authorName: "Virginia Woolf", kind: "text" },
  { title: "Monday or Tuesday", authorName: "Virginia Woolf", kind: "text" },
  { title: "Babe Ruth's Own Book of Baseball", authorName: "Babe Ruth", kind: "text" },
];

async function main() {
  useFirebaseCliCredential();
  initializeApp({ projectId: "motiscroll", storageBucket: "motiscroll.firebasestorage.app" });
  const db = getFirestore();
  const log = emptyImportLog();
  const perWork = new Map<string, number>();
  for (const work of works) perWork.set(work.authorName, (perWork.get(work.authorName) ?? 0) + 1);
  for (const work of works) {
    const author = (await db.collection("authors").doc(slug(work.authorName)).get()).data();
    const tracks: string[] = Array.isArray(author?.sourcingTrack) ? author.sourcingTrack : [];
    if (!author?.field || !tracks.includes("public_domain")) {
      log.todos.push(`${work.title}: ${work.authorName} is not on the public_domain track, so nothing was imported.`);
      continue;
    }
    const already = (
      await db.collection("publishedItems").where("authorId", "==", slug(work.authorName)).count().get()
    ).data().count;
    const limit = Math.floor(Math.max(0, perAuthor - already) / (perWork.get(work.authorName) ?? 1));
    if (limit === 0) {
      console.log(`${work.authorName}: already has ${already} published lines`);
      continue;
    }
    try {
      const result = await importWork({ ...work, field: String(author.field) }, log, limit);
      console.log(
        result
          ? `${work.authorName}: ${result.pageTitle} (${result.publisher}), ${result.kept} new excerpts`
          : `${work.authorName}: ${work.title} not imported`,
      );
    } catch (error) {
      log.counts.failed += 1;
      log.todos.push(`${work.title}: ${error instanceof Error ? error.message : "fetch failed"}`);
      console.log(`${work.authorName}: ${work.title} failed`);
    }
  }
  await recomputeCollectionCounts();
  console.log(`Published authors refreshed: ${await publishAuthors()}`);
  const { counts } = log;
  console.log(
    `Summary found=${counts.found} added=${counts.added} skipped=${counts.skipped} approved=${counts.approved} needs_review=${counts.needsReview} failed=${counts.failed}`,
  );
  for (const line of log.todos) console.log(`TODO\t${line}`);
}

main().catch((error: unknown) => {
  console.error(error);
  process.exit(1);
});
