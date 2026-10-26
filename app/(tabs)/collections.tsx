import { ScrollView, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { FollowButton } from '@/components/FollowButton';
import { GeneratedCover } from '@/components/GeneratedCover';
import { FIELD_META, FIELD_ORDER } from '@/data/taxonomy';
import { ITEMS, type Field } from '@/data/items';
import { useStore } from '@/store/useStore';
import { useAppTheme, useDockInset } from '@/theme/useAppTheme';

export default function CollectionsScreen() {
  const { colors, fonts } = useAppTheme();
  const insets = useSafeAreaInsets();
  const dock = useDockInset();
  const followed = useStore((state) => state.followedFields);
  const toggleFollow = useStore((state) => state.toggleFollow);

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: colors.bg }}
      contentContainerStyle={{ paddingTop: insets.top + 18, paddingHorizontal: 20, paddingBottom: dock + 28, gap: 16 }}>
      <View style={{ gap: 6, marginBottom: 4 }}>
        <Text style={{ color: colors.text, fontFamily: fonts.serif, fontSize: 36 }}>Collections</Text>
        <Text style={{ color: colors.textMuted, fontFamily: fonts.sans, fontSize: 15, lineHeight: 22 }}>
          Follow a field and it moves to the front of Discover.
        </Text>
      </View>
      {FIELD_ORDER.map((field) => (
        <FieldCard
          key={field}
          field={field}
          count={ITEMS.filter((item) => item.field === field).length}
          following={followed.includes(field)}
          onToggle={() => toggleFollow(field)}
        />
      ))}
    </ScrollView>
  );
}

function FieldCard({
  field,
  count,
  following,
  onToggle,
}: {
  field: Field;
  count: number;
  following: boolean;
  onToggle: () => void;
}) {
  const { colors, fonts, radii } = useAppTheme();
  const meta = FIELD_META[field];
  return (
    <View
      style={{
        backgroundColor: colors.card,
        borderRadius: radii.card,
        borderWidth: 1,
        borderColor: colors.border,
        overflow: 'hidden',
      }}>
      <View style={{ height: 180 }}>
        <GeneratedCover field={field} seed={field} style={{ height: 180 }} />
        <View style={{ position: 'absolute', left: 18, right: 18, bottom: 16, gap: 8 }}>
          <View
            style={{
              alignSelf: 'flex-start',
              borderRadius: radii.pill,
              paddingHorizontal: 10,
              paddingVertical: 4,
              backgroundColor: 'rgba(11,11,13,0.45)',
            }}>
            <Text style={{ color: '#F4F1EA', fontFamily: fonts.sansMedium, fontSize: 12 }}>
              {count} {count === 1 ? 'reading' : 'readings'}
            </Text>
          </View>
          <Text
            style={{
              color: '#F4F1EA',
              fontFamily: fonts.serif,
              fontSize: 36,
              lineHeight: 40,
              textShadowColor: 'rgba(0,0,0,0.45)',
              textShadowOffset: { width: 0, height: 1 },
              textShadowRadius: 8,
            }}>
            {meta.title}
          </Text>
        </View>
      </View>
      <View style={{ padding: 16, gap: 12 }}>
        <Text style={{ color: colors.textMuted, fontFamily: fonts.sans, fontSize: 15, lineHeight: 22 }}>
          {meta.description}
        </Text>
        <FollowButton following={following} onPress={onToggle} />
      </View>
    </View>
  );
}