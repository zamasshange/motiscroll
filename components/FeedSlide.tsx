import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { AuthorAvatar } from '@/components/AuthorAvatar';
import { FieldPill } from '@/components/FieldPill';
import { GeneratedCover } from '@/components/GeneratedCover';
import { RiseIn } from '@/components/RiseIn';
import { SpeechBadge } from '@/components/SpeechBadge';
import { UnverifiedNote } from '@/components/UnverifiedNote';
import type { Item } from '@/data/items';
import { useAppTheme, useDockInset } from '@/theme/useAppTheme';
import { layout } from '@/theme/tokens';
import { sourceLine } from '@/utils/format';

export function FeedSlide({
  item,
  fontScale,
  active,
  onOpen,
}: {
  item: Item;
  fontScale: number;
  active: boolean;
  onOpen: () => void;
}) {
  const { colors, fonts } = useAppTheme();
  const insets = useSafeAreaInsets();
  const dock = useDockInset();
  const size = layout.feedBaseFontSize * fontScale;

  return (
    <RiseIn active={active}>
      <View style={{ flex: 1, backgroundColor: colors.bg }}>
        <GeneratedCover field={item.field} seed={item.id} variant="subtle" style={StyleSheet.absoluteFill} />
        <View
          style={{
            flex: 1,
            paddingTop: insets.top + 92,
            paddingBottom: dock,
            paddingHorizontal: 68,
            justifyContent: 'center',
            alignItems: 'center',
            gap: 16,
          }}>
          <FieldPill field={item.field} />
          {item.verified ? null : <UnverifiedNote />}
          <Pressable onPress={onOpen} accessibilityRole="button" accessibilityLabel="Go deeper">
            <Text
              allowFontScaling
              maxFontSizeMultiplier={1.8}
              adjustsFontSizeToFit
              minimumFontScale={0.72}
              numberOfLines={10}
              style={{
                color: colors.text,
                fontFamily: fonts.serifItalic,
                fontSize: size,
                lineHeight: size * 1.38,
                textAlign: 'center',
              }}>
              {item.text}
            </Text>
          </Pressable>
          <View style={{ flexDirection: 'row', alignItems: 'center', gap: 10, paddingHorizontal: 8 }}>
            <AuthorAvatar
              author={item.author}
              imageUrl={item.imageUrl}
              credit={item.imageCredit}
              field={item.field}
              size={36}
            />
            <View style={{ flexShrink: 1, gap: 2 }}>
              <Text style={{ color: colors.text, fontFamily: fonts.sansSemibold, fontSize: 16 }}>{item.author}</Text>
              <Text style={{ color: colors.textMuted, fontFamily: fonts.sans, fontSize: 13 }}>{item.authorRole}</Text>
              <Text style={{ color: colors.textFaint, fontFamily: fonts.sans, fontSize: 13 }}>{sourceLine(item)}</Text>
            </View>
          </View>
          <Pressable onPress={onOpen} accessibilityRole="button" accessibilityLabel="Go deeper" hitSlop={8}>
            <Text style={{ color: colors.accent, fontFamily: fonts.sansSemibold, fontSize: 15 }}>Go deeper</Text>
          </Pressable>
          <SpeechBadge item={item} />
        </View>
      </View>
    </RiseIn>
  );
}