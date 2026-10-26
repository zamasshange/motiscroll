import { Alert, Linking } from 'react-native';

export function openExternal(url: string) {
  Linking.openURL(url).catch(() => {
    Alert.alert('This link could not be opened.');
  });
}
