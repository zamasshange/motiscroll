import 'package:moti_scroll/data/models.dart';

/// UI-only lines for widget tests. The app does not import this file.
List<Item> uiFixture() {
  return [
    Item(
      id: 'fixture-quote',
      type: 'quote',
      text: 'A fixture line for the home screen test.',
      author: 'Fixture',
      authorRole: 'Test',
      field: Field.leadership,
      moods: const [Mood.needFocus],
      source: const Source(title: 'Test source', year: 2000),
      verified: true,
      deeper: const Deeper(
        context: 'Fixture context',
        didYouKnow: 'Fixture note',
        takeaway: 'Fixture takeaway',
        related: [],
      ),
    ),
    Item(
      id: 'fixture-speech',
      type: 'speech',
      text: 'A fixture speech line for the home screen test.',
      author: 'Fixture',
      authorRole: 'Test',
      field: Field.leadership,
      moods: const [Mood.needFocus],
      source: const Source(title: 'Test speech', year: 2000),
      verified: true,
      deeper: const Deeper(
        context: 'Fixture context',
        didYouKnow: 'Fixture note',
        takeaway: 'Fixture takeaway',
        related: [],
      ),
      speech: const SpeechMeta(
        durationSec: 60,
        watchUrl: 'https://example.com',
      ),
    ),
  ];
}
