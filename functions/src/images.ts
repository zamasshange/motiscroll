import { getStorage } from "firebase-admin/storage";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { onCall } from "firebase-functions/v2/https";

import { assertEditor } from "./authz.js";
import { fetchText } from "./http.js";
import { contactEmail, enforceAppCheck } from "./secrets.js";

const accepted = ["public domain", "cc0", "cc by", "cc by-sa"];

export const fetchAuthorImage = onCall(
  { enforceAppCheck: enforceAppCheck(), secrets: [contactEmail], timeoutSeconds: 180 },
  async (request) => {
    assertEditor(request);
    const only = String(request.data?.authorId ?? "");
    const db = getFirestore();
    const query = only
      ? db.collection("authors").where("__name__", "==", only).limit(1)
      : db.collection("authors").limit(30);
    const authors = await query.get();
    let stored = 0;
    for (const author of authors.docs) {
      const data = author.data();
      if (data.image?.storagePath) continue;
      if (data.speakerType === "character") continue;
      if (data.isLiving === true && data.livingPhotoAllowed !== true) continue;
      const qid = String(data.wikidataId ?? "");
      if (!qid) continue;
      try {
        const entity = JSON.parse(
          await fetchText(`https://www.wikidata.org/wiki/Special:EntityData/${encodeURIComponent(qid)}.json`),
        ) as { entities?: Record<string, { claims?: { P18?: { mainsnak?: { datavalue?: { value?: string } } }[] } }> };
        const file = entity.entities?.[qid]?.claims?.P18?.[0]?.mainsnak?.datavalue?.value;
        if (!file) continue;
        const infoUrl =
          "https://commons.wikimedia.org/w/api.php?action=query&format=json&prop=imageinfo&iiprop=url|extmetadata&iiextmetadatafilter=LicenseShortName|Artist|LicenseUrl|Attribution&titles=" +
          encodeURIComponent(`File:${file}`);
        const info = JSON.parse(await fetchText(infoUrl)) as {
          query?: { pages?: Record<string, { imageinfo?: { url?: string; extmetadata?: Record<string, { value?: string }> }[] }> };
        };
        const page = Object.values(info.query?.pages ?? {})[0];
        const image = page?.imageinfo?.[0];
        const meta = image?.extmetadata ?? {};
        const license = strip(meta.LicenseShortName?.value ?? "");
        const licenseKey = license.toLowerCase();
        const ok = accepted.some((name) => licenseKey === name || licenseKey.startsWith(name));
        if (!ok || !image?.url) continue;
        const bytes = await fetch(image.url, {
          headers: { "User-Agent": `MotiScroll/1.0 (${contactEmail.value() || "editor@example.com"})` },
        });
        if (!bytes.ok) continue;
        const buffer = Buffer.from(await bytes.arrayBuffer());
        const path = `author-images/${author.id}.jpg`;
        const bucket = getStorage().bucket();
        await bucket.file(path).save(buffer, { contentType: "image/jpeg", public: true, resumable: false });
        const downloadUrl = `https://storage.googleapis.com/${bucket.name}/${path}`;
        const artist = strip(meta.Artist?.value ?? "Unknown");
        const licenseUrl = strip(meta.LicenseUrl?.value ?? "");
        const sourceUrl = `https://commons.wikimedia.org/wiki/File:${encodeURIComponent(file)}`;
        const attributionText = `${artist} · ${license}`;
        await author.ref.set(
          {
            image: {
              storagePath: path,
              downloadUrl,
              artist,
              license,
              licenseUrl,
              sourceUrl,
              attributionText,
              requiresAttribution: licenseKey.startsWith("cc by"),
            },
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
        stored += 1;
      } catch (error) {
        console.error("image fetch failed", author.id, error);
      }
    }
    return { stored };
  },
);

function strip(value: string): string {
  return value.replace(/<[^>]+>/g, "").replace(/\s+/g, " ").trim().slice(0, 300);
}
