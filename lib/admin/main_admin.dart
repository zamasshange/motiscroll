import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../firebase_options.dart';

/// Editor queue. Run with `flutter run -t lib/admin/main_admin.dart`.
/// The signed-in user needs the custom claim `editor: true`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AdminQueue(),
    );
  }
}

class AdminQueue extends StatefulWidget {
  const AdminQueue({super.key});

  @override
  State<AdminQueue> createState() => _AdminQueueState();
}

class _AdminQueueState extends State<AdminQueue> {
  String? _message;

  Future<void> _signIn() async {
    await FirebaseAuth.instance.signInWithProvider(GoogleAuthProvider());
    final token = await FirebaseAuth.instance.currentUser?.getIdTokenResult(
      true,
    );
    setState(() {
      _message = token?.claims?['editor'] == true
          ? null
          : 'This account does not have the editor claim.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: user == null
          ? Center(
              child: FilledButton(
                onPressed: _signIn,
                child: const Text('Sign in'),
              ),
            )
          : Column(
              children: [
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_message!),
                  ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('items')
                        .where('status', isEqualTo: 'needs_review')
                        .limit(30)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final docs = snapshot.data?.docs ?? const [];
                      if (docs.isEmpty) {
                        return const Center(child: Text('Nothing is waiting.'));
                      }
                      return ListView(
                        children: [
                          for (final doc in docs)
                            _ReviewCard(id: doc.id, data: doc.data()),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _ReviewCard extends StatefulWidget {
  const _ReviewCard({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  List<String> _errors = const [];
  var _reason = '';

  Future<void> _preview() async {
    final result = await FirebaseFunctions.instance
        .httpsCallable('previewApproval')
        .call({'itemId': widget.id});
    final data = result.data;
    final errors = data is Map && data['errors'] is List
        ? (data['errors'] as List).map((e) => '$e').toList()
        : <String>[];
    setState(() => _errors = errors);
  }

  Future<void> _approve() async {
    await FirebaseFunctions.instance.httpsCallable('approveItem').call({
      'itemId': widget.id,
      'longQuoteOverrideReason': _reason,
    });
  }

  Future<void> _reject() async {
    await FirebaseFunctions.instance.httpsCallable('rejectItem').call({
      'itemId': widget.id,
      'reason': _reason.isEmpty ? 'Rejected in review' : _reason,
    });
  }

  @override
  Widget build(BuildContext context) {
    final warnings = (widget.data['warnings'] as List?)?.join(', ') ?? '';
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.data['text'] as String? ?? '',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(widget.data['authorId'] as String? ?? ''),
            if (warnings.isNotEmpty) Text('Warnings: $warnings'),
            if ((widget.data['sourceHint'] as String?)?.isNotEmpty ?? false)
              Text('Source hint: ${widget.data['sourceHint']}'),
            TextButton(
              onPressed: _preview,
              child: const Text('Check what is blocking approval'),
            ),
            for (final error in _errors) Text(error),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Override reason or rejection reason',
              ),
              onChanged: (value) => _reason = value,
            ),
            FutureBuilder(
              future: FirebaseFirestore.instance
                  .collection('items')
                  .doc(widget.id)
                  .collection('sources')
                  .get(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? const [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final source in docs)
                      TextButton(
                        onPressed: () {
                          final url = source.data()['url'] as String? ?? '';
                          final uri = Uri.tryParse(url);
                          if (uri != null) {
                            launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Text(
                          'Open original: ${source.data()['title'] ?? source.id}',
                        ),
                      ),
                  ],
                );
              },
            ),
            Row(
              children: [
                FilledButton(onPressed: _approve, child: const Text('Approve')),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: _reject, child: const Text('Reject')),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    FirebaseFirestore.instance
                        .collection('items')
                        .doc(widget.id)
                        .collection('deeper')
                        .doc('main')
                        .set({
                          'humanReviewed': true,
                          'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
                        }, SetOptions(merge: true));
                  },
                  child: const Text('Mark deeper reviewed'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
