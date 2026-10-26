import { Ionicons } from '@expo/vector-icons';
import { useCallback } from 'react';
import { Pressable } from 'react-native';
import Animated, { useAnimatedStyle, useSharedValue, withSequence, withSpring } from 'react-native-reanimated';

import { useAppTheme } from '@/theme/useAppTheme';
import { lightTap } from '@/utils/haptics';

export function HeartButton({ active, onPress }: { active: boolean; onPress: () => void }) {
  const { colors } = useAppTheme();
  const scale = useSharedValue(1);
  const style = useAnimatedStyle(() => ({ transform: [{ scale: scale.value }] }));

  const handlePress = useCallback(() => {
    scale.value = withSequence(withSpring(1.35, { damping: 8, stiffness: 320 }), withSpring(1));
    lightTap();
    onPress();
  }, [onPress, scale]);

  return (
    <Pressable
      onPress={handlePress}
      accessibilityRole="button"
      accessibilityLabel={active ? 'Unlike' : 'Like'}
      hitSlop={10}
      style={{ minWidth: 44, minHeight: 44, alignItems: 'center', justifyContent: 'center' }}>
      <Animated.View style={style}>
        <Ionicons name={active ? 'heart' : 'heart-outline'} size={26} color={active ? colors.accent : colors.text} />
      </Animated.View>
    </Pressable>
  );
}
