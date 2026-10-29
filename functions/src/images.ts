import { FieldValue, Firestore, getFirestore } from "firebase-admin/firestore";
import { onCall } from "firebase-functions/v2/https";

import { assertEditor } from "./authz.js";
import { fetchText } from "./http.js";
import { contactEmail, enforceAppCheck } from "./secrets.js";

export async function fetchMissingAuthorImages(only = ""): Promise<number> {
  const db = getFirestore();
    const single = only ? await db.collection("authors").doc(only).get() : null;
    const authors = single
      ? single.exists
        ? [single]
        : []
      : (await db.collection("authors").get()).docs;
    let stored = 0;
    for (const author of authors) {
      const data = author.data();
      if (!data) continue;
      if (data.image?.downloadUrl) {
        await copyPortrait(db, author.id, data.image as Record<string, unknown>);
        continue;
      }
      if (data.speakerType === "character") continue;
      if (data.isLiving === true && data.livingPhotoAllowed !== true) continue;
      const qid = String(data.wikidataId ?? "");
      if (!qid) continue;
      try {
        const entity = JSON.parse(
          await fetchText(`https://www.wikidata.org/wiki/Special:EntityData/${encodeURIComponent(qid)}.json`),
        ) as { entities?: Record<string, { claims?: { P18?: { mainsnak?: { datavalue?: { value?: string } } }[] } }> };
        const files = (entity.entities?.[qid]?.claims?.P18 ?? [])
          .map((claim) => claim.mainsnak?.datavalue?.value)
          .filter((value): value is string => typeof value === "string" && value.length > 0);
        const found = await firstAllowedPortrait(files);
        if (!found) continue;
        const portrait = {
          storagePath: "",
          downloadUrl: found.downloadUrl,
          artist: found.artist,
          license: found.license,
          licenseUrl: found.licenseUrl,
          sourceUrl: found.sourceUrl,
          attributionText: `${found.artist} · ${found.license}`,
          requiresAttribution: found.license.toLowerCase().includes("by"),
        };
        await author.ref.set(
          { image: portrait, updatedAt: FieldValue.serverTimestamp() },
          { merge: true },
        );
        await copyPortrait(db, author.id, portrait);
        stored += 1;
      } catch (error) {
        console.error("image fetch failed", author.id, error);
      }
    }
  return stored;
}

export const fetchAuthorImage = onCall(
  { enforceAppCheck: enforceAppCheck(), secrets: [contactEmail], timeoutSeconds: 180 },
  async (request) => {
    assertEditor(request);
    const stored = await fetchMissingAuthorImages(String(request.data?.authorId ?? ""));
    return { stored };
  },
);

function strip(value: string): string {
  return value.replace(/<[^>]+>/g, "").replace(/\s+/g, " ").trim().slice(0, 300);
}

export interface AllowedPortrait {
  downloadUrl: string;
  artist: string;
  license: string;
  licenseUrl: string;
  sourceUrl: string;
}

export async function firstAllowedPortrait(files: string[]): Promise<AllowedPortrait | null> {
  for (const candidate of files) {
    const infoUrl =
      "https://commons.wikimedia.org/w/api.php?action=query&format=json&origin=*&prop=imageinfo&iiprop=url|extmetadata&iiurlwidth=800&iiextmetadatafilter=LicenseShortName|Artist|LicenseUrl&titles=" +
      encodeURIComponent(`File:${candidate}`);
    const info = JSON.parse(await fetchText(infoUrl)) as {
      query?: {
        pages?: Record<
          string,
          { imageinfo?: { url?: string; thumburl?: string; extmetadata?: Record<string, { value?: string }> }[] }
        >;
      };
    };
    const image = Object.values(info.query?.pages ?? {})[0]?.imageinfo?.[0];
    const license = strip(image?.extmetadata?.LicenseShortName?.value ?? "");
    const downloadUrl = image?.thumburl || image?.url || "";
    if (!portraitLicenseOk(license) || !downloadUrl) continue;
    return {
      downloadUrl,
      artist: strip(image?.extmetadata?.Artist?.value ?? "Unknown"),
      license,
      licenseUrl: strip(image?.extmetadata?.LicenseUrl?.value ?? ""),
      sourceUrl: `https://commons.wikimedia.org/wiki/File:${encodeURIComponent(candidate)}`,
    };
  }
  return null;
}

function portraitLicenseOk(license: string): boolean {
  const key = license.toLowerCase();
  if (!key || key.includes("-nc") || key.includes("-nd")) return false;
  if (key.startsWith("public domain") || key.startsWith("pd-") || key === "pdm" || key.startsWith("pdm-") || key.startsWith("cc0")) {
    return true;
  }
  if (key === "godl-india") return true;
  if (key.includes("no restrictions")) return true;
  if (key.startsWith("cc by-sa") || key.startsWith("cc-by-sa")) return true;
  return (key.startsWith("cc by") || key.startsWith("cc-by")) && !key.includes("nc") && !key.includes("nd");
}

async function copyPortrait(db: Firestore, authorId: string, image: Record<string, unknown>) {
  const downloadUrl = String(image.downloadUrl ?? "");
  if (!downloadUrl) return;
  const items = await db.collection("publishedItems").where("authorId", "==", authorId).get();
  let batch = db.batch();
  let writes = 0;
  for (const item of items.docs) {
    if (item.data().authorImageUrl === downloadUrl) continue;
    batch.set(
      item.ref,
      {
        authorImageUrl: downloadUrl,
        imageCredit: {
          artist: String(image.artist ?? ""),
          license: String(image.license ?? ""),
          sourceUrl: String(image.sourceUrl ?? ""),
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
}
