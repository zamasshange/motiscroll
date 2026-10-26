import { Ionicons } from '@expo/vector-icons';
import { Pressable, Text, View } from 'react-native';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import Animated, { runOnJS, useAnimatedStyle, useSharedValue, withSpring, withTiming } from 'react-native-reanimated';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { AuthorAvatar } from '@/components/AuthorAvatar';
import { BackHeader } from '@/components/BackHeader';
import { itemById } from '@/data/items';
import { useStore } from '@/store/useStore';
import { useAppTheme } from '@/theme/useAppTheme';
import { sourceLine } from '@/utils/format';
import { openFeed } from '@/utils/nav';

export default function SavedScreen() {
  const { colors, fonts } = useAppTheme();
  const insets = useSafeAreaInsets();
  const savedIds = useStore((state) => state.savedIds);
  const removeSave = useStore((state) => state.removeSave);
  const items = savedIds.map((id) => itemById(id)).filter((item) => item != null);

  return (
    <View style={{ flex: 1, backgroundColor: colors.bg, paddingTop: insets.top + 8 }}>
      <View style={{ paddingHorizontal: 12 }}>
        <BackHeader title="Saved" />
      </View>
      {items.length === 0 ? (
        <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', padding: 32, gap: 12 }}>
          <Text style={{ color: colors.text, fontFamily: fonts.serif, fontSize: 28, textAlign: 'center' }}>
            Nothing saved yet.
          </Text>
          <Pressable onPress={() => openFeed({})} accessibilityRole="button">
            <Text style={{ color: colors.accent, fontFamily: fonts.sansSemibold, fontSize: 16 }}>Browse the feed</Text>
          </Pressable>
        </View>
      ) : (
        <View style={{ paddingTop: 12 }}>
          {items.map((item) => (
            <SavedRow key={item.id} item={item} onOpen={() => openFeed({ itemId: item.id })} onRemove={() => removeSave(item.id)} />
          ))}
        </View>
      )}
    </View>
  );
}

function SavedRow({
  item,
  onOpen,
  onRemove,
}: {
  item: NonNullable<ReturnType<typeof itemById>>;
  onOpen: () => void;
  onRemove: () => void;
}) {
  const { colors, fonts, radii } = useAppTheme();
  const translateX = useSharedValue(0);
  const style = useAnimatedStyle(() => ({ transform: [{ translateX: translateX.value }] }));
  const pan = Gesture.Pan()
    .activeOffsetX([-12, 12])
    .failOffsetY([-16, 16])
    .onUpdate((event) => {
      translateX.value = Math.min(0, event.translationX);
    })
    .onEnd(() => {
      if (translateX.value < -96) {
        translateX.value = withTiming(-420, { duration: 180 }, (finished) => {
          if (finished) runOnJS(onRemove)();
        });
      } else {
        translateX.value = withSpring(0);
      }
    });

  return (
    <View key={item.id} style={{ marginHorizontal: 20, marginBottom: 12 }}>
      <View
        style={{
          position: 'absolute',
          top: 0,
          right: 0,
          bottom: 0,
          width: 96,
          borderRadius: radii.control,
          backgroundColor: colors.danger,
          alignItems: 'center',
          justifyContent: 'center',
        }}>
        <Ionicons name="trash-outline" size={20} color="#fff" />
      </View>
      <GestureDetector gesture={pan}>
        <Animated.View style={style}>
          <Pressable
            onPress={onOpen}
            accessibilityRole="button"
            accessibilityLabel={`Open ${item.author}`}
            style={{
              backgroundColor: colors.card,
              borderRadius: radii.control,
              borderWidth: 1,
              borderColor: colors.border,
              padding: 16,
              gap: 8,
              flexDirection: 'row',
            }}>
            <AuthorAvatar author={item.author} imageUrl={item.imageUrl} credit={item.imageCredit} field={item.field} size={40} />
            <View style={{ flex: 1, gap: 4 }}>
              <Text style={{ color: colors.text, fontFamily: fonts.sansSemibold, fontSize: 16 }}>{item.author}</Text>
              <Text style={{ color: colors.textFaint, fontFamily: fonts.sans, fontSize: 12 }}>{sourceLine(item)}</Text>
              <Text numberOfLines={2} style={{ color: colors.textMuted, fontFamily: fonts.serifItalic, fontSize: 15, lineHeight: 22 }}>
                {item.text}
              </Text>
            </View>
          </Pressable>
        </Animated.View>
      </GestureDetector>
    </View>
  );
}
