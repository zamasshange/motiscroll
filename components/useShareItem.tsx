import { useEffect, useRef, useState } from 'react';
import { Alert, Platform, View, type HostInstance } from 'react-native';
import { captureRef } from 'react-native-view-shot';
import * as Sharing from 'expo-sharing';

import { ShareCard } from '@/components/ShareCard';
import type { Item } from '@/data/items';
import { APP_NAME } from '@/theme/tokens';

function downloadDataUri(uri: string) {
  const link = document.createElement('a');
  link.href = uri;
  link.download = `${APP_NAME.replace(/\s+/g, '-').toLowerCase()}-quote.png`;
  document.body.appendChild(link);
  link.click();
  link.remove();
}

async function presentImage(uri: string) {
  if (Platform.OS === 'web') {
    const response = await fetch(uri);
    const blob = await response.blob();
    const file = new File([blob], `${APP_NAME}-quote.png`, { type: 'image/png' });
    if (typeof navigator.share === 'function' && navigator.canShare?.({ files: [file] })) {
      await navigator.share({ files: [file], title: APP_NAME });
      return;
    }
    downloadDataUri(uri);
    return;
  }

  const available = await Sharing.isAvailableAsync();
  if (!available) {
    Alert.alert('Sharing is not available on this device.');
    return;
  }
  await Sharing.shareAsync(uri, { mimeType: 'image/png', UTI: 'public.png' });
}

export function useShareItem() {
  const ref = useRef<HostInstance | null>(null);
  const [item, setItem] = useState<Item | null>(null);
  const [laidOut, setLaidOut] = useState(false);
  const busy = useRef(false);

  useEffect(() => {
    if (!item || !laidOut || busy.current) return;
    busy.current = true;
    const timer = setTimeout(() => {
      void (async () => {
        try {
          const uri = await captureRef(ref.current as never, {
            format: 'png',
            quality: 1,
            result: Platform.OS === 'web' ? 'data-uri' : 'tmpfile',
          });
          await presentImage(uri);
        } catch {
          Alert.alert('Could not create a share image for this card.');
        } finally {
          busy.current = false;
          setItem(null);
          setLaidOut(false);
        }
      })();
    }, 80);
    return () => clearTimeout(timer);
  }, [item, laidOut]);

  const share = (next: Item) => {
    if (busy.current) return;
    setLaidOut(false);
    setItem(next);
  };

  const node = item ? (
    <View
      ref={ref}
      pointerEvents="none"
      collapsable={false}
      onLayout={() => setLaidOut(true)}
      style={{ position: 'absolute', left: -2000, top: 0 }}>
      <ShareCard item={item} />
    </View>
  ) : null;

  return { share, node };
}
