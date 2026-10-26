import type { Field } from '@/data/items';

export type MoodId =
  | 'starting-over'
  | 'bad-day'
  | 'need-focus'
  | 'pre-workout'
  | 'exam-stress'
  | 'feeling-stuck';

export const MOODS: { id: MoodId; label: string }[] = [
  { id: 'starting-over', label: 'Starting over' },
  { id: 'bad-day', label: 'Bad day' },
  { id: 'need-focus', label: 'Need focus' },
  { id: 'pre-workout', label: 'Pre-workout' },
  { id: 'exam-stress', label: 'Exam stress' },
  { id: 'feeling-stuck', label: 'Feeling stuck' },
];

export const FIELD_ORDER: Field[] = [
  'sports',
  'business',
  'science',
  'arts',
  'leadership',
  'resilience',
];

export const FIELD_META: Record<
  Field,
  { title: string; description: string; tint: [string, string] }
> = {
  sports: {
    title: 'Sports',
    description: 'Effort, craft, and the nerve to begin again.',
    tint: ['#8C4A32', '#3A241C'],
  },
  business: {
    title: 'Business',
    description: 'Building, deciding, and staying with the work.',
    tint: ['#6E5644', '#2A221C'],
  },
  science: {
    title: 'Science',
    description: 'Curiosity with the patience to be wrong.',
    tint: ['#3E625C', '#1A2A28'],
  },
  arts: {
    title: 'Arts',
    description: 'Making something that did not exist yesterday.',
    tint: ['#8A4E3A', '#2C1C16'],
  },
  leadership: {
    title: 'Leadership',
    description: 'The weight of choosing for more than yourself.',
    tint: ['#4A5168', '#1C2030'],
  },
  resilience: {
    title: 'Resilience',
    description: 'How people continue when the day goes badly.',
    tint: ['#7A4034', '#2A1814'],
  },
  other: {
    title: 'Other',
    description: 'Lines that do not sit in a single field.',
    tint: ['#2A2A2E', '#17171A'],
  },
};

export function isField(value: string): value is Field {
  return value in FIELD_META;
}

export function isMood(value: string): value is MoodId {
  return MOODS.some((mood) => mood.id === value);
}
