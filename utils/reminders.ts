import * as Notifications from 'expo-notifications';
import { Platform } from 'react-native';

import { APP_NAME } from '@/theme/tokens';

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowBanner: true,
    shouldShowList: true,
    shouldPlaySound: false,
    shouldSetBadge: false,
  }),
});

export async function enableMorningReminder() {
  if (Platform.OS === 'web') return false;
  const current = await Notifications.getPermissionsAsync();
  const next =
    current.status === 'granted' ? current : await Notifications.requestPermissionsAsync();
  if (next.status !== 'granted') return false;
  await Notifications.cancelAllScheduledNotificationsAsync();
  // PHASE 2: a server can replace this local reminder. The device only stores the schedule.
  await Notifications.scheduleNotificationAsync({
    content: {
      title: APP_NAME,
      body: 'A line is waiting when you are.',
    },
    trigger: {
      type: Notifications.SchedulableTriggerInputTypes.DAILY,
      hour: 8,
      minute: 0,
    },
  });
  return true;
}
