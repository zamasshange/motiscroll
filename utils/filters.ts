import type { Field, Item } from '@/data/items';
import { FIELD_META, MOODS } from '@/data/taxonomy';

export type FeedFilter =
  | { kind: 'all' }
  | { kind: 'field'; field: Field }
  | { kind: 'mood'; mood: string };

export function filterItems(items: Item[], filter: FeedFilter) {
  if (filter.kind === 'all') return items;
  if (filter.kind === 'field') return items.filter((item) => item.field === filter.field);
  return items.filter((item) => item.moods.includes(filter.mood));
}

export function filterLabel(filter: FeedFilter) {
  if (filter.kind === 'all') return 'All';
  if (filter.kind === 'field') return FIELD_META[filter.field].title;
  return MOODS.find((mood) => mood.id === filter.mood)?.label ?? 'Mood';
}

export function filterKey(filter: FeedFilter) {
  if (filter.kind === 'all') return 'all';
  if (filter.kind === 'field') return `field:${filter.field}`;
  return `mood:${filter.mood}`;
}
