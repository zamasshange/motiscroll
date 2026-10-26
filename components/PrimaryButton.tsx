import type { ReactNode } from 'react';
import { Pressable, Text, type PressableProps, type StyleProp, type ViewStyle } from 'react-native';
import Animated, { useAnimatedStyle, useSharedValue, withSequence, withSpring } from 'react-native-reanimated';

import { useAppTheme } from '@/theme/useAppTheme';

export function PrimaryButton({
  label,
  onPress,
  style,
}: {
  label: string;
  onPress: () => void;
  style?: StyleProp<ViewStyle>;
}) {
  const { colors, fonts, radii } = useAppTheme();
  return (
    <Pressable
      onPress={onPress}
      accessibilityRole="button"
      style={({ pressed }) => [
        {
          backgroundColor: colors.text,
          borderRadius: radii.pill,
          paddingVertical: 16,
          alignItems: 'center',
          opacity: pressed ? 0.86 : 1,
        },
        style,
      ]}>
      <Text style={{ color: colors.bg, fontFamily: fonts.sansSemibold, fontSize: 16 }}>{label}</Text>
    </Pressable>
  );
}

export function IconHit({
  onPress,
  label,
  children,
  hitSlop = 10,
}: {
  onPress: () => void;
  label: string;
  children: ReactNode;
  hitSlop?: PressableProps['hitSlop'];
}) {
  const scale = useSharedValue(1);
  const style = useAnimatedStyle(() => ({ transform: [{ scale: scale.value }] }));
  return (
    <Pressable
      onPress={() => {
        scale.value = withSequence(withSpring(1.22, { damping: 8, stiffness: 320 }), withSpring(1));
        onPress();
      }}
      accessibilityRole="button"
      accessibilityLabel={label}
      hitSlop={hitSlop}
      style={({ pressed }) => ({
        opacity: pressed ? 0.7 : 1,
        minWidth: 44,
        minHeight: 44,
        alignItems: 'center',
        justifyContent: 'center',
      })}>
      <Animated.View style={style}>{children}</Animated.View>
    </Pressable>
  );
}
