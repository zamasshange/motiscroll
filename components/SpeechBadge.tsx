import { Ionicons } from '@expo/vector-icons';
import { Pressable, Text, View } from 'react-native';

import type { Item } from '@/data/items';
import { useAppTheme } from '@/theme/useAppTheme';
import { formatDuration } from '@/utils/format';
import { openExternal } from '@/utils/openExternal';

export function SpeechBadge({ item }: { item: Item }) {
  const { colors, fonts, radii } = useAppTheme();
  if (!item.speech) return null;
  const speech = item.speech;

  return (
    <View style={{ gap: 8 }}>
      <View style={{ flexDirection: 'row', alignItems: 'center', gap: 10, flexWrap: 'wrap' }}>
        <View
          style={{
            flexDirection: 'row',
            alignItems: 'center',
            gap: 6,
            backgroundColor: colors.accentSoft,
            borderRadius: radii.pill,
            paddingHorizontal: 12,
            paddingVertical: 8,
          }}>
          <Ionicons name="play" size={14} color={colors.accent} />
          <Text style={{ color: colors.accent, fontFamily: fonts.sansSemibold, fontSize: 13 }}>
            {formatDuration(speech.durationSec)}
          </Text>
        </View>
        <Pressable
          onPress={() => openExternal(speech.watchUrl)}
          accessibilityRole="button"
          accessibilityLabel="Watch full speech"
          hitSlop={8}>
          <Text style={{ color: colors.text, fontFamily: fonts.sansSemibold, fontSize: 15 }}>
            Watch full speech
          </Text>
        </Pressable>
      </View>
      <Text style={{ color: colors.textFaint, fontFamily: fonts.sans, fontSize: 12 }}>
        Opens the full public-domain text in your browser.
      </Text>
    </View>
  );
}
