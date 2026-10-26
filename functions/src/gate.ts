export type SourceType = "primary" | "secondary" | "transcript" | "video";
export type Confidence = "confirmed" | "probable" | "disputed";
export type RightsStatus =
  | "public_domain"
  | "government"
  | "licensed"
  | "link_out_only"
  | "unknown";

export interface SourceDoc {
  title?: string;
  url?: string;
  year?: number | null;
  pageOrTimestamp?: string;
  sourceType?: SourceType;
  confidence?: Confidence;
}

export interface ApprovalInput {
  type: "quote" | "speech";
  verified: boolean;
  wordCount: number;
  longQuoteOverrideReason?: string;
  sources: SourceDoc[];
  speech?: { rightsStatus?: RightsStatus } | null;
  author: { isLiving?: boolean; speakerType?: "person" | "character" };
  onWatchlist: boolean;
  deeper?: { generatedBy?: "human" | "ai"; humanReviewed?: boolean } | null;
  charactersEnabled: boolean;
}

const WIKI_HOSTS = [
  "wikiquote.org",
  "wikipedia.org",
  "wikimedia.org",
  "wikisource.org",
  "wikidata.org",
  "mediawiki.org",
];

export function wordCount(text: string): number {
  const trimmed = text.trim();
  if (!trimmed) return 0;
  return trimmed.split(/\s+/).length;
}

export function isWikiUrl(raw: string): boolean {
  try {
    const host = new URL(raw).hostname.toLowerCase().replace(/\.$/, "");
    if (host.endsWith(".wiki")) return true;
    return WIKI_HOSTS.some((domain) => host === domain || host.endsWith(`.${domain}`));
  } catch {
    return false;
  }
}

export function approvalErrors(input: ApprovalInput): string[] {
  const errors: string[] = [];
  if (!input.verified) {
    errors.push("The editor must set verified to true. A candidate is not publishable.");
  }
  const withUrl = input.sources.filter((source) => (source.url ?? "").trim().length > 0);
  if (input.sources.length === 0 || withUrl.length === 0) {
    errors.push("At least one source with a URL is required.");
  }
  for (const source of withUrl) {
    if (isWikiUrl(source.url!)) {
      errors.push(
        `Source URL ${source.url} is on a wiki domain. Wikiquote and Wikipedia are discovery aids, not the approving source.`,
      );
    }
  }
  if (input.type === "speech") {
    const rights = input.speech?.rightsStatus ?? "unknown";
    if (rights === "unknown") {
      errors.push("Speeches cannot be approved while rightsStatus is unknown.");
    }
  }
  if (input.author.isLiving) {
    const primary = input.sources.find(
      (source) =>
        source.sourceType === "primary" && (source.pageOrTimestamp ?? "").trim().length > 0,
    );
    if (!primary) {
      errors.push("A living author needs a primary source with a page or timestamp.");
    }
  }
  if (input.onWatchlist) {
    const confirmed = input.sources.find(
      (source) => source.sourceType === "primary" && source.confidence === "confirmed",
    );
    if (!confirmed) {
      errors.push("This author is on the misattribution watchlist and needs a confirmed primary source.");
    }
  }
  if (input.deeper?.generatedBy === "ai" && input.deeper.humanReviewed !== true) {
    errors.push("AI-drafted Go deeper text must be marked humanReviewed before it can publish.");
  }
  if (input.wordCount > 40 && !(input.longQuoteOverrideReason ?? "").trim()) {
    errors.push("Quotes over 40 words need an explicit editor override and a reason.");
  }
  if (input.author.speakerType === "character" && !input.charactersEnabled) {
    errors.push("Characters stay unpublished while config/flags.charactersEnabled is false.");
  }
  return errors;
}
