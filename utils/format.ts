import type { Item } from '@/data/items';

export function sourceLine(item: Item) {
  return item.source.year ? `${item.source.title} · ${item.source.year}` : item.source.title;
}

export function formatDuration(seconds: number) {
  const minutes = Math.max(1, Math.round(seconds / 60));
  return `about ${minutes} min`;
}

export function firstParam(value: string | string[] | undefined) {
  return Array.isArray(value) ? value[0] : value;
}

export function hashString(value: string) {
  let hash = 2166136261;
  for (let index = 0; index < value.length; index += 1) {
    hash ^= value.charCodeAt(index);
    hash = Math.imul(hash, 16777619);
  }
  return hash >>> 0;
}
