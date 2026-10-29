import 'package:cloud_firestore/cloud_firestore.dart';

/// The first lines for home. A copy already on the phone is used immediately.
/// The server is asked only when that copy is missing.
Future<QuerySnapshot<Map<String, dynamic>>> openingSnapshot(
  FirebaseFirestore db,
) async {
  final query = db.collection('publishedItems').limit(48);
  try {
    final cached = await query.get(const GetOptions(source: Source.cache));
    if (cached.docs.isNotEmpty) return cached;
  } on Object {
    // The phone has no Firestore copy yet.
  }
  return query.get();
}
