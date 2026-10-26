import { useRouter, type Href } from 'expo-router';
import { useState } from 'react';
import { Alert, Pressable, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { BackHeader } from '@/components/BackHeader';
import { useStore, type ThemePreference } from '@/store/useStore';
import { useAppTheme } from '@/theme/useAppTheme';
import { APP_NAME, layout } from '@/theme/tokens';
import { clamp } from '@/utils/number';

const THEMES: { id: ThemePreference; label: string }[] = [
  { id: 'dark', label: 'Dark' },
  { id: 'light', label: 'Light' },
  { id: 'system', label: 'System' },
];

export default function SettingsScreen() {
  const { colors, fonts, radii } = useAppTheme();
  const insets = useSafeAreaInsets();
  const themePreference = useStore((state) => state.themePreference);
  const fontScale = useStore((state) => state.fontScale);
  const setThemePreference = useStore((state) => state.setThemePreference);
  const setFontScale = useStore((state) => state.setFontScale);
  const resetProgress = useStore((state) => state.resetProgress);
  const replayOnboarding = useStore((state) => state.replayOnboarding);
  const router = useRouter();
  const preview = layout.feedBaseFontSize * fontScale;

  return (
    <View style={{ flex: 1, backgroundColor: colors.bg, paddingTop: insets.top + 8, paddingHorizontal: 20, gap: 28 }}>
      <BackHeader title="Settings" />
      <Text style={{ color: colors.textFaint, fontFamily: fonts.sans, fontSize: 13 }}>{APP_NAME}</Text>

      <View style={{ gap: 10 }}>
        <Text style={{ color: colors.text, fontFamily: fonts.sansSemibold, fontSize: 16 }}>Appearance</Text>
        <View style={{ flexDirection: 'row', gap: 8 }}>
          {THEMES.map((theme) => {
            const active = themePreference === theme.id;
            return (
              <Pressable
                key={theme.id}
                onPress={() => setThemePreference(theme.id)}
                accessibilityRole="button"
                accessibilityState={{ selected: active }}
                style={{
                  flex: 1,
                  alignItems: 'center',
                  paddingVertical: 12,
                  borderRadius: radii.pill,
                  backgroundColor: active ? colors.text : colors.card,
                  borderWidth: 1,
                  borderColor: active ? colors.text : colors.border,
                }}>
                <Text style={{ color: active ? colors.bg : colors.text, fontFamily: fonts.sansSemibold, fontSize: 14 }}>
                  {theme.label}
                </Text>
              </Pressable>
            );
          })}
        </View>
      </View>

      <View style={{ gap: 12 }}>
        <View style={{ flexDirection: 'row', justifyContent: 'space-between' }}>
          <Text style={{ color: colors.text, fontFamily: fonts.sansSemibold, fontSize: 16 }}>Feed text size</Text>
          <Text style={{ color: colors.textMuted, fontFamily: fonts.sans, fontSize: 14 }}>{Math.round(fontScale * 100)}%</Text>
        </View>
        <FontSlider value={fontScale} onChange={setFontScale} />
        <Text
          style={{
            color: colors.text,
            fontFamily: fonts.serifItalic,
            fontSize: preview,
            lineHeight: preview * 1.3,
          }}>
          The quick line sits like this.
        </Text>
      </View>

      <Pressable
        onPress={() => {
          replayOnboarding();
          router.replace('/onboarding' as Href);
        }}
        accessibilityRole="button"
        style={{
          borderRadius: radii.pill,
          borderWidth: 1,
          borderColor: colors.border,
          paddingVertical: 14,
          alignItems: 'center',
        }}>
        <Text style={{ color: colors.text, fontFamily: fonts.sansSemibold, fontSize: 16 }}>Replay onboarding</Text>
      </Pressable>

      <Pressable
        onPress={() =>
          Alert.alert('Reset progress?', 'This clears your streak, saves, likes, follows, and the first-run hint.', [
            { text: 'Cancel', style: 'cancel' },
            { text: 'Reset', style: 'destructive', onPress: resetProgress },
          ])
        }
        accessibilityRole="button"
        style={{
          borderRadius: radii.pill,
          borderWidth: 1,
          borderColor: colors.danger,
          paddingVertical: 14,
          alignItems: 'center',
        }}>
        <Text style={{ color: colors.danger, fontFamily: fonts.sansSemibold, fontSize: 16 }}>Reset progress</Text>
      </Pressable>
    </View>
  );
}

function FontSlider({ value, onChange }: { value: number; onChange: (value: number) => void }) {
  const { colors } = useAppTheme();
  const [width, setWidth] = useState(1);
  const min = 0.85;
  const max = 1.45;
  const ratio = (value - min) / (max - min);

  const update = (x: number) => {
    const next = min + clamp(x / width, 0, 1) * (max - min);
    onChange(Math.round(next * 20) / 20);
  };

  return (
    <View
      onLayout={(event) => setWidth(event.nativeEvent.layout.width)}
      onStartShouldSetResponder={() => true}
      onMoveShouldSetResponder={() => true}
      onResponderGrant={(event) => update(event.nativeEvent.locationX)}
      onResponderMove={(event) => update(event.nativeEvent.locationX)}
      accessibilityRole="adjustable"
      accessibilityLabel="Feed text size"
      style={{ height: 36, justifyContent: 'center' }}>
      <View style={{ height: 4, borderRadius: 4, backgroundColor: colors.border }} />
      <View
        style={{
          position: 'absolute',
          left: 0,
          width: Math.max(8, ratio * width),
          height: 4,
          borderRadius: 4,
          backgroundColor: colors.accent,
        }}
      />
      <View
        style={{
          position: 'absolute',
          left: Math.max(0, ratio * width - 12),
          width: 24,
          height: 24,
          borderRadius: 12,
          backgroundColor: colors.text,
        }}
      />
    </View>
  );
}
