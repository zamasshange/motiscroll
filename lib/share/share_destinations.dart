import 'share_config.dart';

enum ShareDestination { instagramStory, facebook, whatsapp, save, more }

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

ShareButtonView instagramStoryView(
  ShareApps apps, {
  required bool metaReady,
}) {
  if (!metaReady) {
    return const ShareButtonView(
      visible: false,
      enabled: false,
      systemShare: true,
    );
  }
  if (!apps.instagram) {
    return const ShareButtonView(
      visible: true,
      enabled: false,
      systemShare: true,
    );
  }
  return const ShareButtonView(
    visible: true,
    enabled: true,
    systemShare: false,
  );
}

ShareButtonView facebookView(ShareApps apps, {required bool metaReady}) {
  if (!metaReady) {
    return const ShareButtonView(
      visible: false,
      enabled: false,
      systemShare: true,
    );
  }
  if (apps.facebook) {
    return const ShareButtonView(
      visible: true,
      enabled: true,
      systemShare: false,
    );
  }
  if (apps.facebookLite) {
    return const ShareButtonView(
      visible: true,
      enabled: true,
      systemShare: true,
    );
  }
  return const ShareButtonView(
    visible: true,
    enabled: false,
    systemShare: true,
  );
}

ShareButtonView whatsappView(ShareApps apps) {
  if (apps.anyWhatsApp) {
    return const ShareButtonView(
      visible: true,
      enabled: true,
      systemShare: false,
    );
  }
  return const ShareButtonView(
    visible: true,
    enabled: false,
    systemShare: true,
  );
}
