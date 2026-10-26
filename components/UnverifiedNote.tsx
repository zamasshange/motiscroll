import { Text, View } from 'react-native';

import { useAppTheme } from '@/theme/useAppTheme';

export function UnverifiedNote() {
  const { colors, fonts, radii } = useAppTheme();
  return (
    <View
      style={{
        alignSelf: 'flex-start',
        borderRadius: radii.pill,
        borderWidth: 1,
        borderColor: colors.border,
        paddingHorizontal: 10,
        paddingVertical: 4,
      }}>
      <Text style={{ color: colors.textMuted, fontFamily: fonts.sansMedium, fontSize: 12 }}>
        Not verified
      </Text>
    </View>
  );
}
