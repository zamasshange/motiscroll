import { useColorScheme } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { useStore, type ThemePreference } from '@/store/useStore';
import { fonts, layout, palettes, radii, spacing, type Palette } from '@/theme/tokens';

export function useAppTheme() {
  const preference = useStore((state) => state.themePreference);
  const system = useColorScheme();
  const mode = resolveMode(preference, system);

  return {
    mode,
    colors: palettes[mode],
    fonts,
    spacing,
    radii,
    layout,
  };
}

export function useDockInset() {
  const insets = useSafeAreaInsets();
  return insets.bottom + layout.tabBarHeight + layout.tabBarFloat + 36;
}

function resolveMode(
  preference: ThemePreference,
  system: 'light' | 'dark' | null | undefined,
): keyof typeof palettes {
  if (preference === 'system') return system === 'light' ? 'light' : 'dark';
  return preference;
}

export type AppColors = Palette;
