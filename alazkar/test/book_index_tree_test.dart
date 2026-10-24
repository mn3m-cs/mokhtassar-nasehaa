import 'dart:convert';
import 'dart:io';

import 'package:alazkar/src/core/helpers/bookmarks_helper.dart';
import 'package:alazkar/src/features/reminders/data/models/reminder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// «حول الكتاب»: the pages before the index starts (decision 7 of #220).
const _aboutBook = 99;

/// A node of the navigation as `kind:name`, with its children.
class _Node {
  _Node(this.kind, this.name, this.children);

  final String kind;
  final String name;
  final List<_Node> children;

  List<String> lines([int depth = 0]) => [
        '${'  ' * depth}$kind:$name',
        for (final child in children) ...child.lines(depth + 1),
      ];
}

/// The tree docs/book-index.json describes: an entry with children is a
/// category, one without is a section, and a line the book prints only in a
/// footnote («notASection») is no node.
List<_Node> _treeOfIndex(List<dynamic> entries) => [
      for (final entry in entries.cast<Map<String, dynamic>>())
        if (entry['children'] != null)
          _Node('category', entry['name'] as String,
              _treeOfIndex(entry['children'] as List<dynamic>))
        else if (entry['notASection'] == null)
          _Node('content', entry['name'] as String, const []),
    ];

void main() {
  late Database database;
  late List<Map<String, Object?>> titles;
  late Map<String, dynamic> index;

  setUpAll(() async {
    sqfliteFfiInit();
    database = await databaseFactoryFfi.openDatabase(
      File('assets/db/Al-Azkar.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    titles = await database.rawQuery(
      'SELECT id, "order", name, parentId, nodeType FROM titles '
      'ORDER BY "order"',
    );
    index = jsonDecode(File('../docs/book-index.json').readAsStringSync())
        as Map<String, dynamic>;
  });

  tearDownAll(() => database.close());

  List<_Node> treeOfDatabase(int? parentId) => [
        for (final title in titles.where((t) => t['parentId'] == parentId))
          if (title['id'] != _aboutBook)
            _Node(
              title['nodeType']! as String,
              title['name']! as String,
              treeOfDatabase(title['id']! as int),
            ),
      ];

  Map<String, Object?> titleOf(int id) =>
      titles.singleWhere((title) => title['id'] == id);

  Set<String> indexLines() {
    final lines = <String>{};
    void collect(List<_Node> nodes) {
      for (final node in nodes) {
        if (node.kind == 'content') lines.add(node.name);
        collect(node.children);
      }
    }

    collect(_treeOfIndex(index['entries'] as List<dynamic>));
    return lines;
  }

  test('the navigation is the book index: names, order and levels', () {
    final expected = _treeOfIndex(index['entries'] as List<dynamic>);
    final actual = treeOfDatabase(null);

    expect(
      [for (final node in actual) ...node.lines()],
      [for (final node in expected) ...node.lines()],
    );
  });

  test('«حول الكتاب» stays first, above the index', () {
    final roots = titles.where((title) => title['parentId'] == null).toList();

    expect(roots.first['id'], _aboutBook);
    expect(roots.first['order'], 1);
  });

  test('a line the book prints only in a footnote is no section', () {
    final footnoteLines = <String>[];
    void collect(List<dynamic> entries) {
      for (final entry in entries.cast<Map<String, dynamic>>()) {
        if (entry['notASection'] != null) {
          footnoteLines.add(entry['name'] as String);
        }
        collect(entry['children'] as List<dynamic>? ?? const []);
      }
    }

    collect(index['entries'] as List<dynamic>);
    final names = titles.map((title) => title['name']).toSet();

    expect(footnoteLines, hasLength(7));
    expect(footnoteLines.where(names.contains), isEmpty);
  });

  test(
      'the default favourites and the reminders keep their ids, each on a '
      'line of the index', () {
    final lines = indexLines();
    final ids = {
      ...BookmarksDBHelper.defaultTitleIds,
      for (final slot in ReminderSlot.values) slot.titleId,
    };

    for (final id in ids) {
      final title = titleOf(id);
      expect(title['nodeType'], 'content', reason: 'section $id');
      expect(lines, contains(title['name']), reason: 'section $id');
    }
    expect(titleOf(1)['name'], 'أولًا: أذكار الصَّباح');
    expect(titleOf(2)['name'], 'ثانيًا: أذكارُ المساء');
    expect(titleOf(18)['name'], 'ما يقول إذا أراد النوم');
  });

  test(
      'a section that was named after its chapter is now the first section '
      'under that chapter, so its favourite opens there', () {
    // Sections whose name was the chapter's before #220, with the chapter.
    const formerChapterSections = {
      4: 'أذكار الاستيقاظ',
      5: 'أذكار الوضوء',
      6: 'أذكار اللِّباس',
      7: 'أذكار دخول البيت، والخروج منه',
      9: 'أذكار الأذان',
      18: 'أذكار النَّوْمِ',
      41: 'أذكار المَرَض',
      45: 'أذكار الموت',
      48: 'أذكار الصيام',
      49: 'أذكار المُسافِر',
      60: 'أذكار الغزو والجهاد',
      61: 'أذكار الأكل والشرب',
      63: 'أذكار النكاح',
      65: 'أذكار تتعلق بالأمور العلوية',
      66: 'أولًا: من القرآن الكريم',
      67: 'ثانيًا: أذكار متفرِّقة من السُّنَّةِ الشَّرِيفَة',
      75: 'من صِيَغِ الحمد:',
    };

    formerChapterSections.forEach((id, chapter) {
      final section = titleOf(id);
      final parent = titleOf(section['parentId']! as int);
      expect(parent['name'], chapter, reason: 'section $id');
      expect(parent['nodeType'], 'category', reason: 'section $id');
      expect(section['order'], 1, reason: 'section $id');
    });
  });

  test(
      'every section that left the navigation sends its favourites to a '
      'section that holds its rows', () {
    final ids = titles.map((title) => title['id']).toSet();

    BookmarksDBHelper.movedTitleIds.forEach((from, to) {
      expect(ids, isNot(contains(from)), reason: 'section $from');
      expect(titleOf(to)['nodeType'], 'content', reason: 'section $to');
    });
  });

  test('upgrading the favourites moves them from the sections that left',
      () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    await db.execute('''
      CREATE TABLE favourite_titles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titleId INTEGER NOT NULL UNIQUE
      )
    ''');
    for (final titleId in [1, 2, 4, 16, 18, 49, 139, 157, 176]) {
      await db.insert('favourite_titles', {'titleId': titleId});
    }

    await BookmarksDBHelper.upgrade(db, 4);

    final rows =
        await db.rawQuery('SELECT titleId FROM favourite_titles ORDER BY 1');
    expect(
      rows.map((row) => row['titleId']),
      [-176, 1, 2, 4, 16, 18, 49, 156],
      reason: '139 joins 49, which is already there; 157 goes to 156; 176 '
          'stays the card «ورد التسبيح», stored as -176',
    );
  });
}
