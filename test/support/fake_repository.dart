import 'package:moti_scroll/data/catalog.dart';
import 'package:moti_scroll/data/discover_deck.dart';
import 'package:moti_scroll/data/models.dart';
import 'package:moti_scroll/data/repositories.dart';

class LocalItemRepository implements ItemRepository {
  LocalItemRepository(this.items, {this.profiles = const []});

  final List<Item> items;
  final List<AuthorProfile> profiles;

  @override
  Future<List<AuthorProfile>> authors() async => profiles;

  @override
  Future<PageChunk> page({
    Field? field,
    Mood? mood,
    bool more = false,
    int limit = 20,
  }) async {
    if (more) return const PageChunk([]);
    final filtered = items.where((item) {
      if (field != null && item.field != field) return false;
      if (mood != null && !item.moods.contains(mood)) return false;
      return true;
    }).toList();
    return PageChunk(filtered);
  }

  @override
  Future<Item?> byId(String id) async => itemById(id, items);

  @override
  Future<Item?> quoteOfDay(DateTime day) async =>
      dailyPicks(day, null, items)?.quote;

  @override
  Future<PageChunk> discover({
    required Set<Field> followed,
    required DiscoverDeck deck,
    int limit = 20,
  }) async {
    return PageChunk(discoverOrder(followed, items));
  }

  @override
  Future<Map<Field, int>> collectionCounts() async {
    return {
      for (final field in Field.values)
        field: items.where((item) => item.field == field).length,
    };
  }
}
