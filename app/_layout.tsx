import 'react-native-gesture-handler';

import { DMSans_400Regular, DMSans_500Medium, DMSans_600SemiBold, DMSans_700Bold } from '@expo-google-fonts/dm-sans';
import {
  PlayfairDisplay_500Medium_Italic,
  PlayfairDisplay_600SemiBold,
  PlayfairDisplay_700Bold,
} from '@expo-google-fonts/playfair-display';
import { Ionicons } from '@expo/vector-icons';
import { DarkTheme, DefaultTheme, Redirect, ThemeProvider, useSegments } from 'expo-router';
import { useFonts } from 'expo-font';
import { Stack, type Href } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import { StatusBar } from 'expo-status-bar';
import { useEffect } from 'react';
import { View } from 'react-native';
import { GestureHandlerRootView } from 'react-native-gesture-handler';

import { useEnsureDiscoverQueue, useStore } from '@/store/useStore';
import { useAppTheme } from '@/theme/useAppTheme';

export { ErrorBoundary } from 'expo-router';

SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const [loaded, error] = useFonts({
    ...Ionicons.font,
    PlayfairDisplay_500Medium_Italic,
    PlayfairDisplay_600SemiBold,
    PlayfairDisplay_700Bold,
    DMSans_400Regular,
    DMSans_500Medium,
    DMSans_600SemiBold,
    DMSans_700Bold,
  });
  const hydrated = useStore((state) => state.hydrated);

  useEffect(() => {
    if (error) throw error;
  }, [error]);

  useEffect(() => {
    const timer = setTimeout(() => {
      if (!useStore.getState().hydrated) useStore.setState({ hydrated: true });
    }, 1500);
    return () => clearTimeout(timer);
  }, []);

  useEffect(() => {
    if (loaded && hydrated) SplashScreen.hideAsync();
  }, [hydrated, loaded]);

  if (!loaded || !hydrated) return null;

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <RootNavigator />
    </GestureHandlerRootView>
  );
}

function RootNavigator() {
  const { colors, mode } = useAppTheme();
  const onboardingComplete = useStore((state) => state.onboardingComplete);
  const segments = useSegments();
  useEnsureDiscoverQueue();
  const atOnboarding = segments[0] === 'onboarding';
  const base = mode === 'dark' ? DarkTheme : DefaultTheme;
  const navigationTheme = {
    ...base,
    colors: {
      ...base.colors,
      background: colors.bg,
      card: colors.bg,
      text: colors.text,
      border: colors.border,
      primary: colors.accent,
    },
  };

  return (
    <ThemeProvider value={navigationTheme}>
      <StatusBar style={mode === 'dark' ? 'light' : 'dark'} />
      <View style={{ flex: 1, backgroundColor: colors.bg }}>
        {!onboardingComplete && !atOnboarding ? <Redirect href={'/onboarding' as Href} /> : null}
        <Stack screenOptions={{ headerShown: false, contentStyle: { backgroundColor: colors.bg } }}>
          <Stack.Screen name="(tabs)" />
          <Stack.Screen name="onboarding" />
          <Stack.Screen name="saved" />
          <Stack.Screen name="settings" />
        </Stack>
      </View>
    </ThemeProvider>
  );
}
