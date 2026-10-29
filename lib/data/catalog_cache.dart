import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'models.dart';
import 'repositories.dart';

/// The last published library, so the home screen can open before Firestore
/// answers. The file is only written from lines the catalog already returned.
class CatalogCache {
  static Future<List<Item>> read() async {
    if (Platform.environment['FLUTTER_TEST'] == 'true') return const [];
    try {
      final file = await _file();
      if (!await file.exists()) return const [];
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return const [];
      final rows = decoded['items'];
      if (rows is! List) return const [];
      final items = <Item>[];
      for (final row in rows) {
        if (row is! Map) continue;
        final map = Map<String, dynamic>.from(row);
        final id = map.remove('id');
        if (id is! String || id.isEmpty) continue;
        items.add(itemFromPublished(id, map));
      }
      return items;
    } on Object {
      return const [];
    }
  }

  static Future<void> write(List<Item> items) async {
    if (items.isEmpty || Platform.environment['FLUTTER_TEST'] == 'true') return;
    try {
      final file = await _file();
      await file.writeAsString(
        jsonEncode({
          'items': [for (final item in items) itemToPublishedJson(item)],
        }),
      );
    } on Object {
      return;
    }
  }

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/catalog_snapshot.json');
  }
}

Map<String, Object?> itemToPublishedJson(Item item) {
  return {
    'id': item.id,
    'type': item.type,
    'text': item.text,
    'authorName': item.author,
    'authorRole': item.authorRole,
    'field': item.field.name,
    'moods': [for (final mood in item.moods) mood.name],
    'primarySource': {
      'title': item.source.title,
      'year': item.source.year,
      'url': item.source.url,
    },
    'deeper': {
      'context': item.deeper.context,
      'didYouKnow': item.deeper.didYouKnow,
      'takeaway': item.deeper.takeaway,
    },
    'related': item.deeper.related,
    'speech': item.speech == null
        ? null
        : {
            'durationSec': item.speech!.durationSec,
            'watchUrl': item.speech!.watchUrl,
          },
    'isTranslated': item.isTranslated,
    'authorImageUrl': item.imageUrl,
    'imageCredit': item.imageCredit == null
        ? null
        : {
            'artist': item.imageCredit!.artist,
            'license': item.imageCredit!.license,
            'sourceUrl': item.imageCredit!.sourceUrl,
          },
  };
}
