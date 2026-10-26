import { Ionicons } from '@expo/vector-icons';
import { useLocalSearchParams } from 'expo-router';
import { useEffect, useMemo, useRef, useState } from 'react';
import { Pressable, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { FeedSlide } from '@/components/FeedSlide';
import { GoDeeperSheet } from '@/components/GoDeeperSheet';
import { HeartButton } from '@/components/HeartButton';
import { HintBanner } from '@/components/HintBanner';
import { IconHit } from '@/components/PrimaryButton';
import { PickerSheet, type PickerRow } from '@/components/PickerSheet';
import { Scrubber } from '@/components/Scrubber';
import { useShareItem } from '@/components/useShareItem';
import { VerticalPager } from '@/components/VerticalPager';
import { ITEMS, itemById, type Item } from '@/data/items';
import { FIELD_ORDER, FIELD_META, MOODS, isMood } from '@/data/taxonomy';
import { useStore } from '@/store/useStore';
import { useAppTheme, useDockInset } from '@/theme/useAppTheme';
import { filterItems, filterKey, filterLabel, type FeedFilter } from '@/utils/filters';
import { firstParam, sourceLine } from '@/utils/format';
import { lightTap } from '@/utils/haptics';

export default function FeedScreen() {
  const params = useLocalSearchParams<{ mood?: string; itemId?: string; at?: string }>();
  const mood = firstParam(params.mood);
  const itemId = firstParam(params.itemId);
  const at = firstParam(params.at);
  const { colors, fonts, radii } = useAppTheme();
  const insets = useSafeAreaInsets();
  const dock = useDockInset();
  const [filter, setFilter] = useState<FeedFilter>({ kind: 'all' });
  const [index, setIndex] = useState(0);
  const [menu, setMenu] = useState<'filter' | 'jump' | null>(null);
  const [sheetItem, setSheetItem] = useState<Item | null>(null);
  const indexRef = useRef(0);
  const { share, node } = useShareItem();

  const likedIds = useStore((state) => state.likedIds);
  const savedIds = useStore((state) => state.savedIds);
  const fontScale = useStore((state) => state.fontScale);
  const hintDismissed = useStore((state) => state.hintDismissed);
  const toggleLike = useStore((state) => state.toggleLike);
  const toggleSave = useStore((state) => state.toggleSave);
  const dismissHint = useStore((state) => state.dismissHint);
  const recordView = useStore((state) => state.recordView);

  const filtered = useMemo(() => filterItems(ITEMS, filter), [filter]);
  const safeIndex = Math.min(index, Math.max(filtered.length - 1, 0));
  const current = filtered[safeIndex];

  useEffect(() => {
    indexRef.current = safeIndex;
    if (safeIndex !== index) setIndex(safeIndex);
  }, [index, safeIndex]);

  useEffect(() => {
    if (!at) return;
    if (itemId) {
      setFilter({ kind: 'all' });
      const next = ITEMS.findIndex((item) => item.id === itemId);
      setIndex(next < 0 ? 0 : next);
      return;
    }
    if (mood && isMood(mood)) {
      setFilter({ kind: 'mood', mood });
      setIndex(0);
    }
  }, [at, itemId, mood]);

  useEffect(() => {
    if (current) recordView();
  }, [current, recordView]);

  const setFromPager = (next: number) => {
    if (indexRef.current !== next) lightTap();
    indexRef.current = next;
    setIndex(next);
  };

  const jumpToId = (id: string) => {
    const within = filtered.findIndex((item) => item.id === id);
    if (within >= 0) {
      setIndex(within);
      return;
    }
    const allIndex = ITEMS.findIndex((item) => item.id === id);
    if (allIndex < 0) return;
    setFilter({ kind: 'all' });
    setIndex(allIndex);
  };

  const filterRows: PickerRow[] = [
    { id: 'all', label: 'All', active: filter.kind === 'all' },
    ...FIELD_ORDER.map((field) => ({
      id: `field:${field}`,
      label: FIELD_META[field].title,
      active: filter.kind === 'field' && filter.field === field,
    })),
    ...MOODS.map((entry) => ({
      id: `mood:${entry.id}`,
      label: entry.label,
      active: filter.kind === 'mood' && filter.mood === entry.id,
    })),
  ];

  const jumpRows: PickerRow[] = filtered.map((item, itemIndex) => ({
    id: item.id,
    label: item.author,
    hint: sourceLine(item),
    active: itemIndex === safeIndex,
  }));

  return (
    <View style={{ flex: 1, backgroundColor: colors.bg }}>
      {filtered.length === 0 || !current ? (
        <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', padding: 32, gap: 16 }}>
          <Text style={{ color: colors.text, fontFamily: fonts.serif, fontSize: 28, textAlign: 'center' }}>
            Nothing in this filter yet.
          </Text>
          <Pressable onPress={() => setFilter({ kind: 'all' })} accessibilityRole="button">
            <Text style={{ color: colors.accent, fontFamily: fonts.sansSemibold, fontSize: 16 }}>Show everything</Text>
          </Pressable>
        </View>
      ) : (
        <VerticalPager
          key={filterKey(filter)}
          items={filtered}
          index={safeIndex}
          enabled={sheetItem == null && menu == null}
          onIndexChange={setFromPager}
          renderItem={(item, itemIndex) => (
            <FeedSlide
              item={item}
              fontScale={fontScale}
              active={itemIndex === safeIndex}
              onOpen={() => setSheetItem(item)}
            />
          )}
        />
      )}

      <View pointerEvents="box-none" style={{ position: 'absolute', top: 0, right: 0, bottom: 0, left: 0 }}>
        <View
          style={{
            position: 'absolute',
            top: insets.top + 8,
            left: 16,
            right: 16,
            flexDirection: 'row',
            justifyContent: 'space-between',
            gap: 12,
          }}>
          <Pill label={filterLabel(filter)} onPress={() => setMenu('filter')} />
          <Pill label={current ? current.author : 'Jump'} onPress={() => setMenu('jump')} align="right" />
        </View>

        {current ? (
          <View
            pointerEvents="box-none"
            style={{
              position: 'absolute',
              right: 6,
              top: insets.top + 96,
              bottom: dock,
              justifyContent: 'center',
            }}>
            <HeartButton active={likedIds.includes(current.id)} onPress={() => toggleLike(current.id)} />
            <IconHit
              label={savedIds.includes(current.id) ? 'Remove save' : 'Save'}
              onPress={() => {
                lightTap();
                toggleSave(current.id);
              }}>
              <Ionicons
                name={savedIds.includes(current.id) ? 'bookmark' : 'bookmark-outline'}
                size={26}
                color={savedIds.includes(current.id) ? colors.accent : colors.text}
              />
            </IconHit>
            <IconHit label="Share" onPress={() => share(current)}>
              <Ionicons name="share-outline" size={26} color={colors.text} />
            </IconHit>
          </View>
        ) : null}

        {filtered.length > 1 ? (
          <View style={{ position: 'absolute', left: 4, top: insets.top + 120 }}>
            <Scrubber
              count={filtered.length}
              index={safeIndex}
              onChange={(next) => {
                indexRef.current = next;
                setIndex(next);
              }}
            />
          </View>
        ) : null}

        {!hintDismissed && current ? (
          <View style={{ position: 'absolute', left: 48, right: 72, bottom: dock - 4 }}>
            <HintBanner onDismiss={dismissHint} />
          </View>
        ) : null}
      </View>

      <GoDeeperSheet
        item={sheetItem}
        onClose={() => setSheetItem(null)}
        onOpenRelated={(id) => {
          const related = itemById(id);
          jumpToId(id);
          if (related) setSheetItem(null);
        }}
      />
      {menu === 'filter' ? (
        <PickerSheet
          title="Show"
          rows={filterRows}
          onClose={() => setMenu(null)}
          onPick={(id) => {
            if (id === 'all') setFilter({ kind: 'all' });
            else if (id.startsWith('field:')) setFilter({ kind: 'field', field: id.slice(6) as Item['field'] });
            else if (id.startsWith('mood:') && isMood(id.slice(5))) setFilter({ kind: 'mood', mood: id.slice(5) });
            setIndex(0);
            setMenu(null);
          }}
        />
      ) : null}
      {menu === 'jump' ? (
        <PickerSheet
          title="Jump to"
          rows={jumpRows}
          onClose={() => setMenu(null)}
          onPick={(id) => {
            jumpToId(id);
            setMenu(null);
          }}
        />
      ) : null}
      {node}
    </View>
  );
}

function Pill({ label, onPress, align = 'left' }: { label: string; onPress: () => void; align?: 'left' | 'right' }) {
  const { colors, fonts, radii } = useAppTheme();
  return (
    <Pressable
      onPress={onPress}
      accessibilityRole="button"
      style={{
        maxWidth: '46%',
        flexDirection: 'row',
        alignItems: 'center',
        gap: 6,
        backgroundColor: colors.card,
        borderRadius: radii.pill,
        borderWidth: 1,
        borderColor: colors.border,
        paddingHorizontal: 14,
        paddingVertical: 8,
      }}>
      <Text numberOfLines={1} style={{ flexShrink: 1, color: colors.text, fontFamily: fonts.sansMedium, fontSize: 14 }}>
        {label}
      </Text>
      <Ionicons name="chevron-down" size={14} color={colors.textMuted} style={{ marginLeft: align === 'right' ? 0 : 0 }} />
    </Pressable>
  );
}
