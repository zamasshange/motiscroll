import type { Field } from '@/data/items';
import { hashString } from '@/utils/format';

export const COVER_PALETTES: Record<Field, [string, string, string, string]> = {
  sports: ['#E7A394', '#C4524A', '#1C3144', '#7E2E3A'],
  business: ['#D7C4A2', '#8EA4B8', '#1B2836', '#3E5C78'],
  science: ['#B7DDD6', '#3E8F88', '#102E36', '#3C4F86'],
  arts: ['#F0C2B4', '#C46B7A', '#2A1C32', '#6E3A5C'],
  leadership: ['#C9D0E4', '#8A7348', '#1A2238', '#31456E'],
  resilience: ['#D7B7A6', '#C46A4A', '#102E2C', '#2F6A5E'],
  other: ['#E7C3B0', '#E07A4A', '#17191E', '#3A4150'],
};

export type CoverBlob = {
  color: string;
  x: number;
  y: number;
  size: number;
};

function mulberry32(seed: number) {
  let value = seed >>> 0;
  return () => {
    value = (value + 0x6d2b79f5) | 0;
    let t = Math.imul(value ^ (value >>> 15), 1 | value);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export function coverBlobs(field: Field, seed: string): CoverBlob[] {
  const palette = COVER_PALETTES[field];
  const rand = mulberry32(hashString(`${field}:${seed}`));
  return [0, 1, 2, 3].map((index) => ({
    color: palette[index],
    x: rand() * 0.9 - 0.15,
    y: rand() * 0.9 - 0.15,
    size: 0.55 + rand() * 0.45,
  }));
}
