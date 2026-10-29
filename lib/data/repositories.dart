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

  Future<Map<Field, int>> collectionCounts();

  Future<List<AuthorProfile>> authors();

  /// A short server read so the home screen can draw before the full library.
  Future<PageChunk> previewOpening() async => const PageChunk([]);
}

abstract class UserDirectory {
  Future<void> ensureProfile({
    required Set<Field> fields,
    required Mood? mood,
    required String timezone,
    required Map<String, Object?> notifications,
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

  Future<void> feedback({required String topic, required String message});

  Future<void> setLanguages({
    String? contentLanguage,
    String? uiLanguage,
    String? secondLanguage,
  });
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
    if (!more && field == null && mood == null) {
      final snap = await _db
          .collection('publishedItems')
          .limit(catalogPageSize)
          .get();
      return PageChunk(rotateAuthors(_itemsFrom(snap)));
    }
    if (!more) _cursor = null;
    late QuerySnapshot<Map<String, dynamic>> snap;
    try {
      Query<Map<String, dynamic>> query = _db.collection('publishedItems');
      if (field != null) query = query.where('field', isEqualTo: field.name);
      if (mood != null) query = query.where('moods', arrayContains: mood.name);
      query = query.orderBy('rand').limit(limit);
      final cursor = _cursor;
      if (more && cursor != null) query = query.startAfterDocument(cursor);
      snap = await query.get();
    } on FirebaseException catch (error) {
      if (error.code != 'failed-precondition' || more) rethrow;
      snap = await _db.collection('publishedItems').limit(limit).get();
    }
    if (snap.docs.isNotEmpty) _cursor = snap.docs.last;
    return PageChunk(rotateAuthors(_itemsFrom(snap)));
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

  @override
  Future<Map<Field, int>> collectionCounts() async {
    final snap = await _db.collection('collections').get();
    final counts = <Field, int>{};
    for (final doc in snap.docs) {
      final field = _field(doc.id);
      final count = doc.data()['itemCount'];
      if (field != null && count is num) counts[field] = count.toInt();
    }
    return counts;
  }

  @override
  Future<List<AuthorProfile>> authors() async {
    final snap = await _db.collection('publishedAuthors').get();
    final profiles = <AuthorProfile>[];
    for (final doc in snap.docs) {
      final profile = authorFromPublished(doc.id, doc.data());
      if (profile != null) profiles.add(profile);
    }
    return profiles;
  }

  @override
  Future<PageChunk> previewOpening() async {
    final snap = await _db.collection('publishedItems').limit(48).get();
    return PageChunk(rotateAuthors(_itemsFrom(snap)));
  }

  Future<List<Item>> _randPage(double start, {List<String>? whereIn}) async {
    Query<Map<String, dynamic>> query = _db.collection('publishedItems');
    if (whereIn != null && whereIn.isNotEmpty) {
      query = query.where('field', whereIn: whereIn.take(10).toList());
    }
    late QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await query
          .where('rand', isGreaterThanOrEqualTo: start)
          .orderBy('rand')
          .limit(20)
          .get();
    } on FirebaseException catch (error) {
      if (error.code != 'failed-precondition') rethrow;
      snap = await _db.collection('publishedItems').limit(20).get();
    }
    return rotateAuthors(_itemsFrom(snap));
  }

  List<Item> _itemsFrom(QuerySnapshot<Map<String, dynamic>> snap) {
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
    required Map<String, Object?> notifications,
  }) async {
    await _user.set({
      'onboardingDone': true,
      'timezone': timezone,
      'usualMood': mood?.name,
      'selectedFields': fields.map((field) => field.name).toList(),
      ...notifications,
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

  @override
  Future<void> feedback({
    required String topic,
    required String message,
  }) async {
    await _db.collection('feedback').add({
      'userId': uid,
      'topic': topic,
      'message': message,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> setLanguages({
    String? contentLanguage,
    String? uiLanguage,
    String? secondLanguage,
  }) async {
    await _user.set({
      'contentLanguage': contentLanguage ?? FieldValue.delete(),
      'uiLanguage': uiLanguage ?? FieldValue.delete(),
      'secondLanguage': secondLanguage ?? FieldValue.delete(),
    }, SetOptions(merge: true));
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
    text: decodeText(data['text'] as String? ?? ''),
    author: decodeText(data['authorName'] as String? ?? ''),
    authorRole: decodeText(data['authorRole'] as String? ?? ''),
    field: _field(data['field'] as String?) ?? Field.other,
    moods: [
      for (final name in (data['moods'] as List?) ?? const [])
        if (_mood(name is String ? name : null) != null)
          _mood(name as String?)!,
    ],
    source: Source(
      title: decodeText(sourceMap['title'] as String? ?? 'Source'),
      year: year is num ? year.toInt() : null,
      url: (sourceMap['url'] as String?)?.isEmpty ?? true
          ? null
          : sourceMap['url'] as String?,
    ),
    verified: true,
    deeper: Deeper(
      context: decodeText(deeperMap['context'] as String? ?? ''),
      didYouKnow: decodeText(deeperMap['didYouKnow'] as String? ?? ''),
      takeaway: decodeText(deeperMap['takeaway'] as String? ?? ''),
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
    isTranslated: data['isTranslated'] == true,
    imageUrl: data['authorImageUrl'] as String?,
    imageCredit: creditMap == null
        ? null
        : ImageCredit(
            artist: decodeText(creditMap['artist'] as String? ?? ''),
            license: creditMap['license'] as String? ?? '',
            sourceUrl: creditMap['sourceUrl'] as String? ?? '',
          ),
  );
}

AuthorProfile? authorFromPublished(String id, Map<String, dynamic> data) {
  final name = data['name'] as String? ?? '';
  final field = _field(data['field'] as String?);
  if (name.isEmpty || field == null) return null;
  final credit = data['imageCredit'];
  final creditMap = credit is Map ? Map<String, dynamic>.from(credit) : null;
  final imageUrl = data['imageUrl'] as String?;
  return AuthorProfile(
    id: id,
    name: decodeText(name),
    role: decodeText(data['role'] as String? ?? ''),
    field: field,
    bornYear: (data['bornYear'] as num?)?.toInt(),
    diedYear: (data['diedYear'] as num?)?.toInt(),
    isLiving: data['isLiving'] as bool? ?? false,
    imageUrl: imageUrl == null || imageUrl.isEmpty ? null : imageUrl,
    imageCredit: creditMap == null
        ? null
        : ImageCredit(
            artist: decodeText(creditMap['artist'] as String? ?? ''),
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
