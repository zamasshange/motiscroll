export const APP_NAME = 'APP NAME';

export const spacing = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
  xxl: 32,
  xxxl: 48,
} as const;

export const radii = {
  card: 24,
  sheet: 28,
  pill: 999,
  control: 16,
  image: 20,
} as const;

export const fonts = {
  serif: 'PlayfairDisplay_600SemiBold',
  serifBold: 'PlayfairDisplay_700Bold',
  serifItalic: 'PlayfairDisplay_500Medium_Italic',
  sans: 'DMSans_400Regular',
  sansMedium: 'DMSans_500Medium',
  sansSemibold: 'DMSans_600SemiBold',
  sansBold: 'DMSans_700Bold',
} as const;

export const layout = {
  tabBarHeight: 62,
  tabBarFloat: 10,
  feedBaseFontSize: 30,
} as const;

export type Palette = {
  bg: string;
  card: string;
  cardAlt: string;
  border: string;
  text: string;
  textMuted: string;
  textFaint: string;
  accent: string;
  accentSoft: string;
  danger: string;
  tabBar: string;
  sheet: string;
  backdrop: string;
  shadow: string;
};

export const palettes: Record<'dark' | 'light', Palette> = {
  dark: {
    bg: '#0B0B0D',
    card: '#16161A',
    cardAlt: '#1E1E24',
    border: 'rgba(255,255,255,0.08)',
    text: '#F4F1EA',
    textMuted: '#A8A197',
    textFaint: '#726C64',
    accent: '#E07A4A',
    accentSoft: 'rgba(224,122,74,0.16)',
    danger: '#E15D5D',
    tabBar: 'rgba(18,18,22,0.88)',
    sheet: '#141418',
    backdrop: 'rgba(0,0,0,0.58)',
    shadow: 'rgba(0,0,0,0.35)',
  },
  light: {
    bg: '#F6F3EE',
    card: '#FFFFFF',
    cardAlt: '#F3EEE6',
    border: 'rgba(28,22,16,0.08)',
    text: '#1C1916',
    textMuted: '#6B645C',
    textFaint: '#9A9288',
    accent: '#C4622D',
    accentSoft: 'rgba(196,98,45,0.12)',
    danger: '#C43B3B',
    tabBar: 'rgba(255,252,248,0.92)',
    sheet: '#FFFCF8',
    backdrop: 'rgba(28,22,16,0.35)',
    shadow: 'rgba(28,22,16,0.08)',
  },
};
