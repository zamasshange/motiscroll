import { Ionicons } from '@expo/vector-icons';
import { Pressable, Text, View } from 'react-native';

import { useAppTheme } from '@/theme/useAppTheme';

export function HintBanner({ onDismiss }: { onDismiss: () => void }) {
  const { colors, fonts, radii } = useAppTheme();
  return (
    <View
      style={{
        flexDirection: 'row',
        alignItems: 'center',
        gap: 10,
        backgroundColor: colors.card,
        borderRadius: radii.control,
        borderWidth: 1,
        borderColor: colors.border,
        paddingVertical: 10,
        paddingLeft: 14,
        paddingRight: 8,
      }}>
      <Text style={{ flex: 1, color: colors.text, fontFamily: fonts.sansMedium, fontSize: 14 }}>
        Swipe up for next, tap to go deeper
      </Text>
      <Pressable onPress={onDismiss} accessibilityRole="button" accessibilityLabel="Dismiss hint" hitSlop={8}>
        <Ionicons name="close" size={18} color={colors.textMuted} />
      </Pressable>
    </View>
  );
}
