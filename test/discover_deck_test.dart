import 'package:flutter_test/flutter_test.dart';
import 'package:moti_scroll/data/discover_deck.dart';
import 'package:moti_scroll/data/models.dart';

Item _item(String id, Field field) {
  return Item(
    id: id,
    type: 'quote',
    text: id,
    author: id,
    authorRole: '',
    field: field,
    moods: const [],
    source: const Source(title: 'Book'),
    verified: true,
    deeper: const Deeper(
      context: '',
      didYouKnow: '',
      takeaway: '',
      related: [],
    ),
  );
}

void main() {
  test('discover does not repeat an id in a session', () {
    final deck = DiscoverDeck();
    final followed = [_item('a', Field.arts), _item('b', Field.arts)];
    final other = [_item('a', Field.science), _item('c', Field.science)];
    final first = deck.take(followed: followed, other: other, count: 10);
    final ids = first.map((item) => item.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(ids, containsAll(['a', 'b', 'c']));
    final second = deck.take(followed: followed, other: other, count: 10);
    expect(second, isEmpty);
  });

  test('followed lines are the majority of a mixed page', () {
    final deck = DiscoverDeck();
    final followed = [
      for (var i = 0; i < 12; i++) _item('f$i', Field.leadership),
    ];
    final other = [for (var i = 0; i < 12; i++) _item('o$i', Field.science)];
    final page = deck.take(followed: followed, other: other, count: 10);
    final followedCount = page.where((item) => item.id.startsWith('f')).length;
    expect(followedCount, greaterThanOrEqualTo(6));
  });
}
