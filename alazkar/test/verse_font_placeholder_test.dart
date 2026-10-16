import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _verseFont = 'assets/fonts/UthmanicHafs_v2-1.ttf';
const _placeholderGlyph = 'uni0602';
final _verseSpan = RegExp('﴿(.*?)﴾');

/// The Hafs font draws a dotted circle for every codepoint whose glyph is
/// [_placeholderGlyph] or built from it, so none of them may reach a verse.
class _PlaceholderCodepoints {
  final ByteData _font;
  final Map<String, int> _tables = {};

  _PlaceholderCodepoints(Uint8List bytes)
      : _font = ByteData.sublistView(bytes) {
    final tableCount = _font.getUint16(4);
    for (var i = 0; i < tableCount; i++) {
      final record = 12 + i * 16;
      final tag = String.fromCharCodes(bytes.sublist(record, record + 4));
      _tables[tag] = _font.getUint32(record + 8);
    }
  }

  Set<int> find() {
    final placeholder = _glyphNames().indexOf(_placeholderGlyph);
    expect(placeholder, isNot(-1), reason: '$_placeholderGlyph not in font');
    final glyphs = _glyphOffsets();
    bool drawsPlaceholder(int glyph) =>
        glyph == placeholder ||
        _components(glyphs[glyph], glyphs[glyph + 1]).any(drawsPlaceholder);

    return {
      for (final entry in _codepointGlyphs().entries)
        if (drawsPlaceholder(entry.value)) entry.key,
    };
  }

  int get _glyphCount => _font.getUint16(_tables['maxp']! + 4);

  List<String> _glyphNames() {
    final post = _tables['post']!;
    expect(_font.getUint32(post), 0x00020000, reason: 'post format 2.0');
    final count = _font.getUint16(post + 32);
    final indexes = [
      for (var i = 0; i < count; i++) _font.getUint16(post + 34 + i * 2),
    ];
    final customCount = indexes.reduce((a, b) => a > b ? a : b) - 257;
    final custom = <String>[];
    var offset = post + 34 + count * 2;
    while (custom.length < customCount) {
      final length = _font.getUint8(offset);
      custom.add(String.fromCharCodes(
        _font.buffer.asUint8List(_font.offsetInBytes + offset + 1, length),
      ));
      offset += length + 1;
    }
    return indexes.map((i) => i < 258 ? '' : custom[i - 258]).toList();
  }

  List<int> _glyphOffsets() {
    final glyf = _tables['glyf']!;
    final loca = _tables['loca']!;
    final longOffsets = _font.getInt16(_tables['head']! + 50) == 1;
    return [
      for (var i = 0; i <= _glyphCount; i++)
        glyf +
            (longOffsets
                ? _font.getUint32(loca + i * 4)
                : _font.getUint16(loca + i * 2) * 2),
    ];
  }

  List<int> _components(int start, int end) {
    if (end <= start || _font.getInt16(start) >= 0) return const [];
    final components = <int>[];
    var offset = start + 10;
    int flags;
    do {
      flags = _font.getUint16(offset);
      components.add(_font.getUint16(offset + 2));
      offset += 4 + (flags & 0x0001 != 0 ? 4 : 2);
      if (flags & 0x0008 != 0) {
        offset += 2;
      } else if (flags & 0x0040 != 0) {
        offset += 4;
      } else if (flags & 0x0080 != 0) {
        offset += 8;
      }
    } while (flags & 0x0020 != 0);
    return components;
  }

  Map<int, int> _codepointGlyphs() {
    final cmap = _tables['cmap']!;
    int? subtable;
    for (var i = 0; i < _font.getUint16(cmap + 2); i++) {
      final record = cmap + 4 + i * 8;
      if (_font.getUint16(record) == 3 && _font.getUint16(record + 2) == 1) {
        subtable = cmap + _font.getUint32(record + 4);
      }
    }
    expect(subtable, isNotNull, reason: 'Windows Unicode BMP cmap');
    expect(_font.getUint16(subtable!), 4, reason: 'cmap format 4');

    final segments = _font.getUint16(subtable + 6) ~/ 2;
    final ends = subtable + 14;
    final starts = ends + segments * 2 + 2;
    final deltas = starts + segments * 2;
    final rangeOffsets = deltas + segments * 2;
    final glyphs = <int, int>{};
    for (var s = 0; s < segments; s++) {
      final start = _font.getUint16(starts + s * 2);
      final end = _font.getUint16(ends + s * 2);
      final delta = _font.getInt16(deltas + s * 2);
      final rangeOffset = _font.getUint16(rangeOffsets + s * 2);
      for (var codepoint = start; codepoint <= end; codepoint++) {
        if (codepoint == 0xFFFF) continue;
        var glyph = codepoint;
        if (rangeOffset != 0) {
          glyph = _font.getUint16(
            rangeOffsets + s * 2 + rangeOffset + (codepoint - start) * 2,
          );
          if (glyph == 0) continue;
        }
        glyphs[codepoint] = (glyph + delta) & 0xFFFF;
      }
    }
    return glyphs;
  }
}

String _hex(int codepoint) =>
    'U+${codepoint.toRadixString(16).toUpperCase().padLeft(4, '0')}';

List<String> _placeholdersIn(
  String where,
  String text,
  Set<int> placeholders,
) =>
    [
      for (final codepoint in text.runes.toSet().intersection(placeholders))
        '$where: ${_hex(codepoint)}',
    ];

void main() {
  late Set<int> placeholders;

  setUpAll(() {
    sqfliteFfiInit();
    placeholders =
        _PlaceholderCodepoints(File(_verseFont).readAsBytesSync()).find();
  });

  Future<Database> open(String path) async {
    final database = await databaseFactoryFfi.openDatabase(
      File(path).absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    addTearDown(database.close);
    return database;
  }

  test('the verse font draws U+065C as a placeholder and U+06EA as a glyph',
      () {
    expect(placeholders, contains(0x065C));
    expect(placeholders, isNot(contains(0x06EA)));
  });

  test('no verse span in Al-Azkar.db holds a placeholder codepoint', () async {
    final database = await open('assets/db/Al-Azkar.db');
    final rows = [
      for (final column in ['body', 'fadl', 'source'])
        for (final row in await database.rawQuery(
          'SELECT id, $column AS text FROM contents',
        ))
          ('contents.$column ${row['id']}', row['text'] as String?),
      for (final row in await database.rawQuery(
        'SELECT id, name AS text FROM titles',
      ))
        ('titles.name ${row['id']}', row['text'] as String?),
    ];

    final found = [
      for (final (where, text) in rows)
        for (final span in _verseSpan.allMatches(text ?? ''))
          ..._placeholdersIn(where, span[0]!, placeholders),
    ];
    expect(found, isEmpty);
  });

  test('no verse in quran.ar.uthmani.v2.db holds a placeholder codepoint',
      () async {
    final database = await open('assets/db/quran.ar.uthmani.v2.db');
    final rows = await database.rawQuery(
      'SELECT sura, ayah, text FROM arabic_text',
    );

    expect(rows, hasLength(6236));
    final found = [
      for (final row in rows)
        ..._placeholdersIn(
          'arabic_text ${row['sura']}:${row['ayah']}',
          row['text']! as String,
          placeholders,
        ),
    ];
    expect(found, isEmpty);
  });
}
