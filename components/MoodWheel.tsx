import { useRef, useState } from 'react';
import { ScrollView, Text, View } from 'react-native';

import { MOODS } from '@/data/taxonomy';
import { useAppTheme } from '@/theme/useAppTheme';
import { lightTap } from '@/utils/haptics';

const ROW = 46;
const VISIBLE = 5;

export function MoodWheel({ value, onChange }: { value: string; onChange: (id: string) => void }) {
  const { colors, fonts } = useAppTheme();
  const selected = Math.max(0, MOODS.findIndex((mood) => mood.id === value));
  const [offset, setOffset] = useState(selected * ROW);
  const last = useRef(selected);

  return (
    <View style={{ height: ROW * VISIBLE, overflow: 'hidden' }}>
      <View
        pointerEvents="none"
        style={{
          position: 'absolute',
          left: 28,
          right: 28,
          top: ROW * 2,
          height: ROW,
          borderRadius: 999,
          backgroundColor: colors.cardAlt,
          borderWidth: 1,
          borderColor: colors.border,
        }}
      />
      <ScrollView
        showsVerticalScrollIndicator={false}
        snapToInterval={ROW}
        decelerationRate="fast"
        contentOffset={{ x: 0, y: selected * ROW }}
        contentContainerStyle={{ paddingVertical: ROW * 2 }}
        scrollEventThrottle={16}
        onScroll={(event) => {
          const y = event.nativeEvent.contentOffset.y;
          setOffset(y);
          const next = Math.min(MOODS.length - 1, Math.max(0, Math.round(y / ROW)));
          if (next !== last.current) {
            last.current = next;
            lightTap();
            onChange(MOODS[next].id);
          }
        }}>
        {MOODS.map((mood, index) => {
          const distance = Math.abs(index * ROW - offset) / ROW;
          const scale = Math.max(0.84, 1 - distance * 0.08);
          const opacity = Math.max(0.22, 1 - distance * 0.36);
          const active = distance < 0.5;
          return (
            <View key={mood.id} style={{ height: ROW, alignItems: 'center', justifyContent: 'center' }}>
              <Text
                style={{
                  opacity,
                  transform: [{ scale }],
                  fontFamily: active ? fonts.sansSemibold : fonts.sans,
                  fontSize: active ? 22 : 16,
                  color: active ? colors.text : colors.textMuted,
                }}>
                {mood.label}
              </Text>
            </View>
          );
        })}
      </ScrollView>
    </View>
  );
}