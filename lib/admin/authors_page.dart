import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthorsPage extends StatefulWidget {
  const AuthorsPage({super.key});

  @override
  State<AuthorsPage> createState() => _AuthorsPageState();
}

class _AuthorsPageState extends State<AuthorsPage> {
  String _field = 'all';
  String _era = 'all';
  String _track = 'all';
  var _needsQuotes = false;
  var _loading = true;
  String? _error;
  List<_AuthorRow> _rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final authors = await FirebaseFirestore.instance
          .collection('authors')
          .get();
      final published = await FirebaseFirestore.instance
          .collection('publishedItems')
          .get();
      final counts = <String, int>{};
      for (final doc in published.docs) {
        final authorId = doc.data()['authorId'] as String? ?? '';
        if (authorId.isEmpty) continue;
        counts[authorId] = (counts[authorId] ?? 0) + 1;
      }
      final rows = [
        for (final doc in authors.docs)
          _AuthorRow(
            id: doc.id,
            data: doc.data(),
            published: counts[doc.id] ?? 0,
          ),
      ]..sort((a, b) => a.name.compareTo(b.name));
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message ?? 'The author list could not be opened.';
        _loading = false;
      });
    }
  }

  List<_AuthorRow> get _visible {
    return _rows.where((row) {
      if (_field != 'all' && row.field != _field) return false;
      if (_era != 'all' && row.era != _era) return false;
      if (_track != 'all' && !row.tracks.contains(_track)) return false;
      if (_needsQuotes && row.published > 0) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Filter(
                label: 'Field',
                value: _field,
                choices: const [
                  'all',
                  'leadership',
                  'science',
                  'business',
                  'sports',
                  'arts',
                  'resilience',
                ],
                onChanged: (value) => setState(() => _field = value),
              ),
              _Filter(
                label: 'Era',
                value: _era,
                choices: const ['all', '20th', 'modern'],
                onChanged: (value) => setState(() => _era = value),
              ),
              _Filter(
                label: 'Track',
                value: _track,
                choices: const [
                  'all',
                  'public_domain',
                  'wikiquote_candidates',
                  'manual_curation',
                ],
                onChanged: (value) => setState(() => _track = value),
              ),
              FilterChip(
                label: const Text('Needs quotes'),
                selected: _needsQuotes,
                onSelected: (value) => setState(() => _needsQuotes = value),
              ),
            ],
          ),
        ),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_error != null)
          Expanded(child: Center(child: Text(_error!)))
        else
          Expanded(
            child: ListView(
              children: [
                for (final row in visible)
                  ListTile(
                    title: Text(row.name),
                    subtitle: Text(
                      '${row.field} · ${row.era} · ${row.tracks.join(', ')} · ${row.published} published',
                    ),
                    trailing: row.published == 0
                        ? TextButton(
                            onPressed: () => _addManual(row),
                            child: const Text('Add a manual line'),
                          )
                        : Text('${row.published}'),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _addManual(_AuthorRow row) async {
    final text = TextEditingController();
    final source = TextEditingController();
    final page = TextEditingController();
    final url = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(row.name),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: text,
                decoration: const InputDecoration(labelText: 'Exact line'),
                minLines: 2,
                maxLines: 5,
              ),
              TextField(
                controller: source,
                decoration: const InputDecoration(labelText: 'Original source'),
              ),
              TextField(
                controller: page,
                decoration: const InputDecoration(
                  labelText: 'Page or timestamp',
                ),
              ),
              TextField(
                controller: url,
                decoration: const InputDecoration(labelText: 'Source URL'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save draft'),
          ),
        ],
      ),
    );
    if (saved != true || !mounted) return;
    final line = text.text.trim();
    final sourceTitle = source.text.trim();
    final location = page.text.trim();
    if (line.isEmpty || sourceTitle.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A manual line needs the quote, the source, and a page or timestamp.',
          ),
        ),
      );
      return;
    }
    final id = 'manual-${row.id}-${DateTime.now().millisecondsSinceEpoch}';
    final item = FirebaseFirestore.instance.collection('items').doc(id);
    await item.set({
      'text': line,
      'authorId': row.id,
      'field': row.field,
      'type': 'quote',
      'status': 'draft',
      'language': 'en',
      'verified': false,
      'discoveredVia': 'manual_entry',
      'moods': <String>[],
      'wordCount': line
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .length,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await item.collection('sources').doc('primary').set({
      'title': sourceTitle,
      'url': url.text.trim(),
      'pageOrTimestamp': location,
      'sourceType': 'primary',
      'confidence': 'confirmed',
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved as a draft. It is not published.')),
    );
  }
}

class _AuthorRow {
  _AuthorRow({required this.id, required this.data, required this.published});

  final String id;
  final Map<String, dynamic> data;
  final int published;

  String get name => data['name'] as String? ?? id;
  String get field => data['field'] as String? ?? '';
  String get era => data['era'] as String? ?? '';
  List<String> get tracks => [
    for (final track in (data['sourcingTrack'] as List?) ?? const [])
      if (track is String) track,
  ];
}

class _Filter extends StatelessWidget {
  const _Filter({
    required this.label,
    required this.value,
    required this.choices,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> choices;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: value,
      items: [
        for (final choice in choices)
          DropdownMenuItem(value: choice, child: Text('$label: $choice')),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}
