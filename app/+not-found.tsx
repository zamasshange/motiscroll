import { Link, Stack } from 'expo-router';
import { Text, View } from 'react-native';

import { useAppTheme } from '@/theme/useAppTheme';

export default function NotFoundScreen() {
  const { colors, fonts } = useAppTheme();
  return (
    <>
      <Stack.Screen options={{ title: 'Not found', headerShown: false }} />
      <View style={{ flex: 1, backgroundColor: colors.bg, alignItems: 'center', justifyContent: 'center', padding: 24, gap: 12 }}>
        <Text style={{ color: colors.text, fontFamily: fonts.serif, fontSize: 28 }}>This screen does not exist.</Text>
        <Link href="/" style={{ paddingVertical: 12 }}>
          <Text style={{ color: colors.accent, fontFamily: fonts.sansSemibold, fontSize: 16 }}>Back home</Text>
        </Link>
      </View>
    </>
  );
}
