import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../firebase_options.dart';
import 'authors_page.dart';

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
  var _section = 0;

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _queue() async {
    final snap = await FirebaseFirestore.instance
        .collection('items')
        .where('status', isEqualTo: 'needs_review')
        .limit(30)
        .get();
    return snap.docs;
  }

  Future<void> _spotCheck() async {
    final docs = await _queue();
    docs.shuffle();
    final sample = docs.take(5).toList();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Spot-check sample'),
        content: SizedBox(
          width: 480,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final doc in sample) ...[
                Text(doc.data()['text'] as String? ?? ''),
                const SizedBox(height: 8),
                FutureBuilder(
                  future: doc.reference.collection('sources').get(),
                  builder: (context, snapshot) {
                    final sources = snapshot.data?.docs ?? const [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final source in sources)
                          TextButton(
                            onPressed: () {
                              final url = source.data()['url'] as String? ?? '';
                              final uri = Uri.tryParse(url);
                              if (uri != null) {
                                launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
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
                const Divider(),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveBatch() async {
    try {
      final docs = await _queue();
      final ids = docs.take(25).map((doc) => doc.id).toList();
      final result = await FirebaseFunctions.instance
          .httpsCallable('approveBatch')
          .call({'itemIds': ids});
      final data = result.data;
      final skipped = data is Map ? data['skipped'] : null;
      setState(() {
        _message = skipped is List && skipped.isNotEmpty
            ? 'Some lines were skipped. Compare the spot-check sample with the original before trying again.'
            : 'The batch was approved.';
      });
    } on FirebaseFunctionsException {
      setState(() {
        _message = 'The batch could not be approved. Spot-check the sources and try again.';
      });
    }
  }

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
      appBar: AppBar(title: Text(_section == 0 ? 'Review' : 'Authors')),
      bottomNavigationBar: user == null
          ? null
          : NavigationBar(
              selectedIndex: _section,
              onDestinationSelected: (index) =>
                  setState(() => _section = index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.fact_check_outlined),
                  label: 'Review',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  label: 'Authors',
                ),
              ],
            ),
      body: user == null
          ? Center(
              child: FilledButton(
                onPressed: _signIn,
                child: const Text('Sign in'),
              ),
            )
          : _section == 1
          ? const AuthorsPage()
          : Column(
              children: [
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_message!),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Row(
                    children: [
                      OutlinedButton(
                        onPressed: _spotCheck,
                        child: const Text('Spot-check sample'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _approveBatch,
                        child: const Text('Approve batch'),
                      ),
                    ],
                  ),
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
                            launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
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
