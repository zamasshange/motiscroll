enum Field { sports, business, science, arts, leadership, resilience, other }

enum Mood {
  startingOver('Starting over'),
  badDay('Bad day'),
  needFocus('Need focus'),
  preWorkout('Pre-workout'),
  examStress('Exam stress'),
  feelingStuck('Feeling stuck');

  const Mood(this.label);
  final String label;
}

class FieldInfo {
  const FieldInfo(this.title, this.description);
  final String title;
  final String description;
}

const fieldInfo = <Field, FieldInfo>{
  Field.sports: FieldInfo(
    'Sports',
    'Effort, craft, and the nerve to begin again.',
  ),
  Field.business: FieldInfo(
    'Business',
    'Building, deciding, and staying with the work.',
  ),
  Field.science: FieldInfo(
    'Science',
    'Curiosity with the patience to be wrong.',
  ),
  Field.arts: FieldInfo(
    'Arts',
    'Making something that did not exist yesterday.',
  ),
  Field.leadership: FieldInfo(
    'Leadership',
    'The weight of choosing for more than yourself.',
  ),
  Field.resilience: FieldInfo(
    'Resilience',
    'How people continue when the day goes badly.',
  ),
  Field.other: FieldInfo('Other', 'Lines that do not sit in a single field.'),
};

const collectionFields = <Field>[
  Field.sports,
  Field.business,
  Field.science,
  Field.arts,
  Field.leadership,
  Field.resilience,
];

class Source {
  const Source({required this.title, this.year, this.url});
  final String title;
  final int? year;
  final String? url;

  String get line => year == null ? title : '$title, $year';
}

class Deeper {
  const Deeper({
    required this.context,
    required this.didYouKnow,
    required this.takeaway,
    required this.related,
  });

  final String context;
  final String didYouKnow;
  final String takeaway;
  final List<String> related;
}

class SpeechMeta {
  const SpeechMeta({required this.durationSec, required this.watchUrl});
  final int durationSec;
  final String watchUrl;
}

class ImageCredit {
  const ImageCredit({
    required this.artist,
    required this.license,
    required this.sourceUrl,
  });

  final String artist;
  final String license;
  final String sourceUrl;

  bool get requiresVisibleCredit => license.startsWith('CC');
}

class Item {
  const Item({
    required this.id,
    required this.type,
    required this.text,
    required this.author,
    required this.authorRole,
    required this.field,
    required this.moods,
    required this.source,
    required this.verified,
    required this.deeper,
    this.speech,
    this.imageUrl,
    this.imageCredit,
  });

  final String id;
  final String type;
  final String text;
  final String author;
  final String authorRole;
  final Field field;
  final List<Mood> moods;
  final Source source;
  final bool verified;
  final Deeper deeper;
  final SpeechMeta? speech;
  final String? imageUrl;
  final ImageCredit? imageCredit;

  bool get isSpeech => type == 'speech';

  String get durationLabel {
    final seconds = speech?.durationSec ?? 0;
    final minutes = (seconds / 60).round().clamp(1, 999);
    return 'about $minutes min';
  }
}

int hashString(String value) {
  var hash = 0;
  for (final code in value.codeUnits) {
    hash = (hash * 31 + code) & 0x7fffffff;
  }
  return hash;
}

String initialsFor(String author) {
  final parts = author
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty && RegExp(r'[A-Za-z]').hasMatch(part[0]))
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String dayKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
