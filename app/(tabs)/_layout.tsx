import { Tabs } from 'expo-router';

import { FloatingTabBar } from '@/components/FloatingTabBar';
import { useAppTheme } from '@/theme/useAppTheme';

export default function TabLayout() {
  const { colors } = useAppTheme();
  return (
    <Tabs
      tabBar={(props) => <FloatingTabBar {...props} />}
      screenOptions={{
        headerShown: false,
        lazy: true,
        sceneStyle: { backgroundColor: colors.bg },
      }}>
      <Tabs.Screen name="collections" options={{ title: 'Collections' }} />
      <Tabs.Screen name="discover" options={{ title: 'Discover' }} />
      <Tabs.Screen name="index" options={{ title: 'Home' }} />
      <Tabs.Screen name="feed" options={{ title: 'Feed' }} />
    </Tabs>
  );
}
