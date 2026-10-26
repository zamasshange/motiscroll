import { Ionicons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import { Pressable, Text, View } from 'react-native';

import { useAppTheme } from '@/theme/useAppTheme';

export function BackHeader({ title }: { title: string }) {
  const router = useRouter();
  const { colors, fonts } = useAppTheme();
  return (
    <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
      <Pressable
        onPress={() => router.back()}
        accessibilityRole="button"
        accessibilityLabel="Back"
        hitSlop={8}
        style={{ width: 40, height: 40, alignItems: 'center', justifyContent: 'center' }}>
        <Ionicons name="chevron-back" size={24} color={colors.text} />
      </Pressable>
      <Text style={{ color: colors.text, fontFamily: fonts.serif, fontSize: 28 }}>{title}</Text>
    </View>
  );
}
