import 'package:cloud_firestore/cloud_firestore.dart' hide Field, Source;

import 'catalog.dart';
import 'discover_deck.dart';
import 'models.dart';

class PageChunk {
  const PageChunk(this.items, {this.cursor});

  final List<Item> items;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
}

abstract class ItemRepository {
  Future<PageChunk> page({
    Field? field,
    Mood? mood,
    bool more = false,
    int limit = 20,
  });

  Future<Item?> byId(String id);

  Future<Item?> quoteOfDay(DateTime day);

  Future<PageChunk> discover({
    required Set<Field> followed,
    required DiscoverDeck deck,
    int limit = 20,
  });
}

abstract class UserDirectory {
  Future<void> ensureProfile({
    required Set<Field> fields,
    required Mood? mood,
    required String timezone,
    required String reminderTime,
    required bool reminderLocal,
  });

  Future<void> setFlag({
    required String collection,
    required String id,
    required bool on,
  });

  Future<void> report({
    required String itemId,
    required String reason,
    required String note,
  });

  Future<int?> recordView(String itemId);
}

class LocalItemRepository implements ItemRepository {
  LocalItemRepository(this.items);

  final List<Item> items;

  @override
  Future<PageChunk> page({
    Field? field,
    Mood? mood,
    bool more = false,
    int limit = 20,
  }) async {
    if (more) return const PageChunk([]);
    final filtered = items.where((item) {
      if (field != null && item.field != field) return false;
      if (mood != null && !item.moods.contains(mood)) return false;
      return true;
    }).toList();
    return PageChunk(filtered);
  }

  @override
  Future<Item?> byId(String id) async => itemById(id, items);

  @override
  Future<Item?> quoteOfDay(DateTime day) async =>
      dailyPicks(day, null, items)?.quote;

  @override
  Future<PageChunk> discover({
    required Set<Field> followed,
    required DiscoverDeck deck,
    int limit = 20,
  }) async {
    return PageChunk(discoverOrder(followed, items));
  }
}

class FirestoreItemRepository implements ItemRepository {
  FirestoreItemRepository(this._db);

  final FirebaseFirestore _db;
  DocumentSnapshot<Map<String, dynamic>>? _cursor;

  @override
  Future<PageChunk> page({
    Field? field,
    Mood? mood,
    bool more = false,
    int limit = 20,
  }) async {
    if (!more) _cursor = null;
    Query<Map<String, dynamic>> query = _db.collection('publishedItems');
    if (field != null) query = query.where('field', isEqualTo: field.name);
    if (mood != null) query = query.where('moods', arrayContains: mood.name);
    query = query.orderBy('rand').limit(limit);
    final cursor = _cursor;
    if (more && cursor != null) query = query.startAfterDocument(cursor);
    final snap = await query.get();
    if (snap.docs.isNotEmpty) _cursor = snap.docs.last;
    return PageChunk(
      snap.docs.map((doc) => itemFromPublished(doc.id, doc.data())).toList(),
    );
  }

  @override
  Future<Item?> byId(String id) async {
    final doc = await _db.collection('publishedItems').doc(id).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return itemFromPublished(doc.id, data);
  }

  @override
  Future<Item?> quoteOfDay(DateTime day) async {
    final doc = await _db.collection('daily').doc(dayKey(day)).get();
    final data = doc.data();
    if (data == null) return null;
    final snapshot = data['publishedItemSnapshot'];
    if (snapshot is Map<String, dynamic>) {
      return itemFromPublished(data['itemId'] as String? ?? doc.id, snapshot);
    }
    if (snapshot is Map) {
      return itemFromPublished(
        data['itemId'] as String? ?? doc.id,
        Map<String, dynamic>.from(snapshot),
      );
    }
    return null;
  }

  @override
  Future<PageChunk> discover({
    required Set<Field> followed,
    required DiscoverDeck deck,
    int limit = 20,
  }) async {
    final start = DateTime.now().millisecondsSinceEpoch % 1000 / 1000;
    final followedItems = followed.isEmpty
        ? const <Item>[]
        : await _randPage(
            start,
            whereIn: followed.map((field) => field.name).toList(),
          );
    final others = await _randPage(start);
    var page = deck.take(followed: followedItems, other: others, count: limit);
    if (page.length < limit) {
      final wrappedFollowed = followed.isEmpty
          ? const <Item>[]
          : await _randPage(
              0,
              whereIn: followed.map((field) => field.name).toList(),
            );
      final wrapped = await _randPage(0);
      page = [
        ...page,
        ...deck.take(
          followed: wrappedFollowed,
          other: wrapped,
          count: limit - page.length,
        ),
      ];
    }
    return PageChunk(page);
  }

  Future<List<Item>> _randPage(double start, {List<String>? whereIn}) async {
    Query<Map<String, dynamic>> query = _db.collection('publishedItems');
    if (whereIn != null && whereIn.isNotEmpty) {
      query = query.where('field', whereIn: whereIn.take(10).toList());
    }
    final snap = await query
        .where('rand', isGreaterThanOrEqualTo: start)
        .orderBy('rand')
        .limit(20)
        .get();
    return snap.docs
        .map((doc) => itemFromPublished(doc.id, doc.data()))
        .toList();
  }
}

class FirestoreUserDirectory implements UserDirectory {
  FirestoreUserDirectory(this._db, this.uid);

  final FirebaseFirestore _db;
  final String uid;

  DocumentReference<Map<String, dynamic>> get _user =>
      _db.collection('users').doc(uid);

  @override
  Future<void> ensureProfile({
    required Set<Field> fields,
    required Mood? mood,
    required String timezone,
    required String reminderTime,
    required bool reminderLocal,
  }) async {
    await _user.set({
      'onboardingDone': true,
      'timezone': timezone,
      'usualMood': mood?.name,
      'selectedFields': fields.map((field) => field.name).toList(),
      'reminderTime': reminderTime,
      'reminderLocal': reminderLocal,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    for (final field in fields) {
      await _user.collection('followedFields').doc(field.name).set({
        'on': true,
      });
    }
  }

  @override
  Future<void> setFlag({
    required String collection,
    required String id,
    required bool on,
  }) async {
    final ref = _user.collection(collection).doc(id);
    if (on) {
      await ref.set({'on': true, 'updatedAt': FieldValue.serverTimestamp()});
    } else {
      await ref.delete();
    }
  }

  @override
  Future<void> report({
    required String itemId,
    required String reason,
    required String note,
  }) async {
    await _db.collection('reports').add({
      'itemId': itemId,
      'userId': uid,
      'reason': reason,
      'note': note,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<int?> recordView(String itemId) async {
    return null;
  }
}

Item itemFromPublished(String id, Map<String, dynamic> data) {
  final source = data['primarySource'];
  final sourceMap = source is Map
      ? Map<String, dynamic>.from(source)
      : const <String, dynamic>{};
  final deeper = data['deeper'];
  final deeperMap = deeper is Map
      ? Map<String, dynamic>.from(deeper)
      : const <String, dynamic>{};
  final speech = data['speech'];
  final speechMap = speech is Map ? Map<String, dynamic>.from(speech) : null;
  final credit = data['imageCredit'];
  final creditMap = credit is Map ? Map<String, dynamic>.from(credit) : null;
  final year = sourceMap['year'];
  return Item(
    id: id,
    type: data['type'] as String? ?? 'quote',
    text: data['text'] as String? ?? '',
    author: data['authorName'] as String? ?? '',
    authorRole: data['authorRole'] as String? ?? '',
    field: _field(data['field'] as String?) ?? Field.other,
    moods: [
      for (final name in (data['moods'] as List?) ?? const [])
        if (_mood(name is String ? name : null) != null)
          _mood(name as String?)!,
    ],
    source: Source(
      title: sourceMap['title'] as String? ?? 'Source',
      year: year is num ? year.toInt() : null,
      url: (sourceMap['url'] as String?)?.isEmpty ?? true
          ? null
          : sourceMap['url'] as String?,
    ),
    verified: true,
    deeper: Deeper(
      context: deeperMap['context'] as String? ?? '',
      didYouKnow: deeperMap['didYouKnow'] as String? ?? '',
      takeaway: deeperMap['takeaway'] as String? ?? '',
      related: [
        for (final id in (data['related'] as List?) ?? const [])
          if (id is String) id,
      ],
    ),
    speech: speechMap == null
        ? null
        : SpeechMeta(
            durationSec: (speechMap['durationSec'] as num?)?.toInt() ?? 0,
            watchUrl: speechMap['watchUrl'] as String? ?? '',
          ),
    imageUrl: data['authorImageUrl'] as String?,
    imageCredit: creditMap == null
        ? null
        : ImageCredit(
            artist: creditMap['artist'] as String? ?? '',
            license: creditMap['license'] as String? ?? '',
            sourceUrl: creditMap['sourceUrl'] as String? ?? '',
          ),
  );
}

Field? _field(String? name) {
  for (final field in Field.values) {
    if (field.name == name) return field;
  }
  return null;
}

Mood? _mood(String? name) {
  for (final mood in Mood.values) {
    if (mood.name == name) return mood;
  }
  return null;
}
