import { Text, View } from 'react-native';

import type { Item } from '@/data/items';
import { APP_NAME, fonts } from '@/theme/tokens';
import { sourceLine } from '@/utils/format';

export function ShareCard({ item }: { item: Item }) {
  return (
    <View
      collapsable={false}
      style={{
        width: 360,
        backgroundColor: '#100E0C',
        paddingHorizontal: 32,
        paddingTop: 36,
        paddingBottom: 28,
        gap: 18,
      }}>
      <View style={{ width: 42, height: 3, borderRadius: 3, backgroundColor: '#E07A4A' }} />
      {item.verified ? null : (
        <Text style={{ color: '#A8A197', fontFamily: fonts.sansMedium, fontSize: 12 }}>Not verified</Text>
      )}
      <Text style={{ color: '#F4F1EA', fontFamily: fonts.serifItalic, fontSize: 26, lineHeight: 36 }}>{item.text}</Text>
      <View style={{ gap: 4 }}>
        <Text style={{ color: '#F4F1EA', fontFamily: fonts.sansSemibold, fontSize: 16 }}>{item.author}</Text>
        <Text style={{ color: '#A8A197', fontFamily: fonts.sans, fontSize: 13 }}>{sourceLine(item)}</Text>
      </View>
      <Text style={{ color: '#E07A4A', fontFamily: fonts.sansSemibold, fontSize: 12, letterSpacing: 1.4 }}>
        {APP_NAME}
      </Text>
    </View>
  );
}
