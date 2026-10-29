import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { onCall } from "firebase-functions/v2/https";

import { assertEditor } from "./authz.js";
import { fetchText } from "./http.js";
import { contactEmail, enforceAppCheck } from "./secrets.js";

export function slug(name: string): string {
  return name
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

export interface AuthorSeed {
  name: string;
  field: string;
  era: "20th" | "modern";
}

export interface ConfirmRow {
  name: string;
  reason: string;
}

export interface LabelDiff {
  name: string;
  note: string;
}

interface SearchHit {
  id?: string;
  label?: string;
  description?: string;
  match?: { type?: string; text?: string };
}

interface ClaimValue {
  time?: string;
  id?: string;
}

interface EntityClaim {
  mainsnak?: { datavalue?: { value?: ClaimValue | string } };
}

interface EntityBody {
  descriptions?: Record<string, { value?: string }>;
  claims?: Record<string, EntityClaim[]>;
  sitelinks?: Record<string, { title?: string }>;
}

export function loadAuthorSeeds(): AuthorSeed[] {
  const file = [
    join(process.cwd(), "../scripts/authors_seed.json"),
    join(process.cwd(), "scripts/authors_seed.json"),
    join(process.cwd(), "authors_seed.json"),
  ].find((candidate) => existsSync(candidate));
  if (!file) throw new Error("authors_seed.json was not found.");
  const raw = JSON.parse(readFileSync(file, "utf8")) as AuthorSeed[];
  if (!Array.isArray(raw)) throw new Error("authors_seed.json must be an array.");
  return raw;
}

export const watchlistNames = [
  "Albert Einstein",
  "Mahatma Gandhi",
  "Winston Churchill",
  "Nelson Mandela",
  "Maya Angelou",
  "Steve Jobs",
  "Bruce Lee",
  "Audrey Hepburn",
  "Eleanor Roosevelt",
  "Mother Teresa",
  "The Dalai Lama",
  "Muhammad Ali",
  "Marilyn Monroe",
  "Mark Twain",
  "Abraham Lincoln",
  "Buddha",
];

export function sourcingTracks(diedYear: number | null, isLiving: boolean, wikiquoteTitle: string): string[] {
  const tracks: string[] = [];
  if (diedYear != null && diedYear < 1955) tracks.push("public_domain");
  if (wikiquoteTitle.trim()) tracks.push("wikiquote_candidates");
  if (isLiving || diedYear == null || diedYear >= 1955) tracks.push("manual_curation");
  return tracks;
}

export function eraDisagreement(
  era: string,
  bornYear: number | null,
  diedYear: number | null,
  isLiving: boolean,
): string | null {
  if (era === "20th" && isLiving) {
    return "Labeled 20th century. Wikidata has no death date, so this person is living.";
  }
  if (era === "20th" && bornYear != null && bornYear >= 1985) {
    return `Labeled 20th century. Wikidata birth year is ${bornYear}.`;
  }
  if (era === "modern" && diedYear != null && diedYear < 2000) {
    return `Labeled 2000 to now. Wikidata death year is ${diedYear}.`;
  }
  return null;
}

export async function lookupExactHuman(name: string): Promise<
  | { ok: true; id: string; description: string; entity: EntityBody }
  | { ok: false; reason: string }
> {
  const url =
    "https://www.wikidata.org/w/api.php?action=wbsearchentities&search=" +
    `${encodeURIComponent(name)}&language=en&format=json&type=item&limit=10`;
  let hits: SearchHit[] = [];
  try {
    const body = JSON.parse(await fetchText(url)) as { search?: SearchHit[] };
    hits = body.search ?? [];
  } catch (error) {
    return { ok: false, reason: error instanceof Error ? error.message : "Wikidata search failed." };
  }
  const named = hits.filter((hit) => knownAs(hit, name));
  if (named.length === 0) {
    return { ok: false, reason: hits.length === 0 ? "No Wikidata hit." : "No exact name match among the search hits." };
  }
  let humans: { id: string; description: string; entity: EntityBody }[] = [];
  try {
    humans = await humanEntities(named);
  } catch (error) {
    return { ok: false, reason: error instanceof Error ? error.message : "Entity fetch failed." };
  }
  if (humans.length !== 1) {
    const detail = (humans.length > 0 ? humans : named)
      .map((hit) => `${hit.id} ${"description" in hit ? hit.description : ""}`.trim())
      .join("; ");
    return {
      ok: false,
      reason: humans.length === 0 ? `No human entity for an exact name match. ${detail}` : `More than one person matches. ${detail}`,
    };
  }
  return { ok: true, ...humans[0] };
}

/// Uses the person English Wikipedia serves at exactly this title (following
/// redirects). Disambiguation pages and non-human items are refused.
export async function lookupWikipediaPrimary(name: string): Promise<
  | { ok: true; id: string; description: string; entity: EntityBody; title: string }
  | { ok: false; reason: string }
> {
  const url =
    "https://en.wikipedia.org/w/api.php?action=query&format=json&redirects=1&prop=pageprops" +
    `&ppprop=wikibase_item|disambiguation&titles=${encodeURIComponent(name)}`;
  let page: { title?: string; missing?: string; pageprops?: { wikibase_item?: string; disambiguation?: string } } | undefined;
  try {
    const body = JSON.parse(await fetchText(url)) as {
      query?: { pages?: Record<string, typeof page> };
    };
    page = Object.values(body.query?.pages ?? {})[0];
  } catch (error) {
    return { ok: false, reason: error instanceof Error ? error.message : "Wikipedia lookup failed." };
  }
  if (!page || page.missing !== undefined) return { ok: false, reason: "No English Wikipedia page at this title." };
  if (page.pageprops?.disambiguation !== undefined) {
    return { ok: false, reason: `English Wikipedia "${page.title}" is a disambiguation page.` };
  }
  const id = page.pageprops?.wikibase_item ?? "";
  if (!id) return { ok: false, reason: `English Wikipedia "${page.title}" has no Wikidata item.` };
  const entityUrl = `https://www.wikidata.org/wiki/Special:EntityData/${encodeURIComponent(id)}.json`;
  let entity: EntityBody | undefined;
  try {
    const entityDoc = JSON.parse(await fetchText(entityUrl)) as { entities?: Record<string, EntityBody> };
    entity = entityDoc.entities?.[id];
  } catch (error) {
    return { ok: false, reason: error instanceof Error ? error.message : "Entity fetch failed." };
  }
  if (!entity) return { ok: false, reason: `Wikidata ${id} could not be read.` };
  const types = claimIds(entity.claims?.P31);
  if (!types.includes("Q5") || types.includes("Q95074")) {
    return { ok: false, reason: `English Wikipedia "${page.title}" is ${id}, which Wikidata does not list as a human.` };
  }
  return {
    ok: true,
    id,
    description: entity.descriptions?.en?.value ?? "",
    entity,
    title: page.title ?? name,
  };
}

export async function writeAuthor(
  seed: AuthorSeed,
  found: { id: string; description: string; entity: EntityBody },
  resolvedVia: "exact_unique_human" | "enwiki_primary_topic",
) {
  const died = found.entity.claims?.P570;
  const bornYear = yearFrom(found.entity.claims?.P569);
  const diedYear = yearFrom(died);
  const isLiving = !died || died.length === 0;
  const wikiquoteTitle = found.entity.sitelinks?.enwikiquote?.title ?? "";
  const wikipediaTitle = found.entity.sitelinks?.enwiki?.title ?? "";
  const description = found.description.replace(/\s+/g, " ").trim();
  await getFirestore()
    .collection("authors")
    .doc(slug(seed.name))
    .set(
      {
        name: seed.name,
        slug: slug(seed.name),
        field: seed.field,
        era: seed.era,
        role: description,
        bioShort: description,
        sourcingTrack: sourcingTracks(diedYear, isLiving, wikiquoteTitle),
        watchlisted: watchlistNames.includes(seed.name),
        bornYear,
        diedYear,
        isLiving,
        livingPhotoAllowed: false,
        speakerType: "person",
        wikipediaTitle,
        wikidataId: found.id,
        wikiquoteTitle,
        resolvedVia,
        updatedAt: FieldValue.serverTimestamp(),
        createdAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  return {
    note: eraDisagreement(seed.era, bornYear, diedYear, isLiving),
    hasWikiquote: Boolean(wikiquoteTitle),
  };
}

export async function resolveAuthorRoster(seeds: AuthorSeed[]) {
  const manualConfirm: ConfirmRow[] = [];
  const labelDiffs: LabelDiff[] = [];
  const noWikiquote: string[] = [];
  let resolved = 0;
  for (const seed of seeds) {
    if (seed.field === "other" || !seed.name || (seed.era !== "20th" && seed.era !== "modern")) {
      manualConfirm.push({ name: seed.name, reason: "Seed row is missing a name, era, or field." });
      continue;
    }
    const found = await lookupExactHuman(seed.name);
    console.log(`${resolved + manualConfirm.length + 1}/${seeds.length} ${seed.name}`);
    if (!found.ok) {
      manualConfirm.push({ name: seed.name, reason: found.reason });
      await wait(350);
      continue;
    }
    try {
      const written = await writeAuthor(seed, found, "exact_unique_human");
      if (written.note) labelDiffs.push({ name: seed.name, note: written.note });
      if (!written.hasWikiquote) noWikiquote.push(seed.name);
      resolved += 1;
    } catch (error) {
      manualConfirm.push({
        name: seed.name,
        reason: error instanceof Error ? error.message : "Could not write the author.",
      });
    }
    await wait(350);
  }
  return { resolved, manualConfirm, labelDiffs, noWikiquote };
}

function knownAs(hit: SearchHit, name: string): boolean {
  const wanted = name.toLowerCase();
  if ((hit.label ?? "").toLowerCase() === wanted) return true;
  return (hit.match?.text ?? "").toLowerCase() === wanted;
}

function claimIds(claims: EntityClaim[] | undefined): string[] {
  const ids: string[] = [];
  for (const claim of claims ?? []) {
    const value = claim.mainsnak?.datavalue?.value;
    if (value && typeof value === "object" && typeof value.id === "string") ids.push(value.id);
  }
  return ids;
}

async function humanEntities(hits: SearchHit[]) {
  const found: { id: string; description: string; entity: EntityBody }[] = [];
  for (const hit of hits) {
    if (!hit.id) continue;
    const entityUrl = `https://www.wikidata.org/wiki/Special:EntityData/${encodeURIComponent(hit.id)}.json`;
    const entityDoc = JSON.parse(await fetchText(entityUrl)) as { entities?: Record<string, EntityBody> };
    const entity = entityDoc.entities?.[hit.id];
    if (!entity) continue;
    const types = claimIds(entity.claims?.P31);
    if (!types.includes("Q5") || types.includes("Q95074")) continue;
    found.push({ id: hit.id, description: hit.description ?? "", entity });
    await wait(200);
  }
  return found;
}

function yearFrom(claims: EntityClaim[] | undefined): number | null {
  const value = claims?.[0]?.mainsnak?.datavalue?.value;
  if (!value || typeof value === "string" || !value.time) return null;
  const match = /^([+-]\d+)/.exec(value.time);
  if (!match) return null;
  const year = Number(match[1]);
  return Number.isFinite(year) ? year : null;
}

function wait(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export const resolveAuthors = onCall(
  { enforceAppCheck: enforceAppCheck(), secrets: [contactEmail], timeoutSeconds: 1800 },
  async (request) => {
    assertEditor(request);
    return resolveAuthorRoster(loadAuthorSeeds());
  },
);
