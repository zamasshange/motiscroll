import { Pressable, Text, View } from 'react-native';

import { itemById } from '@/data/items';
import { useAppTheme } from '@/theme/useAppTheme';

export function RelatedChips({ ids, onPress }: { ids: string[]; onPress: (id: string) => void }) {
  const { colors, fonts, radii } = useAppTheme();
  const items = ids.map((id) => itemById(id)).filter((item) => item != null);
  if (items.length === 0) return null;

  return (
    <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8, flexGrow: 0 }}>
      {items.map((item) => (
        <Pressable
          key={item.id}
          onPress={() => onPress(item.id)}
          accessibilityRole="button"
          accessibilityLabel={`Open ${item.author}`}
          style={{
            borderRadius: radii.pill,
            borderWidth: 1,
            borderColor: colors.border,
            paddingHorizontal: 12,
            paddingVertical: 8,
            backgroundColor: colors.cardAlt,
          }}>
          <Text style={{ color: colors.text, fontFamily: fonts.sansMedium, fontSize: 13 }}>
            {item.author}
          </Text>
        </Pressable>
      ))}
    </View>
  );
}
