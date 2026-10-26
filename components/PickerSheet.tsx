import { Ionicons } from '@expo/vector-icons';
import { Modal, Pressable, ScrollView, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { useAppTheme } from '@/theme/useAppTheme';

export type PickerRow = { id: string; label: string; hint?: string; active?: boolean };

export function PickerSheet({
  title,
  rows,
  onClose,
  onPick,
}: {
  title: string;
  rows: PickerRow[];
  onClose: () => void;
  onPick: (id: string) => void;
}) {
  const { colors, fonts, radii } = useAppTheme();
  const insets = useSafeAreaInsets();

  return (
    <Modal visible transparent animationType="fade" onRequestClose={onClose}>
      <View style={{ flex: 1, justifyContent: 'flex-end' }}>
        <Pressable style={{ position: 'absolute', top: 0, right: 0, bottom: 0, left: 0, backgroundColor: colors.backdrop }} onPress={onClose} />
        <View
          style={{
            maxHeight: '78%',
            backgroundColor: colors.sheet,
            borderTopLeftRadius: radii.sheet,
            borderTopRightRadius: radii.sheet,
            borderWidth: 1,
            borderColor: colors.border,
            paddingBottom: Math.max(insets.bottom, 16),
          }}>
          <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 22, paddingTop: 18, paddingBottom: 8 }}>
            <Text style={{ color: colors.text, fontFamily: fonts.serif, fontSize: 26 }}>{title}</Text>
            <Pressable onPress={onClose} accessibilityRole="button" accessibilityLabel="Close" hitSlop={8}>
              <Ionicons name="close" size={24} color={colors.text} />
            </Pressable>
          </View>
          <ScrollView contentContainerStyle={{ paddingHorizontal: 12, paddingBottom: 12 }}>
            {rows.map((row) => (
              <Pressable
                key={row.id}
                onPress={() => onPick(row.id)}
                accessibilityRole="button"
                style={({ pressed }) => ({
                  flexDirection: 'row',
                  alignItems: 'center',
                  gap: 12,
                  paddingHorizontal: 12,
                  paddingVertical: 14,
                  borderRadius: 16,
                  backgroundColor: pressed || row.active ? colors.cardAlt : 'transparent',
                })}>
                <View style={{ flex: 1, gap: 2 }}>
                  <Text style={{ color: colors.text, fontFamily: fonts.sansMedium, fontSize: 16 }}>{row.label}</Text>
                  {row.hint ? (
                    <Text numberOfLines={1} style={{ color: colors.textMuted, fontFamily: fonts.sans, fontSize: 13 }}>
                      {row.hint}
                    </Text>
                  ) : null}
                </View>
                {row.active ? <Ionicons name="checkmark" size={18} color={colors.accent} /> : null}
              </Pressable>
            ))}
          </ScrollView>
        </View>
      </View>
    </Modal>
  );
}
