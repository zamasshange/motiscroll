const metaAppId = String.fromEnvironment('META_APP_ID');

bool get metaAppIdReady => metaAppId.isNotEmpty;

class ShareApps {
  const ShareApps({
    this.probed = true,
    this.instagram = false,
    this.facebook = false,
    this.facebookLite = false,
    this.whatsapp = false,
    this.whatsappBusiness = false,
  });

  static const unknown = ShareApps(probed: false);

  final bool probed;
  final bool instagram;
  final bool facebook;
  final bool facebookLite;
  final bool whatsapp;
  final bool whatsappBusiness;

  bool get anyFacebook => facebook || facebookLite;
  bool get anyWhatsApp => whatsapp || whatsappBusiness;

  bool get canInstagramStory => metaAppIdReady && instagram;
  bool get canFacebookStory => metaAppIdReady && facebook;
}

bool showMetaStoryButtons(ShareApps apps) => metaAppIdReady;

bool instagramStoryEnabled(ShareApps apps) => apps.canInstagramStory;

bool facebookStoryEnabled(ShareApps apps) => apps.canFacebookStory;
