import 'models.dart';

/// Interleaves followed fields at about 60% and skips ids already seen.
class DiscoverDeck {
  DiscoverDeck({this.followedRatio = 0.6});

  final double followedRatio;
  final seen = <String>{};

  List<Item> take({
    required List<Item> followed,
    required List<Item> other,
    int count = 20,
  }) {
    final freshFollowed = followed
        .where((item) => !seen.contains(item.id))
        .toList();
    final freshOther = other.where((item) => !seen.contains(item.id)).toList();
    final result = <Item>[];
    var a = 0;
    var b = 0;
    while (result.length < count &&
        (a < freshFollowed.length || b < freshOther.length)) {
      final wantFollowed = result.length < (count * followedRatio).ceil();
      Item? next;
      if (wantFollowed && a < freshFollowed.length) {
        next = freshFollowed[a];
        a += 1;
      } else if (b < freshOther.length) {
        next = freshOther[b];
        b += 1;
      } else if (a < freshFollowed.length) {
        next = freshFollowed[a];
        a += 1;
      }
      if (next == null || !seen.add(next.id)) continue;
      result.add(next);
    }
    return result;
  }
}
