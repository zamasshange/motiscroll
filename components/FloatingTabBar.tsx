import { Ionicons } from '@expo/vector-icons';
import { BlurView } from 'expo-blur';
import type { BottomTabBarProps } from 'expo-router/tabs';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { useAppTheme } from '@/theme/useAppTheme';
import { layout } from '@/theme/tokens';

const ICONS: Record<string, keyof typeof Ionicons.glyphMap> = {
  collections: 'grid-outline',
  discover: 'compass-outline',
  index: 'home',
  feed: 'book-outline',
};

export function FloatingTabBar({ state, descriptors, emitter, navigateToTab }: BottomTabBarProps) {
  const { colors, fonts, radii, mode } = useAppTheme();
  const insets = useSafeAreaInsets();

  return (
    <View
      style={{
        position: 'absolute',
        left: 16,
        right: 16,
        bottom: Math.max(insets.bottom, 8) + layout.tabBarFloat,
        height: layout.tabBarHeight,
        borderRadius: radii.pill,
        borderWidth: 1,
        borderColor: colors.border,
        overflow: 'hidden',
      }}>
      <BlurView intensity={36} tint={mode === 'dark' ? 'dark' : 'light'} style={StyleSheet.absoluteFill} />
      <View
        pointerEvents="none"
        style={[
          StyleSheet.absoluteFill,
          { backgroundColor: mode === 'dark' ? 'rgba(18,18,22,0.62)' : 'rgba(255,252,248,0.72)' },
        ]}
      />
      <View style={{ flex: 1, flexDirection: 'row', alignItems: 'center', paddingHorizontal: 6 }}>
        {state.routes.map((route, index) => {
          const focused = state.index === index;
          const options = descriptors[route.key]?.options;
          const title = options?.title ?? route.name;
          const onPress = () => {
            const event = emitter.emit({
              type: 'tabPress',
              target: route.key,
              canPreventDefault: true,
            });
            if (!focused && !event.defaultPrevented) navigateToTab(route.key);
          };
          return (
            <Pressable
              key={route.key}
              onPress={onPress}
              accessibilityRole="tab"
              accessibilityState={{ selected: focused }}
              accessibilityLabel={String(title)}
              style={({ pressed }) => ({
                flex: 1,
                alignItems: 'center',
                justifyContent: 'center',
                opacity: pressed ? 0.7 : 1,
              })}>
              <View
                style={{
                  alignItems: 'center',
                  justifyContent: 'center',
                  paddingHorizontal: 8,
                  paddingVertical: 6,
                  borderRadius: radii.pill,
                  backgroundColor: focused ? colors.accentSoft : 'transparent',
                  minWidth: 64,
                }}>
                <Ionicons
                  name={ICONS[route.name] ?? 'ellipse-outline'}
                  size={20}
                  color={focused ? colors.accent : colors.textMuted}
                />
                <Text
                  numberOfLines={1}
                  style={{
                    marginTop: 2,
                    fontFamily: fonts.sansMedium,
                    fontSize: 11,
                    color: focused ? colors.accent : colors.textMuted,
                  }}>
                  {title}
                </Text>
              </View>
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}