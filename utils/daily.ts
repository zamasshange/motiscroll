import { ITEMS } from '@/data/items';
import { localDateKey } from '@/utils/dates';
import { hashString } from '@/utils/format';

export function pickByDate<T>(list: T[], salt: string, date = new Date()): T | undefined {
  if (list.length === 0) return undefined;
  return list[hashString(`${localDateKey(date)}:${salt}`) % list.length];
}

export function dailyPicks(date = new Date()) {
  const verified = ITEMS.filter((item) => item.verified);
  const quotes = verified.filter((item) => item.type === 'quote');
  const speeches = verified.filter((item) => item.type === 'speech');
  return {
    quote: pickByDate(quotes, 'quote', date),
    speech: pickByDate(speeches, 'speech', date),
    boost: pickByDate(verified, 'boost', date),
  };
}
