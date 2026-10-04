import 'package:alazkar/src/features/quran/data/models/verse_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a surah read from its first verse is headed by the basmala', () {
    expect(const VerseRange(113, 1, 113, 5).opensWithBasmala, isTrue);
    expect(const VerseRange(67, 1, 67, 30).opensWithBasmala, isTrue);
  });

  test('a passage from the middle of a surah has no basmala', () {
    expect(const VerseRange(2, 255, 2, 255).opensWithBasmala, isFalse);
    expect(const VerseRange(2, 201, 2, 201).opensWithBasmala, isFalse);
    expect(const VerseRange(9, 129, 9, 129).opensWithBasmala, isFalse);
  });

  test('al-Fatiha and at-Tawbah get no added basmala', () {
    expect(const VerseRange(1, 1, 1, 7).opensWithBasmala, isFalse);
    expect(const VerseRange(9, 1, 9, 5).opensWithBasmala, isFalse);
  });
}
