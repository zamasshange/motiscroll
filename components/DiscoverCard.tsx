import { Ionicons } from '@expo/vector-icons';
import { Pressable, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { AuthorAvatar } from '@/components/AuthorAvatar';
import { DidYouKnow } from '@/components/DidYouKnow';
import { GeneratedCover } from '@/components/GeneratedCover';
import { IconHit } from '@/components/PrimaryButton';
import { RelatedChips } from '@/components/RelatedChips';
import { RiseIn } from '@/components/RiseIn';
import { SectionLabel } from '@/components/SectionLabel';
import { SpeechBadge } from '@/components/SpeechBadge';
import { UnverifiedNote } from '@/components/UnverifiedNote';
import type { Item } from '@/data/items';
import { FIELD_META } from '@/data/taxonomy';
import { useAppTheme, useDockInset } from '@/theme/useAppTheme';
import { sourceLine } from '@/utils/format';

export function DiscoverCard({
  item,
  saved,
  done,
  active,
  onOpen,
  onSave,
  onShare,
  onDone,
  onRelated,
}: {
  item: Item;
  saved: boolean;
  done: boolean;
  active: boolean;
  onOpen: () => void;
  onSave: () => void;
  onShare: () => void;
  onDone: () => void;
  onRelated: (id: string) => void;
}) {
  const { colors, fonts, radii } = useAppTheme();
  const insets = useSafeAreaInsets();
  const dock = useDockInset();

  return (
    <RiseIn active={active}>
    <View style={{ flex: 1, paddingTop: insets.top + 12, paddingBottom: dock, paddingHorizontal: 16 }}>
      <View
        style={{
          flex: 1,
          backgroundColor: colors.card,
          borderRadius: radii.card,
          borderWidth: 1,
          borderColor: colors.border,
          overflow: 'hidden',
        }}>
        <View style={{ height: 112 }}>
          <GeneratedCover field={item.field} seed={item.id} style={{ height: 112 }} />
          <View style={{ position: 'absolute', left: 16, right: 16, bottom: 14, flexDirection: 'row', justifyContent: 'space-between' }}>
            <Text
              style={{
                color: '#F4F1EA',
                fontFamily: fonts.serif,
                fontSize: 28,
                textShadowColor: 'rgba(0,0,0,0.45)',
                textShadowOffset: { width: 0, height: 1 },
                textShadowRadius: 6,
              }}>
              {FIELD_META[item.field].title}
            </Text>
            {item.verified ? null : <UnverifiedNote />}
          </View>
        </View>
        <View style={{ padding: 20, gap: 12, flex: 1 }}>
        <View style={{ flexDirection: 'row', gap: 12, alignItems: 'center' }}>
          <AuthorAvatar author={item.author} imageUrl={item.imageUrl} credit={item.imageCredit} field={item.field} size={44} showCredit />
          <View style={{ flex: 1, gap: 2 }}>
            <Text style={{ color: colors.text, fontFamily: fonts.serif, fontSize: 26, lineHeight: 32 }}>{item.author}</Text>
            <Text style={{ color: colors.textMuted, fontFamily: fonts.sans, fontSize: 14 }}>{item.authorRole}</Text>
            <Text style={{ color: colors.textFaint, fontFamily: fonts.sans, fontSize: 13 }}>{sourceLine(item)}</Text>
          </View>
        </View>
        <Text style={{ color: colors.text, fontFamily: fonts.serifItalic, fontSize: 18, lineHeight: 28 }} numberOfLines={6}>
          {item.text}
        </Text>
        <View style={{ gap: 6 }}>
          <SectionLabel>Why it matters</SectionLabel>
          <Text numberOfLines={3} style={{ color: colors.text, fontFamily: fonts.sans, fontSize: 15, lineHeight: 22 }}>
            {item.deeper.context}
          </Text>
        </View>
        <DidYouKnow text={item.deeper.didYouKnow} lines={3} />
        <RelatedChips ids={item.deeper.related} onPress={onRelated} />
        <View style={{ marginTop: 'auto', gap: 14 }}>
          <Pressable onPress={onOpen} accessibilityRole="button" accessibilityLabel="Go deeper">
            <Text style={{ color: colors.accent, fontFamily: fonts.sansSemibold, fontSize: 16 }}>Go deeper ›</Text>
          </Pressable>
          <SpeechBadge item={item} />
          <View style={{ flexDirection: 'row', justifyContent: 'space-around', alignItems: 'center' }}>
            <IconHit label={saved ? 'Remove save' : 'Save'} onPress={onSave}>
              <Ionicons name={saved ? 'bookmark' : 'bookmark-outline'} size={26} color={saved ? colors.accent : colors.textMuted} />
            </IconHit>
            <IconHit label="Share" onPress={onShare}>
              <Ionicons name="share-outline" size={26} color={colors.textMuted} />
            </IconHit>
            <IconHit label={done ? 'Mark as not done' : 'Mark as done'} onPress={onDone}>
              <Ionicons
                name={done ? 'checkmark-circle' : 'checkmark-circle-outline'}
                size={26}
                color={done ? colors.accent : colors.textMuted}
              />
            </IconHit>
          </View>
        </View>
        </View>
      </View>
    </View>
    </RiseIn>
  );
}
