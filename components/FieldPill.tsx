import { Text, View } from 'react-native';

import type { Field } from '@/data/items';
import { FIELD_META } from '@/data/taxonomy';
import { useAppTheme } from '@/theme/useAppTheme';

export function FieldPill({ field }: { field: Field }) {
  const { colors, fonts, radii } = useAppTheme();
  return (
    <View
      style={{
        alignSelf: 'flex-start',
        backgroundColor: colors.accentSoft,
        borderRadius: radii.pill,
        paddingHorizontal: 12,
        paddingVertical: 6,
      }}>
      <Text style={{ color: colors.accent, fontFamily: fonts.sansSemibold, fontSize: 12 }}>
        {FIELD_META[field].title}
      </Text>
    </View>
  );
}
