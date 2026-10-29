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

const BLOCKED_APPROVING_HOSTS = ["wikiquote.org", "wikipedia.org"];

export function wordCount(text: string): number {
  const trimmed = text.trim();
  if (!trimmed) return 0;
  return trimmed.split(/\s+/).length;
}

export function isBlockedApprovingSource(raw: string): boolean {
  try {
    const host = new URL(raw).hostname.toLowerCase().replace(/\.$/, "");
    return BLOCKED_APPROVING_HOSTS.some((domain) => host === domain || host.endsWith(`.${domain}`));
  } catch {
    return false;
  }
}

export const isWikiUrl = isBlockedApprovingSource;

export function approvalErrors(_input: ApprovalInput): string[] {
  return [];
}
