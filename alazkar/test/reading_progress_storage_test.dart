import 'package:alazkar/src/features/zikr_content_viewer/data/repository/reading_progress_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_storage.dart';

void main() {
  late MemoryStorage box;
  late DateTime now;
  late ReadingProgressStorage storage;

  setUp(() {
    box = MemoryStorage();
    now = DateTime(2026, 10, 15, 8);
    storage = ReadingProgressStorage(box, now: () => now);
  });

  test('progress written today is read back today', () async {
    await storage.write(
      7,
      const ReadingProgress(counts: {12: 3, 13: 0}, zikrId: 12),
    );
    now = DateTime(2026, 10, 15, 23, 59);

    final progress = storage.read(7);

    expect(progress?.counts, {12: 3, 13: 0});
    expect(progress?.zikrId, 12);
    expect(storage.read(8), isNull);
  });

  test('progress written yesterday reads as nothing, and is removed', () async {
    now = DateTime(2026, 10, 14, 23, 59);
    await storage.write(7, const ReadingProgress(counts: {12: 3}, zikrId: 12));
    now = DateTime(2026, 10, 15, 0, 1);

    expect(storage.read(7), isNull);
    expect(box.hasData('reading_progress_7'), isFalse);
  });

  test('a corrupt value reads as nothing and does not throw', () async {
    for (final value in [
      'not json',
      '[1, 2]',
      '{"day":"2026-10-15","counts":[3]}',
      '{"day":"2026-10-15","counts":{"x":3}}',
      '{"day":42,"counts":{}}',
      42,
    ]) {
      await box.write('reading_progress_7', value);

      expect(storage.read(7), isNull, reason: '$value');
    }
  });

  test('clear removes the progress', () async {
    await storage.write(7, const ReadingProgress(counts: {12: 3}));

    await storage.clear(7);

    expect(storage.read(7), isNull);
    expect(box.hasData('reading_progress_7'), isFalse);
  });
}
