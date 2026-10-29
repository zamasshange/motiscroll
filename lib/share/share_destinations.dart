import 'share_config.dart';

enum ShareDestination {
  instagramStory,
  facebook,
  whatsapp,
  tiktok,
  x,
  save,
  more,
}

class ShareButtonView {
  const ShareButtonView({
    required this.visible,
    required this.enabled,
    required this.systemShare,
  });

  final bool visible;
  final bool enabled;

  /// When true, tapping uses the system share sheet instead of a Story intent.
  final bool systemShare;
}

ShareButtonView instagramStoryView(ShareApps apps, {required bool metaReady}) {
  if (metaReady && apps.instagram) {
    return const ShareButtonView(
      visible: true,
      enabled: true,
      systemShare: false,
    );
  }
  return const ShareButtonView(visible: true, enabled: true, systemShare: true);
}

ShareButtonView facebookView(ShareApps apps, {required bool metaReady}) {
  if (metaReady && apps.facebook) {
    return const ShareButtonView(
      visible: true,
      enabled: true,
      systemShare: false,
    );
  }
  return const ShareButtonView(visible: true, enabled: true, systemShare: true);
}

ShareButtonView whatsappView(ShareApps apps) {
  if (apps.probed && apps.anyWhatsApp) {
    return const ShareButtonView(
      visible: true,
      enabled: true,
      systemShare: false,
    );
  }
  return const ShareButtonView(visible: true, enabled: true, systemShare: true);
}
