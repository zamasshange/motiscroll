import { Text } from 'react-native';

import { useAppTheme } from '@/theme/useAppTheme';

export function SectionLabel({ children }: { children: string }) {
  const { colors, fonts } = useAppTheme();
  return (
    <Text
      style={{
        fontFamily: fonts.sansSemibold,
        fontSize: 12,
        letterSpacing: 1.3,
        textTransform: 'uppercase',
        color: colors.textFaint,
      }}>
      {children}
    </Text>
  );
}
