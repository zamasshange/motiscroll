import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/fake_repository.dart';
import 'support/ui_fixture.dart';

void main() {
  test('lib does not import the fake repository or a mock catalog', () {
    final hits = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final text = entity.readAsStringSync();
      if (text.contains('LocalItemRepository') ||
          text.contains('kItems') ||
          text.contains('placeholder-13') ||
          text.contains('test/support/fake_repository.dart') ||
          text.contains('ui_fixture.dart')) {
        hits.add(entity.path);
      }
    }
    expect(hits, isEmpty);
  });

  test('the fake repository is only available to tests', () async {
    final page = await LocalItemRepository(uiFixture()).page();
    expect(page.items, hasLength(2));
  });
}
