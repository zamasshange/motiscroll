import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import '../widgets/generated_cover.dart';

class _Path {
  const _Path({
    required this.title,
    required this.field,
    required this.seed,
    required this.items,
  });

  final String title;
  final Field field;
  final String seed;
  final List<Item> items;

  String get meta {
    final seconds = items.fold<int>(
      0,
      (sum, item) => sum + (item.speech?.durationSec ?? 45),
    );
    final mins = (seconds / 60).ceil().clamp(1, 999);
    final lines = items.length == 1 ? '1 line' : '${items.length} lines';
    return '$lines · about $mins min';
  }
}

class PathsScreen extends StatelessWidget {
  const PathsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = state.palette;
    final verified = state.items.where((item) => item.verified).toList();

    final byMood = [
      for (final mood in Mood.values)
        _Path(
          title: mood.label,
          field: Field.resilience,
          seed: mood.name,
          items: verified.where((item) => item.moods.contains(mood)).toList(),
        ),
    ].where((path) => path.items.isNotEmpty).toList();

    final byField = [
      for (final field in Field.values)
        _Path(
          title: fieldInfo[field]!.title,
          field: field,
          seed: 'field-${field.name}',
          items: verified.where((item) => item.field == field).toList(),
        ),
    ].where((path) => path.items.isNotEmpty).toList();

    final people = <String, List<Item>>{};
    for (final item in verified) {
      people.putIfAbsent(item.author, () => []).add(item);
    }
    final byPerson =
        [
            for (final entry in people.entries)
              _Path(
                title: entry.key,
                field: entry.value.first.field,
                seed: 'person-${entry.key}',
                items: entry.value,
              ),
          ].where((path) => path.items.length >= 3).toList()
          ..sort((a, b) => b.items.length.compareTo(a.items.length));

    final mood = state.usualMood;
    final current = mood == null
        ? null
        : byMood.where((path) => path.title == mood.label).firstOrNull;

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: Text('Paths', style: serif(palette, 32))),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: palette.border),
                      ),
                      child: Text(
                        'Done',
                        style: sans(palette, 15, weight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'YOUR PATH',
                style: sans(
                  palette,
                  12,
                  weight: FontWeight.w700,
                  color: palette.textFaint,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _CurrentPath(path: current),
            ),
            if (verified.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Paths appear once the library loads.',
                  textAlign: TextAlign.center,
                  style: sans(palette, 15, color: palette.textMuted),
                ),
              ),
            if (byField.length >= 2 || byMood.isNotEmpty)
              _StartRow(
                paths: [
                  for (final path in (byField.length >= 2
                      ? byField.take(2)
                      : [...byMood.take(1), ...byField.take(1)]))
                    _Path(
                      title: path.title,
                      field: path.field,
                      seed: '${path.seed}-start',
                      items: path.items.take(7).toList(),
                    ),
                ],
              ),
            if (byMood.isNotEmpty) _Section(title: 'By mood', paths: byMood),
            if (byField.isNotEmpty) _Section(title: 'By field', paths: byField),
            if (byPerson.isNotEmpty)
              _Section(title: 'In their own words', paths: byPerson),
          ],
        ),
      ),
    );
  }
}

void _open(BuildContext context, _Path path) {
  if (path.items.isEmpty) return;
  final state = AppScope.of(context);
  Navigator.of(context).pop();
  state.openInFeed(path.items.first.id);
}

class _CurrentPath extends StatelessWidget {
  const _CurrentPath({required this.path});

  final _Path? path;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    final path = this.path;
    return GestureDetector(
      onTap: path == null ? null : () => _open(context, path),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 84,
                height: 84,
                child: GeneratedCover(
                  field: path?.field ?? Field.resilience,
                  seed: path?.seed ?? 'paths-start',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    path == null ? 'Pick a path to begin' : path.title,
                    style: sans(palette, 18, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    path?.meta ??
                        'New here? The sections below are a place to start. No prior reading needed.',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: sans(palette, 13, color: palette.textMuted),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Browse paths',
                    style: sans(palette, 14, weight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            if (path != null)
              Icon(Icons.play_circle_fill_rounded, color: palette.accent),
          ],
        ),
      ),
    );
  }
}

class _StartRow extends StatelessWidget {
  const _StartRow({required this.paths});

  final List<_Path> paths;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    if (paths.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A PLACE TO START',
            style: sans(
              palette,
              12,
              weight: FontWeight.w700,
              color: palette.textFaint,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Short runs of real lines. Open one and it starts in Feed.',
            style: sans(palette, 14, color: palette.textMuted),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < paths.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: _StartCard(path: paths[i])),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StartCard extends StatelessWidget {
  const _StartCard({required this.path});

  final _Path path;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    final image = path.items
        .map((item) => item.imageUrl)
        .whereType<String>()
        .where((url) => url.isNotEmpty)
        .firstOrNull;
    return GestureDetector(
      onTap: () => _open(context, path),
      child: Container(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.15,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (image != null)
                    Image.network(
                      image,
                      fit: BoxFit.cover,
                      headers: imageHeaders,
                      errorBuilder: (context, error, stack) =>
                          GeneratedCover(field: path.field, seed: path.seed),
                    )
                  else
                    GeneratedCover(field: path.field, seed: path.seed),
                  Positioned(
                    top: 8,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      color: palette.text,
                      child: Text(
                        'START HERE',
                        style: sans(
                          palette,
                          10,
                          weight: FontWeight.w700,
                          color: palette.bg,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    path.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: sans(palette, 16, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    path.meta,
                    style: sans(palette, 12, color: palette.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.paths});

  final String title;
  final List<_Path> paths;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 10),
          child: Text(title, style: sans(palette, 20, weight: FontWeight.w700)),
        ),
        SizedBox(
          height: 228,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: paths.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) => _PathCard(path: paths[index]),
          ),
        ),
      ],
    );
  }
}

class _PathCard extends StatelessWidget {
  const _PathCard({required this.path});

  final _Path path;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return GestureDetector(
      onTap: () => _open(context, path),
      child: Container(
        width: 156,
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GeneratedCover(field: path.field, seed: path.seed),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    path.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: sans(palette, 15, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    path.meta,
                    style: sans(palette, 12, color: palette.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
