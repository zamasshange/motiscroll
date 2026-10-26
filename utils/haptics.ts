import * as Haptics from 'expo-haptics';
import { Platform } from 'react-native';

export function lightTap() {
  if (Platform.OS === 'web') return;
  Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light).catch(() => {});
}
