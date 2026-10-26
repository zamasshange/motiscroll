import { Modal, Pressable, Text, View } from 'react-native';

import type { Item } from '@/data/items';
import { useAppTheme } from '@/theme/useAppTheme';
import { openExternal } from '@/utils/openExternal';

export function PhotoCreditSheet({
  credit,
  onClose,
}: {
  credit?: Item['imageCredit'];
  onClose: () => void;
}) {
  const { colors, fonts, radii } = useAppTheme();
  return (
    <Modal visible={credit != null} transparent animationType="fade" onRequestClose={onClose}>
      <Pressable style={{ flex: 1, backgroundColor: colors.backdrop, justifyContent: 'flex-end' }} onPress={onClose}>
        <Pressable
          onPress={() => {}}
          style={{
            margin: 16,
            backgroundColor: colors.sheet,
            borderRadius: radii.card,
            borderWidth: 1,
            borderColor: colors.border,
            padding: 20,
            gap: 8,
          }}>
          <Text style={{ color: colors.text, fontFamily: fonts.serif, fontSize: 22 }}>Photo credit</Text>
          <Text style={{ color: colors.text, fontFamily: fonts.sans, fontSize: 16 }}>{credit?.artist}</Text>
          <Text style={{ color: colors.textMuted, fontFamily: fonts.sans, fontSize: 14 }}>{credit?.license}</Text>
          {credit?.sourceUrl ? (
            <Pressable onPress={() => openExternal(credit.sourceUrl)} accessibilityRole="link">
              <Text style={{ color: colors.accent, fontFamily: fonts.sansSemibold, fontSize: 15 }}>View source</Text>
            </Pressable>
          ) : null}
        </Pressable>
      </Pressable>
    </Modal>
  );
}
