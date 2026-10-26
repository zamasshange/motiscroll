import { BlurView } from 'expo-blur';
import { LinearGradient } from 'expo-linear-gradient';
import { memo, useMemo } from 'react';
import { StyleSheet, View, type StyleProp, type ViewStyle } from 'react-native';

import type { Field } from '@/data/items';
import { COVER_PALETTES, coverBlobs } from '@/theme/covers';
import { hashString } from '@/utils/format';

type Props = {
  field: Field;
  seed: string;
  variant?: 'full' | 'subtle';
  style?: StyleProp<ViewStyle>;
};

function grainDots(seed: string) {
  let value = hashString(`grain:${seed}`);
  return Array.from({ length: 16 }, (_, index) => {
    value = (Math.imul(value ^ (value >>> 13), 1274126177) + index) >>> 0;
    return {
      left: `${(value % 1000) / 10}%` as const,
      top: `${((value >>> 8) % 1000) / 10}%` as const,
      light: (value & 1) === 0,
    };
  });
}

export const GeneratedCover = memo(function GeneratedCover({ field, seed, variant = 'full', style }: Props) {
  const palette = COVER_PALETTES[field];
  const blobs = useMemo(() => coverBlobs(field, seed), [field, seed]);
  const grains = useMemo(() => grainDots(`${field}:${seed}`), [field, seed]);

  return (
    <View style={[{ overflow: 'hidden', backgroundColor: palette[2] }, style]} pointerEvents="none">
      <LinearGradient colors={[palette[1], palette[2], palette[3]]} style={StyleSheet.absoluteFill} />
      {blobs.map((blob, index) => (
        <View
          key={index}
          style={{
            position: 'absolute',
            width: `${blob.size * 100}%`,
            aspectRatio: 1,
            left: `${blob.x * 100}%`,
            top: `${blob.y * 100}%`,
            borderRadius: 999,
            backgroundColor: blob.color,
            opacity: 0.9,
          }}
        />
      ))}
      <BlurView intensity={variant === 'subtle' ? 24 : 46} tint="dark" style={StyleSheet.absoluteFill} />
      {grains.map((dot, index) => (
        <View
          key={index}
          style={{
            position: 'absolute',
            left: dot.left,
            top: dot.top,
            width: 2,
            height: 2,
            borderRadius: 1,
            backgroundColor: dot.light ? '#FFFFFF' : '#000000',
            opacity: 0.16,
          }}
        />
      ))}
      <LinearGradient
        colors={['rgba(0,0,0,0.18)', 'rgba(0,0,0,0.02)', 'rgba(0,0,0,0.5)']}
        style={StyleSheet.absoluteFill}
      />
      {variant === 'subtle' ? (
        <View style={[StyleSheet.absoluteFill, { backgroundColor: 'rgba(11,11,13,0.8)' }]} />
      ) : null}
    </View>
  );
});
