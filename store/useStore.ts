import { useEffect } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { create } from 'zustand';
import { createJSONStorage, persist } from 'zustand/middleware';

import { ITEMS, type Field } from '@/data/items';
import { isField } from '@/data/taxonomy';
import { localDateKey, previousDateKey } from '@/utils/dates';
import { clamp } from '@/utils/number';
import { buildDiscoverOrder } from '@/utils/shuffle';

export type ThemePreference = 'dark' | 'light' | 'system';

const FONT_MIN = 0.85;
const FONT_MAX = 1.45;

type Persisted = {
  likedIds: string[];
  savedIds: string[];
  doneIds: string[];
  followedFields: Field[];
  themePreference: ThemePreference;
  fontScale: number;
  hintDismissed: boolean;
  streakCount: number;
  lastStreakDate: string | null;
  discoverQueue: string[];
  discoverIndex: number;
  onboardingComplete: boolean;
  usualMood: string | null;
};

type Store = Persisted & {
  hydrated: boolean;
  toggleLike: (id: string) => void;
  toggleSave: (id: string) => void;
  toggleDone: (id: string) => void;
  removeSave: (id: string) => void;
  toggleFollow: (field: Field) => void;
  setThemePreference: (theme: ThemePreference) => void;
  setFontScale: (scale: number) => void;
  dismissHint: () => void;
  recordView: () => void;
  setDiscoverQueue: (ids: string[], index?: number) => void;
  setDiscoverIndex: (index: number) => void;
  setUsualMood: (mood: string) => void;
  completeOnboarding: () => void;
  replayOnboarding: () => void;
  resetProgress: () => void;
};

const storage = createJSONStorage(() => ({
  getItem: (key) => {
    if (typeof window === 'undefined') return Promise.resolve(null);
    return AsyncStorage.getItem(key);
  },
  setItem: (key, value) => {
    if (typeof window === 'undefined') return Promise.resolve();
    return AsyncStorage.setItem(key, value);
  },
  removeItem: (key) => {
    if (typeof window === 'undefined') return Promise.resolve();
    return AsyncStorage.removeItem(key);
  },
}));

const emptyProgress = {
  likedIds: [] as string[],
  savedIds: [] as string[],
  doneIds: [] as string[],
  followedFields: [] as Field[],
  hintDismissed: false,
  streakCount: 0,
  lastStreakDate: null as string | null,
  discoverQueue: [] as string[],
  discoverIndex: 0,
  onboardingComplete: false,
  usualMood: null as string | null,
};

function toggleId(list: string[], id: string) {
  return list.includes(id) ? list.filter((entry) => entry !== id) : [...list, id];
}

export const useStore = create<Store>()(
  persist(
    (set, get) => ({
      hydrated: false,
      ...emptyProgress,
      themePreference: 'dark',
      fontScale: 1,
      toggleLike: (id) => {
        // PHASE 2: sync this like to the account.
        set((state) => ({ likedIds: toggleId(state.likedIds, id) }));
      },
      toggleSave: (id) => {
        // PHASE 2: sync saved items to the account.
        set((state) => ({ savedIds: toggleId(state.savedIds, id) }));
      },
      toggleDone: (id) => {
        // PHASE 2: sync completion to the account.
        set((state) => ({ doneIds: toggleId(state.doneIds, id) }));
      },
      removeSave: (id) => {
        // PHASE 2: sync the removal.
        set((state) => ({ savedIds: state.savedIds.filter((entry) => entry !== id) }));
      },
      toggleFollow: (field) => {
        // PHASE 2: sync followed fields to the account.
        const current = get().followedFields;
        const followed = current.includes(field)
          ? current.filter((entry) => entry !== field)
          : [...current, field];
        set({
          followedFields: followed,
          discoverQueue: buildDiscoverOrder(ITEMS, followed),
          discoverIndex: 0,
        });
      },
      setThemePreference: (themePreference) => set({ themePreference }),
      setFontScale: (scale) => set({ fontScale: clamp(scale, FONT_MIN, FONT_MAX) }),
      dismissHint: () => set({ hintDismissed: true }),
      recordView: () => {
        // PHASE 2: sync the streak.
        const today = localDateKey();
        const { lastStreakDate, streakCount } = get();
        if (lastStreakDate === today) return;
        const next = lastStreakDate === previousDateKey(today) ? streakCount + 1 : 1;
        set({ streakCount: next, lastStreakDate: today });
      },
      setDiscoverQueue: (ids, index = 0) => set({ discoverQueue: ids, discoverIndex: index }),
      setDiscoverIndex: (index) => set({ discoverIndex: index }),
      setUsualMood: (usualMood) => set({ usualMood }),
      completeOnboarding: () => set({ onboardingComplete: true }),
      replayOnboarding: () => set({ onboardingComplete: false }),
      resetProgress: () => {
        // PHASE 2: clear the same records on the server.
        const { onboardingComplete, usualMood } = get();
        set({
          ...emptyProgress,
          onboardingComplete,
          usualMood,
          discoverQueue: buildDiscoverOrder(ITEMS, []),
        });
      },
    }),
    {
      name: 'moti-scroll-state',
      storage,
      partialize: (state) => ({
        likedIds: state.likedIds,
        savedIds: state.savedIds,
        doneIds: state.doneIds,
        followedFields: state.followedFields,
        themePreference: state.themePreference,
        fontScale: state.fontScale,
        hintDismissed: state.hintDismissed,
        streakCount: state.streakCount,
        lastStreakDate: state.lastStreakDate,
        discoverQueue: state.discoverQueue,
        discoverIndex: state.discoverIndex,
        onboardingComplete: state.onboardingComplete,
        usualMood: state.usualMood,
      }),
      onRehydrateStorage: () => (state) => {
        const followed = (state?.followedFields ?? []).filter((field): field is Field =>
          isField(field),
        );
        useStore.setState({
          hydrated: true,
          followedFields: followed,
          fontScale: clamp(state?.fontScale ?? 1, FONT_MIN, FONT_MAX),
        });
      },
    },
  ),
);

export function useEnsureDiscoverQueue() {
  const hydrated = useStore((state) => state.hydrated);
  useEffect(() => {
    if (!hydrated) return;
    const { discoverQueue, followedFields, setDiscoverQueue } = useStore.getState();
    const ids = new Set(ITEMS.map((item) => item.id));
    const valid =
      discoverQueue.length === ITEMS.length && discoverQueue.every((id) => ids.has(id));
    if (!valid) setDiscoverQueue(buildDiscoverOrder(ITEMS, followedFields), 0);
  }, [hydrated]);
}
