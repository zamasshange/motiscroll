import { Text, View } from 'react-native';

import { useAppTheme } from '@/theme/useAppTheme';

export function DidYouKnow({ text, lines }: { text: string; lines?: number }) {
  const { colors, fonts, radii } = useAppTheme();
  return (
    <View
      style={{
        backgroundColor: colors.cardAlt,
        borderRadius: radii.control,
        padding: 14,
        gap: 6,
      }}>
      <Text style={{ color: colors.accent, fontFamily: fonts.sansSemibold, fontSize: 12 }}>
        Did you know?
      </Text>
      <Text
        numberOfLines={lines}
        style={{ color: colors.text, fontFamily: fonts.sans, fontSize: 15, lineHeight: 22 }}>
        {text}
      </Text>
    </View>
  );
}
