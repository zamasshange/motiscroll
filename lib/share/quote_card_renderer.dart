import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../data/models.dart';
import '../widgets/chrome.dart';
import 'quote_card.dart';
import 'share_bridge.dart';

class ShareImageFile {
  const ShareImageFile({
    required this.file,
    required this.bytes,
    required this.mime,
  });

  final File file;
  final Uint8List bytes;
  final String mime;
}

/// Paints [QuoteCardWidget] off-screen and writes a PNG (or JPEG if huge).
class QuoteCardRenderer {
  QuoteCardRenderer._();

  static final QuoteCardRenderer instance = QuoteCardRenderer._();

  final Map<String, Uint8List> _cache = {};
  var _fontsReady = false;

  @visibleForTesting
  int get cacheLength => _cache.length;

  @visibleForTesting
  void clearCache() => _cache.clear();

  static Future<void> cleanupTemp() async {
    try {
      final dir = await getTemporaryDirectory();
      final share = Directory('${dir.path}/share');
      if (await share.exists()) {
        await share.delete(recursive: true);
      }
    } on Object {
      return;
    }
  }

  Future<void> ensureFonts() async {
    if (_fontsReady) return;
    await Future.wait([
      rootBundle.load('assets/fonts/PlayfairDisplay_600SemiBold.ttf'),
      rootBundle.load('assets/fonts/PlayfairDisplay_600SemiBold_Italic.ttf'),
      rootBundle.load('assets/fonts/PlayfairDisplay_500Medium_Italic.ttf'),
      rootBundle.load('assets/fonts/DMSans_400Regular.ttf'),
      rootBundle.load('assets/fonts/DMSans_500Medium.ttf'),
      rootBundle.load('assets/fonts/DMSans_600SemiBold.ttf'),
      rootBundle.load('assets/fonts/DMSans_700Bold.ttf'),
      rootBundle.load('assets/images/mark.png'),
    ]);
    _fontsReady = true;
  }

  Future<ShareImageFile> render({
    required BuildContext context,
    required Item item,
    required ShareTemplate template,
    required ShareFormat format,
    required String language,
    required String translatedLabel,
    String? portraitUrl,
  }) async {
    final key = shareCacheKey(
      itemId: item.id,
      template: template,
      format: format,
      language: language,
    );
    final cacheId = '$key@${shareExportPixelRatio.toStringAsFixed(0)}';
    var bytes = _cache[cacheId];
    bytes ??= await _capture(
      context: context,
      item: item,
      template: template,
      format: format,
      language: language,
      translatedLabel: translatedLabel,
      portraitUrl: portraitUrl,
    );
    _cache[cacheId] = bytes;

    var mime = 'image/png';
    var ext = 'png';
    final jpeg = await ShareBridge.instance.encodeJpeg(bytes);
    if (jpeg != null && jpeg.isNotEmpty) {
      bytes = jpeg;
      mime = 'image/jpeg';
      ext = 'jpg';
    }

    final dir = await getTemporaryDirectory();
    final share = Directory('${dir.path}/share');
    await share.create(recursive: true);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final file = File('${share.path}/${item.id}_$stamp.$ext');
    await file.writeAsBytes(bytes, flush: true);
    return ShareImageFile(file: file, bytes: bytes, mime: mime);
  }

  @visibleForTesting
  Future<Uint8List> capturePng({
    required BuildContext context,
    required Item item,
    required ShareTemplate template,
    required ShareFormat format,
    required String language,
    required String translatedLabel,
    String? portraitUrl,
  }) {
    return _capture(
      context: context,
      item: item,
      template: template,
      format: format,
      language: language,
      translatedLabel: translatedLabel,
      portraitUrl: portraitUrl,
    );
  }

  Future<Uint8List> _capture({
    required BuildContext context,
    required Item item,
    required ShareTemplate template,
    required ShareFormat format,
    required String language,
    required String translatedLabel,
    String? portraitUrl,
  }) async {
    await ensureFonts();
    if (!context.mounted) {
      throw StateError('Share card context went away.');
    }
    await precacheImage(const AssetImage('assets/images/mark.png'), context);
    final own = item.imageUrl;
    final portrait = (own != null && own.isNotEmpty) ? own : portraitUrl;
    if (portrait != null && portrait.isNotEmpty && context.mounted) {
      try {
        await precacheImage(
          NetworkImage(portrait, headers: imageHeaders),
          context,
        );
      } on Object {
        // The card falls back to the app icon when the portrait cannot load.
      }
    }
    if (!context.mounted) {
      throw StateError('Share card context went away.');
    }
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      throw StateError('Share card needs an Overlay to render.');
    }
    final size = shareFormatSize(format);
    final boundaryKey = GlobalKey();
    final entry = OverlayEntry(
      builder: (context) {
        return ShareCaptureHost(
          size: size,
          child: MediaQuery(
            data: MediaQueryData(
              size: size,
              devicePixelRatio: shareExportPixelRatio,
              textScaler: TextScaler.noScaling,
              padding: EdgeInsets.zero,
            ),
            child: RepaintBoundary(
              key: boundaryKey,
              child: ExcludeSemantics(
                child: QuoteCardWidget(
                  item: item,
                  template: template,
                  format: format,
                  language: language,
                  translatedLabel: translatedLabel,
                  portraitUrl: portraitUrl,
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(entry);
    try {
      RenderRepaintBoundary? boundary;
      for (var i = 0; i < 40; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 16));
        final object = boundaryKey.currentContext?.findRenderObject();
        if (object is RenderRepaintBoundary &&
            object.hasSize &&
            (object.size.width - size.width).abs() < 1 &&
            (object.size.height - size.height).abs() < 1) {
          boundary = object;
          if (i >= 2) break;
        }
      }
      if (boundary == null) {
        throw StateError(
          'Share card did not paint at ${size.width}x${size.height}.',
        );
      }
      final image = await boundary.toImage(pixelRatio: shareExportPixelRatio);
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        if (data == null) {
          throw StateError('Share card PNG was empty.');
        }
        return data.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } finally {
      entry.remove();
    }
  }
}

/// Keeps a full-resolution card at [size] even when the Overlay is phone-sized.
class ShareCaptureHost extends StatelessWidget {
  const ShareCaptureHost({super.key, required this.size, required this.child});

  final Size size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: -size.width - 64,
      top: 0,
      width: size.width,
      height: size.height,
      child: IgnorePointer(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: size.width,
          maxWidth: size.width,
          minHeight: size.height,
          maxHeight: size.height,
          child: child,
        ),
      ),
    );
  }
}

void scheduleShareTempDelete(File file) {
  unawaited(
    Future<void>.delayed(const Duration(seconds: 90), () async {
      try {
        if (await file.exists()) await file.delete();
      } on FileSystemException {
        return;
      }
    }),
  );
}
