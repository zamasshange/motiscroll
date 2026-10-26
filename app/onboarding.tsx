import type { Href } from 'expo-router';
import { useRouter } from 'expo-router';
import { useState } from 'react';
import { Pressable, Text, View } from 'react-native';
import Animated, {
  Easing,
  useAnimatedStyle,
  useSharedValue,
  withRepeat,
  withTiming,
} from 'react-native-reanimated';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useEffect } from 'react';

import { GeneratedCover } from '@/components/GeneratedCover';
import { PrimaryButton } from '@/components/PrimaryButton';
import { FIELD_META, FIELD_ORDER, MOODS, type MoodId } from '@/data/taxonomy';
import { useStore } from '@/store/useStore';
import { APP_NAME } from '@/theme/tokens';
import { useAppTheme } from '@/theme/useAppTheme';
import { enableMorningReminder } from '@/utils/reminders';
import { useReduceMotion } from '@/utils/motion';

const VALUE_STEPS = [
  {
    title: 'Scroll with purpose',
    body: 'Trade the endless feed for one line you can actually sit with.',
    art: 'stack',
  },
  {
    title: 'Go deeper on any quote',
    body: 'Each line opens into the moment it came from, and one thing to do with it today.',
    art: 'lines',
  },
  {
    title: 'Build a daily habit',
    body: 'A streak, a speech, and a short boost that fits the day you are having.',
    art: 'ring',
  },
] as const;

export default function OnboardingScreen() {
  const [step, setStep] = useState(0);
  const [mood, setMood] = useState<MoodId>('starting-over');
  const [busy, setBusy] = useState(false);
  const followed = useStore((state) => state.followedFields);
  const toggleFollow = useStore((state) => state.toggleFollow);
  const setUsualMood = useStore((state) => state.setUsualMood);
  const completeOnboarding = useStore((state) => state.completeOnboarding);
  const router = useRouter();

  const finish = () => {
    setUsualMood(mood);
    completeOnboarding();
    router.replace('/' as Href);
  };

  const allowReminder = async () => {
    if (busy) return;
    setBusy(true);
    try {
      await enableMorningReminder();
    } catch {
      // The simulator can refuse the prompt. The app still opens.
    }
    finish();
  };

  if (step === 0) {
    return (
      <Welcome
        onNext={() => setStep(1)}
        onSkip={() => setStep(4)}
      />
    );
  }
  if (step >= 1 && step <= 3) {
    const page = VALUE_STEPS[step - 1];
    return (
      <ValuePage
        title={page.title}
        body={page.body}
        art={page.art}
        index={step}
        onNext={() => setStep(step + 1)}
        onSkip={() => setStep(4)}
      />
    );
  }
  if (step === 4) {
    return (
      <Personalize
        followed={followed}
        mood={mood}
        onToggle={toggleFollow}
        onMood={setMood}
        onNext={() => setStep(5)}
      />
    );
  }
  return <Reminder busy={busy} onAllow={allowReminder} onSkip={finish} />;
}

function Welcome({ onNext, onSkip }: { onNext: () => void; onSkip: () => void }) {
  const { colors, fonts } = useAppTheme();
  const insets = useSafeAreaInsets();
  return (
    <View style={{ flex: 1, backgroundColor: colors.bg }}>
      <GeneratedCover field="leadership" seed="welcome" style={{ position: 'absolute', top: 0, left: 0, right: 0, bottom: 0 }} />
      <View style={{ position: 'absolute', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(11,11,13,0.62)' }} />
      <View style={{ flex: 1, paddingTop: insets.top + 24, paddingHorizontal: 28, paddingBottom: insets.bottom + 24, justifyContent: 'space-between' }}>
        <Pressable onPress={onSkip} accessibilityRole="button" hitSlop={8} style={{ alignSelf: 'flex-end' }}>
          <Text style={{ color: 'rgba(244,241,234,0.8)', fontFamily: fonts.sansMedium, fontSize: 15 }}>Skip</Text>
        </Pressable>
        <View style={{ gap: 16 }}>
          <Text style={{ color: '#F4F1EA', fontFamily: fonts.serif, fontSize: 48, lineHeight: 54 }}>{APP_NAME}</Text>
          <Text style={{ color: 'rgba(244,241,234,0.86)', fontFamily: fonts.sans, fontSize: 18, lineHeight: 28 }}>
            Short lines and speeches, one at a time, instead of another empty scroll.
          </Text>
        </View>
        <PrimaryButton label="Get started" onPress={onNext} />
      </View>
    </View>
  );
}

function ValuePage({
  title,
  body,
  art,
  index,
  onNext,
  onSkip,
}: {
  title: string;
  body: string;
  art: 'stack' | 'lines' | 'ring';
  index: number;
  onNext: () => void;
  onSkip: () => void;
}) {
  const { colors, fonts } = useAppTheme();
  const insets = useSafeAreaInsets();
  return (
    <View style={{ flex: 1, backgroundColor: colors.bg }}>
      <GeneratedCover field={index === 1 ? 'arts' : index === 2 ? 'science' : 'resilience'} seed={title} style={{ position: 'absolute', top: 0, left: 0, right: 0, bottom: 0 }} />
      <View style={{ position: 'absolute', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(11,11,13,0.72)' }} />
      <View style={{ flex: 1, paddingTop: insets.top + 24, paddingHorizontal: 28, paddingBottom: insets.bottom + 24 }}>
        <Pressable onPress={onSkip} accessibilityRole="button" hitSlop={8} style={{ alignSelf: 'flex-end' }}>
          <Text style={{ color: 'rgba(244,241,234,0.8)', fontFamily: fonts.sansMedium, fontSize: 15 }}>Skip</Text>
        </Pressable>
        <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
          <Art kind={art} />
        </View>
        <View style={{ gap: 16 }}>
          <Text style={{ color: '#F4F1EA', fontFamily: fonts.serif, fontSize: 40, lineHeight: 46 }}>{title}</Text>
          <Text style={{ color: 'rgba(244,241,234,0.84)', fontFamily: fonts.sans, fontSize: 17, lineHeight: 26 }}>{body}</Text>
          <Dots count={4} active={index} />
          <PrimaryButton label="Continue" onPress={onNext} />
        </View>
      </View>
    </View>
  );
}

function Personalize({
  followed,
  mood,
  onToggle,
  onMood,
  onNext,
}: {
  followed: string[];
  mood: MoodId;
  onToggle: (field: (typeof FIELD_ORDER)[number]) => void;
  onMood: (mood: MoodId) => void;
  onNext: () => void;
}) {
  const { colors, fonts, radii } = useAppTheme();
  const insets = useSafeAreaInsets();
  return (
    <View style={{ flex: 1, backgroundColor: colors.bg, paddingTop: insets.top + 28, paddingHorizontal: 24, paddingBottom: insets.bottom + 24, gap: 22 }}>
      <View style={{ gap: 8 }}>
        <Text style={{ color: colors.text, fontFamily: fonts.serif, fontSize: 36, lineHeight: 42 }}>Make it yours</Text>
        <Text style={{ color: colors.textMuted, fontFamily: fonts.sans, fontSize: 16, lineHeight: 24 }}>
          Follow the fields you care about, and pick what you need lately.
        </Text>
      </View>
      <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8 }}>
        {FIELD_ORDER.map((field) => {
          const selected = followed.includes(field);
          return (
            <Pressable
              key={field}
              onPress={() => onToggle(field)}
              accessibilityRole="button"
              accessibilityState={{ selected }}
              style={{
                borderRadius: radii.pill,
                borderWidth: 1,
                borderColor: selected ? colors.accent : colors.border,
                backgroundColor: selected ? colors.accent : colors.card,
                paddingHorizontal: 14,
                paddingVertical: 10,
              }}>
              <Text style={{ color: selected ? '#1A0E08' : colors.text, fontFamily: fonts.sansSemibold, fontSize: 15 }}>
                {FIELD_META[field].title}
              </Text>
            </Pressable>
          );
        })}
      </View>
      <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8 }}>
        {MOODS.map((entry) => {
          const selected = mood === entry.id;
          return (
            <Pressable
              key={entry.id}
              onPress={() => onMood(entry.id)}
              accessibilityRole="button"
              accessibilityState={{ selected }}
              style={{
                borderRadius: radii.pill,
                borderWidth: 1,
                borderColor: selected ? colors.text : colors.border,
                backgroundColor: selected ? colors.text : 'transparent',
                paddingHorizontal: 14,
                paddingVertical: 10,
              }}>
              <Text style={{ color: selected ? colors.bg : colors.text, fontFamily: fonts.sansMedium, fontSize: 14 }}>
                {entry.label}
              </Text>
            </Pressable>
          );
        })}
      </View>
      <View style={{ marginTop: 'auto' }}>
        <PrimaryButton label="Continue" onPress={onNext} />
      </View>
    </View>
  );
}

function Reminder({ busy, onAllow, onSkip }: { busy: boolean; onAllow: () => void; onSkip: () => void }) {
  const { colors, fonts } = useAppTheme();
  const insets = useSafeAreaInsets();
  return (
    <View style={{ flex: 1, backgroundColor: colors.bg, paddingTop: insets.top + 36, paddingHorizontal: 28, paddingBottom: insets.bottom + 24, justifyContent: 'space-between' }}>
      <View style={{ gap: 12, marginTop: 48 }}>
        <Text style={{ color: colors.text, fontFamily: fonts.serif, fontSize: 40, lineHeight: 46 }}>A nudge at eight</Text>
        <Text style={{ color: colors.textMuted, fontFamily: fonts.sans, fontSize: 17, lineHeight: 26 }}>
          One local reminder each morning. No account, and you can skip it.
        </Text>
      </View>
      <View style={{ gap: 12 }}>
        <PrimaryButton label={busy ? 'One moment' : 'Allow reminders'} onPress={onAllow} />
        <Pressable onPress={onSkip} accessibilityRole="button" style={{ alignItems: 'center', paddingVertical: 12 }}>
          <Text style={{ color: colors.textMuted, fontFamily: fonts.sansSemibold, fontSize: 16 }}>Not now</Text>
        </Pressable>
      </View>
    </View>
  );
}

function Dots({ count, active }: { count: number; active: number }) {
  const { colors } = useAppTheme();
  return (
    <View style={{ flexDirection: 'row', gap: 8 }}>
      {Array.from({ length: count }, (_, index) => (
        <View
          key={index}
          style={{
            width: index === active ? 18 : 7,
            height: 7,
            borderRadius: 99,
            backgroundColor: index === active ? colors.accent : 'rgba(244,241,234,0.35)',
          }}
        />
      ))}
    </View>
  );
}

function Art({ kind }: { kind: 'stack' | 'lines' | 'ring' }) {
  const reduce = useReduceMotion();
  const shift = useSharedValue(0);
  useEffect(() => {
    if (reduce) return;
    shift.value = withRepeat(withTiming(1, { duration: 1800, easing: Easing.inOut(Easing.quad) }), -1, true);
  }, [reduce, shift]);
  const style = useAnimatedStyle(() => ({
    transform: [{ translateY: reduce ? 0 : -8 * shift.value }],
  }));
  return (
    <Animated.View style={[{ width: 180, height: 180, alignItems: 'center', justifyContent: 'center' }, style]}>
      {kind === 'stack' ? <StackArt /> : null}
      {kind === 'lines' ? <LinesArt /> : null}
      {kind === 'ring' ? <RingArt /> : null}
    </Animated.View>
  );
}

function StackArt() {
  return (
    <View style={{ width: 140, height: 160 }}>
      {[0, 1, 2].map((index) => (
        <View
          key={index}
          style={{
            position: 'absolute',
            left: index * 14,
            top: 28 + index * 18,
            width: 110,
            height: 72,
            borderRadius: 18,
            backgroundColor: index === 2 ? '#E07A4A' : 'rgba(244,241,234,0.16)',
            borderWidth: 1,
            borderColor: 'rgba(244,241,234,0.2)',
          }}
        />
      ))}
    </View>
  );
}

function LinesArt() {
  return (
    <View style={{ width: 150, gap: 12 }}>
      {[1, 0.72, 0.46].map((width, index) => (
        <View
          key={index}
          style={{
            height: 10,
            width: 150 * width,
            borderRadius: 99,
            backgroundColor: index === 0 ? '#F4F1EA' : 'rgba(244,241,234,0.35)',
          }}
        />
      ))}
    </View>
  );
}

function RingArt() {
  return (
    <View
      style={{
        width: 120,
        height: 120,
        borderRadius: 60,
        borderWidth: 10,
        borderColor: 'rgba(224,122,74,0.85)',
        alignItems: 'center',
        justifyContent: 'center',
      }}>
      <View style={{ width: 18, height: 18, borderRadius: 9, backgroundColor: '#F4F1EA' }} />
    </View>
  );
}
