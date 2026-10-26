import { useEffect, useMemo, useState } from 'react';
import { Text, View } from 'react-native';

import { DiscoverCard } from '@/components/DiscoverCard';
import { GoDeeperSheet } from '@/components/GoDeeperSheet';
import { useShareItem } from '@/components/useShareItem';
import { VerticalPager } from '@/components/VerticalPager';
import { ITEMS, itemById, type Item } from '@/data/items';
import { useStore } from '@/store/useStore';
import { useAppTheme } from '@/theme/useAppTheme';
import { lightTap } from '@/utils/haptics';
import { buildDiscoverOrder } from '@/utils/shuffle';

export default function DiscoverScreen() {
  const { colors, fonts } = useAppTheme();
  const queue = useStore((state) => state.discoverQueue);
  const index = useStore((state) => state.discoverIndex);
  const followed = useStore((state) => state.followedFields);
  const savedIds = useStore((state) => state.savedIds);
  const doneIds = useStore((state) => state.doneIds);
  const setDiscoverIndex = useStore((state) => state.setDiscoverIndex);
  const setDiscoverQueue = useStore((state) => state.setDiscoverQueue);
  const toggleSave = useStore((state) => state.toggleSave);
  const toggleDone = useStore((state) => state.toggleDone);
  const recordView = useStore((state) => state.recordView);
  const [sheetItem, setSheetItem] = useState<Item | null>(null);
  const { share, node } = useShareItem();

  const deck = useMemo(
    () => queue.map((id) => itemById(id)).filter((item): item is Item => item != null),
    [queue],
  );
  const safeIndex = Math.min(index, Math.max(deck.length - 1, 0));
  const current = deck[safeIndex];

  useEffect(() => {
    if (current) recordView();
  }, [current, recordView]);

  const jumpTo = (id: string) => {
    const next = deck.findIndex((item) => item.id === id);
    if (next >= 0) setDiscoverIndex(next);
  };

  const reshuffle = () => {
    let next = buildDiscoverOrder(ITEMS, followed);
    const last = deck[deck.length - 1]?.id;
    if (last && next[0] === last && next.length > 1) {
      const swapped = [...next];
      const second = swapped[1];
      swapped[1] = swapped[0];
      swapped[0] = second;
      next = swapped;
    }
    lightTap();
    setDiscoverQueue(next, 0);
  };

  return (
    <View style={{ flex: 1, backgroundColor: colors.bg }}>
      {deck.length === 0 || !current ? (
        <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', padding: 32 }}>
          <Text style={{ color: colors.text, fontFamily: fonts.serif, fontSize: 28, textAlign: 'center' }}>
            The deck is still settling.
          </Text>
        </View>
      ) : (
        <VerticalPager
          key={queue.join('|')}
          items={deck}
          index={safeIndex}
          enabled={sheetItem == null}
          onIndexChange={(next) => {
            if (next !== safeIndex) lightTap();
            setDiscoverIndex(next);
            recordView();
          }}
          onSwipePastEnd={reshuffle}
          renderItem={(item, itemIndex) => (
            <DiscoverCard
              item={item}
              saved={savedIds.includes(item.id)}
              done={doneIds.includes(item.id)}
              active={itemIndex === safeIndex}
              onOpen={() => setSheetItem(item)}
              onSave={() => {
                lightTap();
                toggleSave(item.id);
              }}
              onShare={() => share(item)}
              onDone={() => toggleDone(item.id)}
              onRelated={jumpTo}
            />
          )}
        />
      )}
      <GoDeeperSheet item={sheetItem} onClose={() => setSheetItem(null)} onOpenRelated={jumpTo} />
      {node}
    </View>
  );
}
