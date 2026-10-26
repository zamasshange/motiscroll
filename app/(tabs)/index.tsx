import { Ionicons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import { useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { AuthorAvatar } from '@/components/AuthorAvatar';
import { FieldPill } from '@/components/FieldPill';
import { GeneratedCover } from '@/components/GeneratedCover';
import { MoodWheel } from '@/components/MoodWheel';
import { PrimaryButton } from '@/components/PrimaryButton';
import { SectionLabel } from '@/components/SectionLabel';
import { useStore } from '@/store/useStore';
import { useAppTheme, useDockInset } from '@/theme/useAppTheme';
import { dailyPicks } from '@/utils/daily';
import { greeting } from '@/utils/dates';
import { formatDuration, sourceLine } from '@/utils/format';
import { openFeed } from '@/utils/nav';

export default function HomeScreen() {
  const { colors, fonts, radii } = useAppTheme();
  const insets = useSafeAreaInsets();
  const dock = useDockInset();
  const router = useRouter();
  const streak = useStore((state) => state.streakCount);
  const usualMood = useStore((state) => state.usualMood);
  const picks = dailyPicks();
  const [mood, setMood] = useState(usualMood ?? 'starting-over');

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: colors.bg }}
      contentContainerStyle={{
        paddingTop: insets.top + 18,
        paddingHorizontal: 20,
        paddingBottom: dock + 24,
        gap: 18,
      }}>
      <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 12 }}>
        <Text style={{ flex: 1, color: colors.text, fontFamily: fonts.serif, fontSize: 34 }}>{greeting()}</Text>
        <View style={{ flexDirection: 'row', alignItems: 'center', gap: 4 }}>
          <Ionicons name="flame" size={18} color={colors.accent} />
          <Text style={{ color: colors.text, fontFamily: fonts.sansSemibold, fontSize: 16 }}>{streak}</Text>
          <Pressable
            onPress={() => router.push('/saved')}
            accessibilityRole="button"
            accessibilityLabel="Saved"
            hitSlop={8}
            style={{ marginLeft: 10, minWidth: 36, minHeight: 36, alignItems: 'center', justifyContent: 'center' }}>
            <Ionicons name="bookmark-outline" size={22} color={colors.text} />
          </Pressable>
          <Pressable
            onPress={() => router.push('/settings')}
            accessibilityRole="button"
            accessibilityLabel="Settings"
            hitSlop={8}
            style={{ minWidth: 36, minHeight: 36, alignItems: 'center', justifyContent: 'center' }}>
            <Ionicons name="settings-outline" size={22} color={colors.text} />
          </Pressable>
        </View>
      </View>

      {picks.quote ? (
        <Pressable
          onPress={() => openFeed({ itemId: picks.quote!.id })}
          accessibilityRole="button"
          style={({ pressed }) => ({
            minHeight: 280,
            borderRadius: radii.card,
            borderWidth: 1,
            borderColor: colors.border,
            overflow: 'hidden',
            opacity: pressed ? 0.92 : 1,
          })}>
          <GeneratedCover field={picks.quote.field} seed={picks.quote.id} style={StyleSheet.absoluteFill} />
          <View style={[StyleSheet.absoluteFill, { backgroundColor: 'rgba(11,11,13,0.66)' }]} />
          <View style={{ padding: 20, gap: 14, flex: 1, justifyContent: 'flex-end' }}>
            <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' }}>
              <SectionLabel>Quote of the day</SectionLabel>
              <FieldPill field={picks.quote.field} />
            </View>
            <Text style={{ color: '#F4F1EA', fontFamily: fonts.serifItalic, fontSize: 28, lineHeight: 38 }}>
              {picks.quote.text}
            </Text>
            <Text style={{ color: '#F4F1EA', fontFamily: fonts.sansSemibold, fontSize: 16 }}>{picks.quote.author}</Text>
            <Text style={{ color: 'rgba(244,241,234,0.72)', fontFamily: fonts.sans, fontSize: 13 }}>
              {sourceLine(picks.quote)}
            </Text>
          </View>
        </Pressable>
      ) : null}

      <View
        style={{
          backgroundColor: colors.card,
          borderRadius: radii.card,
          borderWidth: 1,
          borderColor: colors.border,
          paddingVertical: 20,
          paddingHorizontal: 8,
          gap: 8,
        }}>
        <View style={{ paddingHorizontal: 12, gap: 4 }}>
          <SectionLabel>For the day you are having</SectionLabel>
          <Text style={{ color: colors.textMuted, fontFamily: fonts.sans, fontSize: 14 }}>
            Spin to a mood, then open a matching feed.
          </Text>
        </View>
        <MoodWheel value={mood} onChange={setMood} />
        <View style={{ paddingHorizontal: 12, paddingTop: 8 }}>
          <PrimaryButton label="Show me" onPress={() => openFeed({ mood })} />
        </View>
      </View>

      {picks.speech ? (
        <Pressable
          onPress={() => openFeed({ itemId: picks.speech!.id })}
          accessibilityRole="button"
          style={({ pressed }) => ({
            backgroundColor: colors.card,
            borderRadius: radii.card,
            borderWidth: 1,
            borderColor: colors.border,
            overflow: 'hidden',
            opacity: pressed ? 0.92 : 1,
          })}>
          <GeneratedCover field={picks.speech.field} seed={picks.speech.id} style={{ height: 72 }} />
          <View style={{ padding: 16, flexDirection: 'row', gap: 14 }}>
          <AuthorAvatar
            author={picks.speech.author}
            imageUrl={picks.speech.imageUrl}
            credit={picks.speech.imageCredit}
            field={picks.speech.field}
            size={84}
            shape="rounded"
            play
            showCredit
          />
          <View style={{ flex: 1, gap: 4 }}>
            <SectionLabel>Today&apos;s speech</SectionLabel>
            <Text style={{ color: colors.text, fontFamily: fonts.serif, fontSize: 22 }}>{picks.speech.author}</Text>
            <Text numberOfLines={2} style={{ color: colors.textMuted, fontFamily: fonts.sans, fontSize: 14 }}>
              {sourceLine(picks.speech)}
            </Text>
            <Text style={{ color: colors.accent, fontFamily: fonts.sansSemibold, fontSize: 13 }}>
              {picks.speech.speech ? formatDuration(picks.speech.speech.durationSec) : 'Read excerpt'}
            </Text>
          </View>
          </View>
        </Pressable>
      ) : null}

      {picks.boost ? (
        <View
          style={{
            backgroundColor: colors.card,
            borderRadius: radii.card,
            borderWidth: 1,
            borderColor: colors.border,
            overflow: 'hidden',
          }}>
          <GeneratedCover field={picks.boost.field} seed={`${picks.boost.id}-boost`} style={{ height: 64 }} />
          <View style={{ padding: 20, gap: 10 }}>
          <SectionLabel>Daily boost</SectionLabel>
          <Text style={{ color: colors.text, fontFamily: fonts.serif, fontSize: 22, lineHeight: 30 }}>
            {picks.boost.deeper.takeaway}
          </Text>
          <Text style={{ color: colors.textFaint, fontFamily: fonts.sans, fontSize: 13 }}>
            A way to use a reading from {picks.boost.author}. Not their words.
          </Text>
          <Pressable onPress={() => openFeed({ itemId: picks.boost!.id })} accessibilityRole="button" hitSlop={6}>
            <Text style={{ color: colors.accent, fontFamily: fonts.sansSemibold, fontSize: 15 }}>Open the reading</Text>
          </Pressable>
          </View>
        </View>
      ) : null}
    </ScrollView>
  );
}
