import type { Field, Item } from '@/data/items';

export function shuffle<T>(list: T[]) {
  const next = [...list];
  for (let index = next.length - 1; index > 0; index -= 1) {
    const swap = Math.floor(Math.random() * (index + 1));
    [next[index], next[swap]] = [next[swap], next[index]];
  }
  return next;
}

export function buildDiscoverOrder(items: Item[], followed: Field[]) {
  const followedSet = new Set(followed);
  const boosted = shuffle(items.filter((item) => followedSet.has(item.field)));
  const rest = shuffle(items.filter((item) => !followedSet.has(item.field)));
  return [...boosted, ...rest].map((item) => item.id);
}
