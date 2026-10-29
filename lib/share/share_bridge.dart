import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'share_config.dart';

const shareChannelName = 'motiscroll/share';

class ShareBridge {
  ShareBridge({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(shareChannelName);

  static ShareBridge instance = ShareBridge();

  final MethodChannel _channel;
  var _warnedMissingMeta = false;

  void warnIfMetaMissing() {
    if (_warnedMissingMeta || metaAppIdReady) return;
    _warnedMissingMeta = true;
    if (kDebugMode) {
      debugPrint(
        'META_APP_ID is missing. Instagram and Facebook Story buttons are hidden. '
        'Pass --dart-define=META_APP_ID=your_id when running or building.',
      );
    }
  }

  Future<ShareApps> installedApps() async {
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'installedApps',
      );
      if (raw == null) return const ShareApps();
      return ShareApps(
        instagram: raw['instagram'] == true,
        facebook: raw['facebook'] == true,
        facebookLite: raw['facebookLite'] == true,
        whatsapp: raw['whatsapp'] == true,
        whatsappBusiness: raw['whatsappBusiness'] == true,
      );
    } on MissingPluginException {
      return const ShareApps();
    } on PlatformException {
      return const ShareApps();
    }
  }

  Future<bool> shareInstagramStory(String path) async {
    if (!metaAppIdReady) return false;
    return _bool('shareInstagramStory', {'path': path, 'appId': metaAppId});
  }

  Future<bool> shareFacebookStory(String path) async {
    if (!metaAppIdReady) return false;
    return _bool('shareFacebookStory', {'path': path, 'appId': metaAppId});
  }

  Future<bool> shareWhatsApp(String path, String caption) {
    return _bool('shareWhatsApp', {'path': path, 'caption': caption});
  }

  Future<Uint8List?> encodeJpeg(Uint8List png) async {
    try {
      final raw = await _channel.invokeMethod<Uint8List>('encodeJpeg', png);
      return raw;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<void> openSettings() async {
    try {
      await _channel.invokeMethod<void>('openSettings');
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  Future<bool> _bool(String method, Map<String, String> args) async {
    try {
      final raw = await _channel.invokeMethod<bool>(method, args);
      return raw == true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
