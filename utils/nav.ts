import { router } from 'expo-router';

export function openFeed(params: { mood?: string; itemId?: string }) {
  router.navigate({
    pathname: '/(tabs)/feed',
    params: {
      mood: params.mood ?? '',
      itemId: params.itemId ?? '',
      at: String(Date.now()),
    },
  });
}
