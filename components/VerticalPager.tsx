import { useCallback, useEffect, useMemo, useRef, type ReactNode } from 'react';
import { View, useWindowDimensions } from 'react-native';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import Animated, { runOnJS, useAnimatedStyle, useSharedValue, withSpring } from 'react-native-reanimated';

import { SNAP_SPRING } from '@/utils/motion';

type Props<T extends { id: string }> = {
  items: T[];
  index: number;
  enabled?: boolean;
  onIndexChange: (index: number) => void;
  onSwipePastEnd?: () => void;
  renderItem: (item: T, index: number) => ReactNode;
};

export function VerticalPager<T extends { id: string }>({
  items,
  index,
  enabled = true,
  onIndexChange,
  onSwipePastEnd,
  renderItem,
}: Props<T>) {
  const { height, width } = useWindowDimensions();
  const translateY = useSharedValue(-index * height);
  const indexSv = useSharedValue(index);
  const heightSv = useSharedValue(height);
  const countSv = useSharedValue(items.length);
  const enabledSv = useSharedValue(enabled);
  const pastEndSv = useSharedValue(onSwipePastEnd ? 1 : 0);
  const heightRef = useRef(height);

  const onIndexChangeRef = useRef(onIndexChange);
  onIndexChangeRef.current = onIndexChange;
  const onPastEndRef = useRef(onSwipePastEnd);
  onPastEndRef.current = onSwipePastEnd;

  const commit = useCallback((next: number) => {
    onIndexChangeRef.current(next);
  }, []);

  const firePastEnd = useCallback(() => {
    onPastEndRef.current?.();
  }, []);

  useEffect(() => {
    heightSv.value = height;
    countSv.value = items.length;
    enabledSv.value = enabled;
    pastEndSv.value = onSwipePastEnd ? 1 : 0;
    const heightChanged = heightRef.current !== height;
    heightRef.current = height;
    if (indexSv.value !== index) {
      indexSv.value = index;
      translateY.value = withSpring(-index * height, SNAP_SPRING);
    } else if (heightChanged) {
      translateY.value = -index * height;
    }
  }, [
    countSv,
    enabled,
    enabledSv,
    height,
    heightSv,
    index,
    indexSv,
    items.length,
    onSwipePastEnd,
    pastEndSv,
    translateY,
  ]);

  const pan = useMemo(() => {
    return Gesture.Pan()
      .activeOffsetY([-12, 12])
      .onUpdate((event) => {
        if (!enabledSv.value) return;
        const pageHeight = heightSv.value;
        const current = indexSv.value;
        const count = Math.max(countSv.value, 1);
        const min = -(count - 1) * pageHeight;
        const raw = -current * pageHeight + event.translationY;
        if (raw > 0) translateY.value = raw * 0.32;
        else if (raw < min) translateY.value = min + (raw - min) * 0.32;
        else translateY.value = raw;
      })
      .onEnd((event) => {
        const pageHeight = heightSv.value;
        const current = indexSv.value;
        const count = countSv.value;
        if (!enabledSv.value || count === 0) {
          translateY.value = withSpring(-current * pageHeight, SNAP_SPRING);
          return;
        }
        const forward = event.translationY < -pageHeight * 0.16 || event.velocityY < -900;
        const backward = event.translationY > pageHeight * 0.16 || event.velocityY > 900;
        let next = current;
        if (forward) next = current + 1;
        else if (backward) next = current - 1;

        if (next >= count) {
          if (pastEndSv.value === 1 && forward) {
            indexSv.value = 0;
            translateY.value = 0;
            runOnJS(firePastEnd)();
            return;
          }
          next = count - 1;
        }
        if (next < 0) next = 0;

        if (next !== current) {
          indexSv.value = next;
          translateY.value = withSpring(-next * pageHeight, SNAP_SPRING);
          runOnJS(commit)(next);
        } else {
          translateY.value = withSpring(-current * pageHeight, SNAP_SPRING);
        }
      });
  }, [commit, countSv, enabledSv, firePastEnd, heightSv, indexSv, pastEndSv, translateY]);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ translateY: translateY.value }],
  }));

  return (
    <View style={{ height, width, overflow: 'hidden' }}>
      <GestureDetector gesture={pan}>
        <Animated.View style={[{ width }, animatedStyle]}>
          {items.map((item, itemIndex) => (
            <View key={item.id} style={{ height, width }}>
              {renderItem(item, itemIndex)}
            </View>
          ))}
        </Animated.View>
      </GestureDetector>
    </View>
  );
}
