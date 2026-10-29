import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../data/models.dart';
import 'quote_card.dart';
import 'share_bridge.dart';

class ShareImageFile {
  const ShareImageFile({required this.file, required this.mime});

  final File file;
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
  }) async {
    final key = shareCacheKey(
      itemId: item.id,
      template: template,
      format: format,
      language: language,
    );
    var bytes = _cache[key];
    bytes ??= await _capture(
      context: context,
      item: item,
      template: template,
      format: format,
      language: language,
      translatedLabel: translatedLabel,
    );
    _cache[key] = bytes;

    var mime = 'image/png';
    var ext = 'png';
    if (bytes.length > shareMaxPngBytes) {
      final jpeg = await ShareBridge.instance.encodeJpeg(bytes);
      if (jpeg != null && jpeg.isNotEmpty) {
        bytes = jpeg;
        mime = 'image/jpeg';
        ext = 'jpg';
      }
    }

    final dir = await getTemporaryDirectory();
    final share = Directory('${dir.path}/share');
    await share.create(recursive: true);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final file = File('${share.path}/${item.id}_$stamp.$ext');
    await file.writeAsBytes(bytes, flush: true);
    return ShareImageFile(file: file, mime: mime);
  }

  Future<Uint8List> _capture({
    required BuildContext context,
    required Item item,
    required ShareTemplate template,
    required ShareFormat format,
    required String language,
    required String translatedLabel,
  }) async {
    await ensureFonts();
    if (!context.mounted) {
      throw StateError('Share card context went away.');
    }
    await precacheImage(const AssetImage('assets/images/mark.png'), context);
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
        return IgnorePointer(
          child: Opacity(
            opacity: 0.01,
            child: Transform.translate(
              offset: const Offset(-4000, 0),
              child: RepaintBoundary(
                key: boundaryKey,
                child: QuoteCardWidget(
                  item: item,
                  template: template,
                  format: format,
                  language: language,
                  translatedLabel: translatedLabel,
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
      for (var i = 0; i < 24; i++) {
        await WidgetsBinding.instance.endOfFrame;
        final object = boundaryKey.currentContext?.findRenderObject();
        if (object is RenderRepaintBoundary &&
            object.hasSize &&
            object.size.width >= size.width - 1) {
          boundary = object;
          if (i >= 2) break;
        }
      }
      if (boundary == null) {
        throw StateError('Share card did not paint.');
      }
      final image = await boundary.toImage(pixelRatio: 1);
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
