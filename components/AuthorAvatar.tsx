import { Ionicons } from '@expo/vector-icons';
import { Image, Pressable, Text, View } from 'react-native';

import { PhotoCreditSheet } from '@/components/PhotoCreditSheet';
import type { Field, Item } from '@/data/items';
import { COVER_PALETTES } from '@/theme/covers';
import { useAppTheme } from '@/theme/useAppTheme';
import { hashString } from '@/utils/format';
import { useState } from 'react';

function initials(name: string) {
  const parts = name.split(/\s+/).filter(Boolean);
  if (parts.length === 0) return '?';
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return `${parts[0][0]}${parts[parts.length - 1][0]}`.toUpperCase();
}

export function AuthorAvatar({
  author,
  imageUrl,
  credit,
  field = 'other',
  size = 44,
  shape = 'circle',
  play = false,
  showCredit = false,
}: {
  author: string;
  imageUrl?: string;
  credit?: Item['imageCredit'];
  field?: Field;
  size?: number;
  shape?: 'circle' | 'rounded';
  play?: boolean;
  showCredit?: boolean;
}) {
  const { colors, fonts } = useAppTheme();
  const [open, setOpen] = useState(false);
  const palette = COVER_PALETTES[field];
  const hash = hashString(author);
  const radius = shape === 'circle' ? size / 2 : Math.round(size * 0.22);
  const mark = (
    <View
      style={{
        width: size,
        height: size,
        borderRadius: radius,
        overflow: 'hidden',
        borderWidth: 1,
        borderColor: 'rgba(255,255,255,0.28)',
        backgroundColor: palette[hash % 2 === 0 ? 3 : 2],
        alignItems: 'center',
        justifyContent: 'center',
      }}>
      {imageUrl ? (
        <Image source={{ uri: imageUrl }} style={{ width: size, height: size }} accessibilityIgnoresInvertColors />
      ) : (
        <Text style={{ color: '#F4F1EA', fontFamily: fonts.serif, fontSize: size * 0.32 }}>{initials(author)}</Text>
      )}
      {play ? (
        <View
          style={{
            position: 'absolute',
            right: Math.max(4, size * 0.06),
            bottom: Math.max(4, size * 0.06),
            width: Math.max(22, size * 0.28),
            height: Math.max(22, size * 0.28),
            borderRadius: 99,
            backgroundColor: colors.accent,
            alignItems: 'center',
            justifyContent: 'center',
          }}>
          <Ionicons name="play" size={Math.max(12, size * 0.14)} color="#1A0E08" />
        </View>
      ) : null}
    </View>
  );

  return (
    <View style={{ alignItems: 'flex-start', gap: 6 }}>
      {mark}
      {showCredit && credit ? (
        <Pressable onPress={() => setOpen(true)} accessibilityRole="button" accessibilityLabel="Photo credit" hitSlop={8}>
          <Text style={{ color: colors.textFaint, fontFamily: fonts.sans, fontSize: 12 }}>Photo credit</Text>
        </Pressable>
      ) : null}
      <PhotoCreditSheet credit={open ? credit : undefined} onClose={() => setOpen(false)} />
    </View>
  );
}
