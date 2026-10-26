import { Ionicons } from '@expo/vector-icons';
import { Modal, Pressable, ScrollView, Text, View, useWindowDimensions } from 'react-native';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import { runOnJS } from 'react-native-reanimated';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { AuthorAvatar } from '@/components/AuthorAvatar';
import { DidYouKnow } from '@/components/DidYouKnow';
import { RelatedChips } from '@/components/RelatedChips';
import { SectionLabel } from '@/components/SectionLabel';
import { SpeechBadge } from '@/components/SpeechBadge';
import { UnverifiedNote } from '@/components/UnverifiedNote';
import type { Item } from '@/data/items';
import { useAppTheme } from '@/theme/useAppTheme';
import { sourceLine } from '@/utils/format';
import { openExternal } from '@/utils/openExternal';

export function GoDeeperSheet({
  item,
  onClose,
  onOpenRelated,
}: {
  item: Item | null;
  onClose: () => void;
  onOpenRelated: (id: string) => void;
}) {
  const { colors, fonts, radii } = useAppTheme();
  const insets = useSafeAreaInsets();
  const { height } = useWindowDimensions();
  const pan = Gesture.Pan().onEnd((event) => {
    if (event.translationY > 90 || event.velocityY > 900) runOnJS(onClose)();
  });

  return (
    <Modal visible={item != null} transparent animationType="slide" onRequestClose={onClose}>
      {item ? (
        <View style={{ flex: 1, justifyContent: 'flex-end', backgroundColor: colors.backdrop }}>
          <Pressable style={{ flex: 1 }} onPress={onClose} accessibilityLabel="Close" />
          <View
            style={{
              maxHeight: height * 0.86,
              backgroundColor: colors.sheet,
              borderTopLeftRadius: radii.sheet,
              borderTopRightRadius: radii.sheet,
              borderWidth: 1,
              borderColor: colors.border,
              paddingBottom: Math.max(insets.bottom, 16),
            }}>
            <GestureDetector gesture={pan}>
              <View style={{ alignItems: 'center', paddingTop: 10, paddingBottom: 8 }}>
                <View style={{ width: 42, height: 4, borderRadius: 4, backgroundColor: colors.border }} />
              </View>
            </GestureDetector>
            <ScrollView contentContainerStyle={{ paddingHorizontal: 22, paddingBottom: 24, gap: 16 }}>
              <View style={{ flexDirection: 'row', justifyContent: 'space-between', gap: 12 }}>
                <AuthorAvatar
                  author={item.author}
                  imageUrl={item.imageUrl}
                  credit={item.imageCredit}
                  field={item.field}
                  size={52}
                  showCredit
                />
                <View style={{ flex: 1, gap: 6 }}>
                  <Text style={{ color: colors.text, fontFamily: fonts.serif, fontSize: 28 }}>{item.author}</Text>
                  <Text style={{ color: colors.textMuted, fontFamily: fonts.sans, fontSize: 14 }}>
                    {sourceLine(item)}
                  </Text>
                  {item.verified ? null : <UnverifiedNote />}
                </View>
                <Pressable onPress={onClose} accessibilityRole="button" accessibilityLabel="Close" hitSlop={8}>
                  <Ionicons name="close" size={24} color={colors.text} />
                </Pressable>
              </View>
              <Text style={{ color: colors.text, fontFamily: fonts.serifItalic, fontSize: 18, lineHeight: 28 }}>
                {item.text}
              </Text>
              <View style={{ gap: 8 }}>
                <SectionLabel>The moment</SectionLabel>
                <Text style={{ color: colors.text, fontFamily: fonts.sans, fontSize: 16, lineHeight: 24 }}>
                  {item.deeper.context}
                </Text>
              </View>
              <DidYouKnow text={item.deeper.didYouKnow} />
              <View
                style={{
                  backgroundColor: colors.accentSoft,
                  borderRadius: radii.control,
                  padding: 14,
                  gap: 6,
                }}>
                <SectionLabel>Apply it today</SectionLabel>
                <Text style={{ color: colors.text, fontFamily: fonts.sansMedium, fontSize: 16, lineHeight: 24 }}>
                  {item.deeper.takeaway}
                </Text>
              </View>
              <View style={{ gap: 8 }}>
                <SectionLabel>Related</SectionLabel>
                <RelatedChips
                  ids={item.deeper.related}
                  onPress={(id) => {
                    onOpenRelated(id);
                    onClose();
                  }}
                />
              </View>
              {item.speech ? <SpeechBadge item={item} /> : null}
              {item.source.url && !item.speech ? (
                <Pressable onPress={() => openExternal(item.source.url!)} accessibilityRole="link">
                  <Text style={{ color: colors.accent, fontFamily: fonts.sansSemibold, fontSize: 15 }}>
                    Open source
                  </Text>
                </Pressable>
              ) : null}
            </ScrollView>
          </View>
        </View>
      ) : null}
    </Modal>
  );
}
