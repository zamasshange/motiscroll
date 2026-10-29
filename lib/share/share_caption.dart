import '../data/models.dart';
import '../theme/tokens.dart';
import '../widgets/widget_payload.dart';

const shareLinkBase = 'https://example.com/motiscroll';

String shareItemLink(String itemId) => '$shareLinkBase/q/$itemId';

String shareCaption(Item item, {String sharedFrom = 'Shared from $kAppName'}) {
  return '"${item.text}"\n— ${item.author}\n$sharedFrom\n${shareItemLink(item.id)}';
}

/// Turns a web share URL into the in-app item link. Universal links are later.
Uri? shareWebLinkToApp(Uri? uri) {
  if (uri == null) return null;
  if (uri.scheme == 'motiscroll') return uri;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  final segments = uri.pathSegments.where((part) => part.isNotEmpty).toList();
  if (segments.length >= 2 &&
      segments[segments.length - 2] == 'q' &&
      segments.last.isNotEmpty) {
    return Uri(scheme: 'motiscroll', host: 'item', path: '/${segments.last}');
  }
  return null;
}

Uri? resolveShareLaunch(Uri? uri) {
  final converted = shareWebLinkToApp(uri);
  if (converted != null) return converted;
  return WidgetLink.parse(uri) != null ? uri : null;
}
