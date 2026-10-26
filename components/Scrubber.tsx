import { useCallback, useEffect, useMemo } from 'react';
import { View } from 'react-native';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import { runOnJS, useSharedValue } from 'react-native-reanimated';

import { useAppTheme } from '@/theme/useAppTheme';

const TRACK = 220;

export function Scrubber({
  count,
  index,
  onChange,
}: {
  count: number;
  index: number;
  onChange: (index: number) => void;
}) {
  const { colors } = useAppTheme();
  const last = useSharedValue(index);
  const onChangeRef = useCallback(onChange, [onChange]);

  useEffect(() => {
    last.value = index;
  }, [index, last]);

  const apply = useCallback(
    (next: number) => {
      onChangeRef(next);
    },
    [onChangeRef],
  );

  const gesture = useMemo(() => {
    const jump = (y: number) => {
      'worklet';
      const ratio = Math.min(1, Math.max(0, y / TRACK));
      const next = Math.round(ratio * Math.max(count - 1, 0));
      if (next !== last.value) {
        last.value = next;
        runOnJS(apply)(next);
      }
    };
    return Gesture.Pan()
      .onBegin((event) => jump(event.y))
      .onUpdate((event) => jump(event.y));
  }, [apply, count, last]);

  if (count <= 1) return null;
  const progress = index / (count - 1);
  const thumbOffset = progress * (TRACK - 18);

  return (
    <GestureDetector gesture={gesture}>
      <View
        accessibilityLabel="Drag to jump through the list"
        style={{ width: 36, height: TRACK, justifyContent: 'center', alignItems: 'center' }}>
        <View
          style={{
            position: 'absolute',
            width: 2,
            top: 8,
            bottom: 8,
            borderRadius: 2,
            backgroundColor: colors.border,
          }}
        />
        <View
          style={{
            position: 'absolute',
            top: thumbOffset,
            width: 14,
            height: 18,
            borderRadius: 7,
            backgroundColor: colors.text,
          }}
        />
      </View>
    </GestureDetector>
  );
}
