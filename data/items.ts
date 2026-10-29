export type Field =
  | 'sports'
  | 'business'
  | 'science'
  | 'arts'
  | 'leadership'
  | 'resilience'
  | 'other';

export type Item = {
  id: string;
  type: 'quote' | 'speech';
  text: string;
  author: string;
  authorRole: string;
  field: Field;
  moods: string[];
  source: { title: string; year?: number; url?: string };
  verified: boolean;
  deeper: {
    context: string;
    didYouKnow: string;
    takeaway: string;
    related: string[];
  };
  speech?: { durationSec: number; watchUrl: string };
  imageUrl?: string;
  imageCredit?: { artist: string; license: string; sourceUrl: string };
};

/** The Expo draft is unused. The Flutter app reads publishedItems. */
export const ITEMS: Item[] = [];

export function itemById(id: string) {
  return ITEMS.find((item) => item.id === id);
}
