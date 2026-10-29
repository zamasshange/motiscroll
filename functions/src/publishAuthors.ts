import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";

import { useFirebaseCliCredential } from "./cliCredential.js";

const fields = new Set(["leadership", "science", "business", "sports", "arts", "resilience"]);

/// Copies the public part of each Wikidata-resolved roster author into
/// publishedAuthors, which signed-in readers can see. Living people never get a
/// portrait here because livingPhotoAllowed stays false.
export async function publishAuthors(): Promise<number> {
  const db = getFirestore();
  const authors = await db.collection("authors").get();
  const keep = new Set<string>();
  let batch = db.batch();
  let pending = 0;
  for (const doc of authors.docs) {
    const data = doc.data();
    if (!fields.has(String(data.field ?? "")) || !data.wikidataId || data.speakerType === "character") continue;
    keep.add(doc.id);
    const showPhoto = data.isLiving !== true || data.livingPhotoAllowed === true;
    const image = showPhoto ? (data.image as Record<string, unknown> | undefined) : undefined;
    const imageUrl = typeof image?.downloadUrl === "string" ? image.downloadUrl : "";
    batch.set(db.collection("publishedAuthors").doc(doc.id), {
      name: data.name,
      field: data.field,
      era: data.era ?? "",
      role: data.role ?? "",
      bornYear: data.bornYear ?? null,
      diedYear: data.diedYear ?? null,
      isLiving: data.isLiving === true,
      wikidataId: data.wikidataId,
      wikipediaTitle: data.wikipediaTitle ?? "",
      imageUrl,
      imageCredit: imageUrl
        ? { artist: image?.artist ?? "", license: image?.license ?? "", sourceUrl: image?.sourceUrl ?? "" }
        : null,
      updatedAt: FieldValue.serverTimestamp(),
    });
    pending += 1;
    if (pending === 400) {
      await batch.commit();
      batch = db.batch();
      pending = 0;
    }
  }
  const existing = await db.collection("publishedAuthors").select().get();
  for (const doc of existing.docs) {
    if (keep.has(doc.id)) continue;
    batch.delete(doc.ref);
    pending += 1;
    if (pending === 400) {
      await batch.commit();
      batch = db.batch();
      pending = 0;
    }
  }
  if (pending > 0) await batch.commit();
  return keep.size;
}

if (require.main === module) {
  useFirebaseCliCredential();
  initializeApp({ projectId: "motiscroll" });
  publishAuthors()
    .then((count) => console.log(`Published authors: ${count}`))
    .catch((error: unknown) => {
      console.error(error);
      process.exit(1);
    });
}
