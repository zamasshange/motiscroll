import 'models.dart';

/// First read of the published library. Large enough to hold the
/// public-domain lines and the quote lists together.
const catalogPageSize = 6000;

const quoteListHosts = [
  'goodreads.com',
  'rd.com',
  'brainyquote.com',
  'ef.com',
  'shakespeare.org.uk',
  'forbes.com',
  'addicted2success.com',
  'my-picture.co.uk',
];

bool fromQuoteList(String? url) {
  if (url == null || url.isEmpty) return false;
  return quoteListHosts.any(url.contains);
}

Item? itemById(String id, List<Item> source) {
  for (final item in source) {
    if (item.id == id) return item;
  }
  return null;
}

int countForField(Field field, List<Item> source) =>
    source.where((item) => item.field == field).length;

List<Item> discoverOrder(Set<Field> followed, List<Item> source) {
  final first = source.where((item) => followed.contains(item.field)).toList();
  final rest = source.where((item) => !followed.contains(item.field)).toList();
  return [...rotateAuthors(first), ...rotateAuthors(rest)];
}

/// A new order each visit. The same line never appears twice, and
/// every author gets a turn before anyone repeats. A line longer than
/// [maxLineLength] is left out: on the feed it shrinks into a paragraph.
const maxLineLength = 120;

List<Item> freshDeck(List<Item> items, int seed) {
  final seenIds = <String>{};
  final seenText = <String>{};
  final unique = <Item>[];
  for (final item in items) {
    if (!seenIds.add(item.id)) continue;
    final text = item.text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty || text.length > maxLineLength || !seenText.add(text)) {
      continue;
    }
    unique.add(item);
  }
  final groups = <String, List<Item>>{};
  for (final item in unique) {
    groups.putIfAbsent(item.author, () => []).add(item);
  }
  final names = groups.keys.toList();
  _shuffle(names, seed);
  for (final name in names) {
    _shuffle(groups[name]!, seed ^ hashString(name));
  }
  final mixed = <Item>[];
  var pending = true;
  while (pending) {
    pending = false;
    for (final name in names) {
      final bucket = groups[name]!;
      if (bucket.isEmpty) continue;
      mixed.add(bucket.removeAt(0));
      pending = true;
    }
  }
  return mixed;
}

void _shuffle(List<Object> list, int seed) {
  var state = seed & 0x7fffffff;
  if (state == 0) state = 1;
  int next() {
    state = (1664525 * state + 1013904223) & 0x7fffffff;
    return state;
  }

  for (var i = list.length - 1; i > 0; i--) {
    final j = next() % (i + 1);
    final swap = list[i];
    list[i] = list[j];
    list[j] = swap;
  }
}

/// Gives every author a turn before anyone repeats, so one person
/// cannot fill the feed. The author order and each author's lines
/// change with the calendar day.
List<Item> dayRotate(List<Item> items, DateTime now) {
  final day = dayKey(now);
  final groups = <String, List<Item>>{};
  for (final item in items) {
    groups.putIfAbsent(item.author, () => []).add(item);
  }
  final buckets = groups.entries.toList()
    ..sort(
      (a, b) => hashString(
        '$day:${a.key}',
      ).compareTo(hashString('$day:${b.key}')),
    );
  for (final bucket in buckets) {
    bucket.value.sort(
      (a, b) => hashString(
        '$day:${a.id}',
      ).compareTo(hashString('$day:${b.id}')),
    );
  }
  final mixed = <Item>[];
  var pending = true;
  while (pending) {
    pending = false;
    for (final bucket in buckets) {
      if (bucket.value.isEmpty) continue;
      mixed.add(bucket.value.removeAt(0));
      pending = true;
    }
  }
  return mixed;
}

/// Gives every author a turn before anyone repeats, so one person
/// cannot fill the feed.
List<Item> rotateAuthors(List<Item> items) {
  final groups = <String, List<Item>>{};
  for (final item in items) {
    groups.putIfAbsent(item.author, () => []).add(item);
  }
  final buckets = groups.values.toList();
  final mixed = <Item>[];
  var pending = true;
  while (pending) {
    pending = false;
    for (final bucket in buckets) {
      if (bucket.isEmpty) continue;
      mixed.add(bucket.removeAt(0));
      pending = true;
    }
  }
  return mixed;
}

class DailyPicks {
  const DailyPicks({
    required this.quote,
    required this.speech,
    required this.boost,
  });
  final Item quote;
  final Item? speech;
  final Item boost;
}

DailyPicks? dailyPicks(DateTime now, Mood? mood, List<Item> source) {
  if (source.isEmpty) return null;
  final quotes = _pool(source.where((item) => !item.isSpeech), mood);
  if (quotes.isEmpty) return null;
  final speeches = _pool(source.where((item) => item.isSpeech), mood);
  final quote = _pick(quotes, now, 'quote', pictured: true, maxLength: maxLineLength);
  var boost = _pick(quotes, now, 'boost', pictured: true, maxLength: maxLineLength);
  if (boost.id == quote.id && quotes.length > 1) {
    final next = (quotes.indexOf(quote) + 1) % quotes.length;
    for (var step = 0; step < quotes.length; step++) {
      final item = quotes[(next + step) % quotes.length];
      if (item.id == quote.id) continue;
      final url = item.imageUrl;
      if (url != null && url.isNotEmpty) {
        boost = item;
        break;
      }
      boost = item;
    }
  }
  return DailyPicks(
    quote: quote,
    speech: speeches.isEmpty ? null : _pick(speeches, now, 'speech'),
    boost: boost,
  );
}

List<Item> _pool(Iterable<Item> source, Mood? mood) {
  final verified = source.where((item) => item.verified).toList();
  final base = verified.isEmpty ? source.toList() : verified;
  if (mood == null) return base;
  final matched = base.where((item) => item.moods.contains(mood)).toList();
  return matched.isEmpty ? base : matched;
}

Item _pick(
  List<Item> items,
  DateTime now,
  String salt, {
  bool pictured = false,
  int? maxLength,
}) {
  var pool = items;
  if (maxLength != null) {
    final short = items.where((item) {
      final length = item.text.trim().length;
      return length >= 24 && length <= maxLength;
    }).toList();
    if (short.isNotEmpty) {
      pool = short;
    } else {
      final sorted = [...items]
        ..sort((a, b) => a.text.length.compareTo(b.text.length));
      pool = sorted.take(24).toList();
    }
  }
  if (pool.isEmpty) return items.first;
  pool = [...pool]..sort((a, b) => a.id.compareTo(b.id));
  final start = hashString('${dayKey(now)}:$salt') % pool.length;
  if (pictured) {
    for (var step = 0; step < pool.length; step++) {
      final item = pool[(start + step) % pool.length];
      final url = item.imageUrl;
      if (url != null && url.isNotEmpty) return item;
    }
  }
  return pool[start];
}
