import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models.dart';
import '../l10n/languages.dart';
import '../l10n/widget_gallery.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import 'quote_card.dart';
import 'quote_card_renderer.dart';
import 'share_bridge.dart';
import 'share_caption.dart';
import 'share_config.dart';
import 'share_destinations.dart';
import 'share_prefs.dart';
import 'share_text.dart';

Future<void> showShareSheet(BuildContext context, Item item) {
  final box = context.findRenderObject();
  Rect? origin;
  if (box is RenderBox && box.hasSize) {
    origin = box.localToGlobal(Offset.zero) & box.size;
  }
  final palette = AppScope.of(context).palette;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: palette.sheet,
    barrierColor: palette.backdrop,
    elevation: 0,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(kSheetRadius)),
    ),
    builder: (context) {
      final height = MediaQuery.sizeOf(context).height;
      return SizedBox(
        height: height * 0.92,
        child: ShareSheet(item: item, origin: origin),
      );
    },
  );
}

class ShareSheet extends StatefulWidget {
  const ShareSheet({super.key, required this.item, this.origin});

  final Item item;
  final Rect? origin;

  @override
  State<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<ShareSheet> {
  final _page = PageController();
  var _template = ShareTemplate.dark;
  var _format = ShareFormat.square;
  var _apps = const ShareApps();
  var _ready = false;
  var _busy = false;
  var _whatsAppHintShown = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharePrefs.load();
    final apps = await ShareBridge.instance.installedApps();
    ShareBridge.instance.warnIfMetaMissing();
    if (!mounted) return;
    setState(() {
      _template = prefs.template;
      _format = prefs.format ?? formatForDestination(prefs.destination);
      _apps = apps;
      _whatsAppHintShown = prefs.whatsAppHintShown;
      _ready = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_page.hasClients) {
        _page.jumpToPage(_template.index);
      }
    });
  }

  String get _uiLang {
    final state = AppScope.of(context);
    return state.uiLanguage ??
        state.resolvedContentLanguage(Localizations.localeOf(context));
  }

  String get _contentLang {
    final state = AppScope.of(context);
    return state.contentLanguage ?? _uiLang;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    final ui = _uiLang;
    final content = _contentLang;
    final direction = languageByCode(ui)?.direction ?? TextDirection.ltr;
    final reduce = reduceMotion(context);
    final cardSize = shareFormatSize(_format);
    final ig = instagramStoryView(_apps, metaReady: metaAppIdReady);
    final fb = facebookView(_apps, metaReady: metaAppIdReady);
    final wa = whatsappView(_apps);
    return Directionality(
      textDirection: direction,
      child: Material(
        color: palette.sheet,
        surfaceTintColor: const Color(0x00000000),
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            16 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(shareUi(ui, 'share'), style: serif(palette, 28)),
              const SizedBox(height: 16),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: AspectRatio(
                        aspectRatio: cardSize.width / cardSize.height,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: palette.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: palette.border),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _ready
                                ? PageView(
                                    controller: _page,
                                    physics: reduce
                                        ? const NeverScrollableScrollPhysics()
                                        : null,
                                    onPageChanged: (index) {
                                      final next = ShareTemplate.values[index];
                                      setState(() => _template = next);
                                      unawaited(SharePrefs.setTemplate(next));
                                    },
                                    children: [
                                      for (final template
                                          in ShareTemplate.values)
                                        FittedBox(
                                          child: QuoteCardWidget(
                                            item: widget.item,
                                            template: template,
                                            format: _format,
                                            language: content,
                                            translatedLabel: widgetString(
                                              content,
                                              'translated',
                                            ),
                                          ),
                                        ),
                                    ],
                                  )
                                : const ColoredBox(color: Color(0xFF16161A)),
                          ),
                        ),
                      ),
                    ),
                    if (_busy)
                      const ColoredBox(
                        color: Color(0x66000000),
                        child: Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final template in ShareTemplate.values) ...[
                      ChoiceChipButton(
                        label: shareUi(ui, template.name),
                        selected: _template == template,
                        onTap: () {
                          setState(() => _template = template);
                          unawaited(SharePrefs.setTemplate(template));
                          if (_page.hasClients) {
                            if (reduce) {
                              _page.jumpToPage(template.index);
                            } else {
                              _page.animateToPage(
                                template.index,
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                              );
                            }
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final format in ShareFormat.values)
                    ChoiceChipButton(
                      label: shareUi(ui, format.name),
                      selected: _format == format,
                      onTap: () {
                        setState(() => _format = format);
                        unawaited(SharePrefs.setFormat(format));
                      },
                    ),
                ],
              ),
              if (_status != null) ...[
                const SizedBox(height: 8),
                Text(
                  _status!,
                  textAlign: TextAlign.center,
                  style: sans(palette, 14, height: 1.3, color: palette.accent),
                ),
              ],
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = (constraints.maxWidth - 16) / 3;
                  final buttons = <Widget>[
                    if (ig.visible)
                      _DestButton(
                        width: width,
                        icon: Icons.camera_alt_outlined,
                        label: shareUi(ui, 'instagramStory'),
                        enabled: ig.enabled,
                        notInstalled: shareUi(ui, 'notInstalled'),
                        onTap: () => _send(
                          ShareDestination.instagramStory,
                          forceStory: true,
                          systemShare: ig.systemShare,
                        ),
                      ),
                    if (fb.visible)
                      _DestButton(
                        width: width,
                        icon: Icons.public_rounded,
                        label: shareUi(ui, 'facebook'),
                        enabled: fb.enabled,
                        notInstalled: shareUi(ui, 'notInstalled'),
                        onTap: () => _send(
                          ShareDestination.facebook,
                          forceStory: !fb.systemShare,
                          systemShare: fb.systemShare,
                        ),
                      ),
                    _DestButton(
                      width: width,
                      icon: Icons.chat_rounded,
                      label: shareUi(ui, 'whatsapp'),
                      enabled: wa.enabled,
                      notInstalled: shareUi(ui, 'notInstalled'),
                      onTap: () => _sendWhatsApp(wa),
                    ),
                    _DestButton(
                      width: width,
                      icon: Icons.download_rounded,
                      label: shareUi(ui, 'savePicture'),
                      enabled: true,
                      notInstalled: shareUi(ui, 'notInstalled'),
                      onTap: () => _send(ShareDestination.save),
                    ),
                    _DestButton(
                      width: width,
                      icon: Icons.ios_share_rounded,
                      label: shareUi(ui, 'more'),
                      enabled: true,
                      notInstalled: shareUi(ui, 'notInstalled'),
                      onTap: () =>
                          _send(ShareDestination.more, systemShare: true),
                    ),
                  ];
                  return Wrap(spacing: 8, runSpacing: 8, children: buttons);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendWhatsApp(ShareButtonView view) async {
    if (!_whatsAppHintShown) {
      final go = await _showWhatsAppHint();
      if (go != true) return;
      _whatsAppHintShown = true;
      await SharePrefs.setWhatsAppHintShown();
    }
    await _send(
      ShareDestination.whatsapp,
      systemShare: view.systemShare || !Platform.isAndroid,
    );
  }

  Future<bool?> _showWhatsAppHint() {
    final palette = AppScope.of(context).palette;
    final ui = _uiLang;
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: palette.sheet,
          surfaceTintColor: const Color(0x00000000),
          title: Text(shareUi(ui, 'whatsapp'), style: serif(palette, 22)),
          content: Text(
            shareUi(ui, 'whatsappHint'),
            style: sans(palette, 15, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                shareUi(ui, 'ok'),
                style: sans(
                  palette,
                  15,
                  weight: FontWeight.w600,
                  color: palette.accent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _send(
    ShareDestination destination, {
    bool forceStory = false,
    bool systemShare = false,
  }) async {
    if (_busy) return;
    HapticFeedback.lightImpact();
    final ui = _uiLang;
    final content = _contentLang;
    final format = forceStory ? ShareFormat.story : _format;
    setState(() {
      _busy = true;
      _status = null;
    });
    ShareImageFile? image;
    try {
      await SharePrefs.setDestination(destination);
      await SharePrefs.setTemplate(_template);
      await SharePrefs.setFormat(_format);
      if (!mounted) return;
      image = await QuoteCardRenderer.instance.render(
        context: context,
        item: widget.item,
        template: _template,
        format: format,
        language: content,
        translatedLabel: widgetString(content, 'translated'),
      );
      if (!mounted) return;
      setState(() => _busy = false);
      final caption = shareCaption(
        widget.item,
        sharedFrom: shareUi(ui, 'sharedFrom'),
      );
      switch (destination) {
        case ShareDestination.instagramStory:
          if (systemShare) {
            await _systemShare(image, caption);
            break;
          }
          final ok = await ShareBridge.instance.shareInstagramStory(
            image.file.path,
          );
          if (!ok) {
            _note(shareUi(ui, 'couldntOpenInstagram'));
            await _systemShare(image, caption);
          }
        case ShareDestination.facebook:
          if (systemShare) {
            await _systemShare(image, caption);
            break;
          }
          final ok = await ShareBridge.instance.shareFacebookStory(
            image.file.path,
          );
          if (!ok) {
            _note(shareUi(ui, 'couldntOpenFacebook'));
            await _systemShare(image, caption);
          }
        case ShareDestination.whatsapp:
          if (systemShare || !Platform.isAndroid) {
            await _systemShare(image, caption);
            break;
          }
          final ok = await ShareBridge.instance.shareWhatsApp(
            image.file.path,
            caption,
          );
          if (!ok) {
            _note(shareUi(ui, 'couldntOpenWhatsApp'));
            await _systemShare(image, caption);
          }
        case ShareDestination.save:
          await _save(image);
        case ShareDestination.more:
          await _systemShare(image, caption);
      }
    } on Object {
      _note(shareUi(ui, 'couldntRender'));
    } finally {
      if (image != null) scheduleShareTempDelete(image.file);
      if (mounted && _busy) setState(() => _busy = false);
    }
  }

  Future<void> _save(ShareImageFile image) async {
    final ui = _uiLang;
    try {
      final allowed = await Gal.requestAccess();
      if (!allowed) {
        _denied();
        return;
      }
      try {
        await Gal.putImageBytes(
          image.bytes,
          name: 'motiscroll_${DateTime.now().millisecondsSinceEpoch}',
        );
      } on Object {
        final ok = await ShareBridge.instance.saveImage(image.file.path);
        if (!ok) rethrow;
      }
      _note(shareUi(ui, 'savedToPhotos'));
    } on GalException catch (error) {
      if (error.type == GalExceptionType.accessDenied) {
        _denied();
        return;
      }
      final ok = await ShareBridge.instance.saveImage(image.file.path);
      if (ok) {
        _note(shareUi(ui, 'savedToPhotos'));
      } else {
        _note(shareUi(ui, 'couldntSave'));
      }
    } on Object {
      final ok = await ShareBridge.instance.saveImage(image.file.path);
      if (ok) {
        _note(shareUi(ui, 'savedToPhotos'));
      } else {
        _note(shareUi(ui, 'couldntSave'));
      }
    }
  }

  void _denied() {
    final palette = AppScope.of(context).palette;
    final ui = _uiLang;
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: palette.sheet,
          surfaceTintColor: const Color(0x00000000),
          content: Text(
            shareUi(ui, 'photosDenied'),
            style: sans(palette, 15, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ShareBridge.instance.openSettings();
              },
              child: Text(
                shareUi(ui, 'openSettings'),
                style: sans(
                  palette,
                  15,
                  weight: FontWeight.w600,
                  color: palette.accent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _systemShare(ShareImageFile image, String caption) async {
    final native = await ShareBridge.instance.shareSystem(
      image.file.path,
      caption,
    );
    if (native) return;
    if (!mounted) return;
    final origin = widget.origin ?? (Offset.zero & MediaQuery.sizeOf(context));
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(image.file.path, mimeType: image.mime)],
        text: caption,
        sharePositionOrigin: origin,
      ),
    );
  }

  void _note(String message) {
    if (!mounted) return;
    setState(() => _status = message);
  }
}

class _DestButton extends StatelessWidget {
  const _DestButton({
    required this.width,
    required this.icon,
    required this.label,
    required this.enabled,
    required this.notInstalled,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String label;
  final bool enabled;
  final String notInstalled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return SizedBox(
      width: width,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Pressable(
          onPressed: onTap,
          semanticLabel: enabled ? label : '$label, $notInstalled',
          child: Container(
            height: 88,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: palette.text),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: sans(palette, 12, weight: FontWeight.w600),
                ),
                if (!enabled)
                  Text(
                    notInstalled,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: sans(palette, 10, color: palette.textMuted),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
