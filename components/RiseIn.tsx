import { useEffect, type ReactNode } from 'react';
import Animated, { useAnimatedStyle, useSharedValue, withTiming } from 'react-native-reanimated';

import { useReduceMotion } from '@/utils/motion';

export function RiseIn({ active, children }: { active: boolean; children: ReactNode }) {
  const reduce = useReduceMotion();
  const opacity = useSharedValue(1);
  const translateY = useSharedValue(0);
  const style = useAnimatedStyle(() => ({
    flex: 1,
    opacity: opacity.value,
    transform: [{ translateY: translateY.value }],
  }));

  useEffect(() => {
    if (!active) return;
    if (reduce) {
      opacity.value = 1;
      translateY.value = 0;
      return;
    }
    opacity.value = 0;
    translateY.value = 8;
    opacity.value = withTiming(1, { duration: 250 });
    translateY.value = withTiming(0, { duration: 250 });
  }, [active, opacity, reduce, translateY]);

  return <Animated.View style={style}>{children}</Animated.View>;
}
