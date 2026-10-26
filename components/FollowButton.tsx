import { Ionicons } from '@expo/vector-icons';
import { useEffect, useRef } from 'react';
import { Pressable, Text } from 'react-native';
import Animated, { useAnimatedStyle, useSharedValue, withSequence, withSpring } from 'react-native-reanimated';

import { useAppTheme } from '@/theme/useAppTheme';
import { lightTap } from '@/utils/haptics';
import { useReduceMotion } from '@/utils/motion';

export function FollowButton({ following, onPress }: { following: boolean; onPress: () => void }) {
  const { colors, fonts, radii } = useAppTheme();
  const reduce = useReduceMotion();
  const scale = useSharedValue(1);
  const ready = useRef(false);
  const style = useAnimatedStyle(() => ({ transform: [{ scale: scale.value }] }));

  useEffect(() => {
    if (!ready.current) {
      ready.current = true;
      return;
    }
    if (reduce) return;
    scale.value = withSequence(withSpring(1.06, { damping: 10, stiffness: 280 }), withSpring(1));
  }, [following, reduce, scale]);

  return (
    <Pressable
      onPress={() => {
        lightTap();
        onPress();
      }}
      accessibilityRole="button"
      accessibilityState={{ selected: following }}
      accessibilityLabel={following ? 'Unfollow' : 'Follow'}
      style={({ pressed }) => ({
        alignSelf: 'flex-start',
        opacity: pressed ? 0.84 : 1,
      })}>
      <Animated.View
        style={[
          {
            flexDirection: 'row',
            alignItems: 'center',
            gap: 6,
            borderRadius: radii.pill,
            paddingHorizontal: 16,
            paddingVertical: 10,
            backgroundColor: following ? colors.accent : 'transparent',
            borderWidth: 1,
            borderColor: following ? colors.accent : colors.border,
          },
          style,
        ]}>
        {following ? <Ionicons name="checkmark" size={16} color="#1A0E08" /> : null}
        <Text style={{ color: following ? '#1A0E08' : colors.text, fontFamily: fonts.sansSemibold, fontSize: 15 }}>
          {following ? 'Following' : 'Follow'}
        </Text>
      </Animated.View>
    </Pressable>
  );
}
