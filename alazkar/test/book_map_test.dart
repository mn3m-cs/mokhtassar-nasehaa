import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _statuses = {'قورن', 'لم يُقارَن', 'ليس في الكتاب', 'لا محتوى'};
const _firstPage = 5;
const _lastPage = 464;

class _MapRow {
  _MapRow(this.pages, this.ids, this.status, this.reference);

  final String pages;
  final List<int> ids;
  final String status;
  final String reference;

  int? get firstPage => int.tryParse(pages.split('–').first);
  int? get lastPage => int.tryParse(pages.split('–').last);
}

List<_MapRow> _parseBookMap(String markdown) {
  final rows = <_MapRow>[];
  for (final line in markdown.split('\n')) {
    if (!line.startsWith('|')) continue;
    final cells = line
        .substring(1, line.lastIndexOf('|'))
        .split('|')
        .map((cell) => cell.trim())
        .toList();
    if (cells.length != 5) continue;
    if (cells[0] == 'الصفحات' || cells[0].startsWith('---')) continue;
    final ids = cells[2] == '—'
        ? <int>[]
        : cells[2]
            .split(',')
            .map((id) => int.tryParse(id.trim()) ?? -1)
            .toList();
    rows.add(_MapRow(cells[0], ids, cells[3], cells[4]));
  }
  return rows;
}

/// Returns what is wrong with the map, one line per problem.
List<String> _bookMapProblems(
  List<_MapRow> rows, {
  required Set<int> contentIds,
  required Set<int> allIds,
}) {
  final problems = <String>[];
  final placed = <int, int>{};
  for (final row in rows) {
    for (final id in row.ids) {
      placed[id] = (placed[id] ?? 0) + 1;
      if (!allIds.contains(id)) {
        problems.add('معرّف غير موجود في القاعدة: $id (ص${row.pages})');
      }
    }
    if (!_statuses.contains(row.status)) {
      problems.add('حالة غير معروفة: «${row.status}» (ص${row.pages})');
    }
    if (row.status == 'قورن' && !RegExp(r'طلب #\d+').hasMatch(row.reference)) {
      problems.add('صف «قورن» بلا رقم طلب دمج (ص${row.pages})');
    }
  }
  for (final id in contentIds) {
    final times = placed[id] ?? 0;
    if (times != 1) {
      problems.add('قسم محتوى $id في $times صفوف، والمطلوب صف واحد');
    }
  }

  final paged = rows.where((row) => row.status != 'ليس في الكتاب').toList();
  var next = _firstPage;
  for (final row in paged) {
    final first = row.firstPage;
    final last = row.lastPage;
    if (first == null || last == null || last < first) {
      problems.add('صفحات غير صالحة: «${row.pages}»');
    } else if (first != next) {
      problems.add('الصفحات لا تتصل: المتوقع ص$next والموجود ص$first');
      next = last + 1;
    } else {
      next = last + 1;
    }
  }
  if (next != _lastPage + 1) {
    problems.add('الصفحات تنتهي عند ص${next - 1} والمطلوب ص$_lastPage');
  }
  return problems;
}

void main() {
  late String markdown;
  late Set<int> contentIds;
  late Set<int> allIds;

  setUpAll(() async {
    markdown = File('../docs/book-map.md').readAsStringSync();
    sqfliteFfiInit();
    final database = await databaseFactoryFfi.openDatabase(
      File('assets/db/Al-Azkar.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    final titles = await database.rawQuery('SELECT id, nodeType FROM titles');
    await database.close();
    allIds = {for (final row in titles) row['id']! as int};
    contentIds = {
      for (final row in titles)
        if (row['nodeType'] == 'content') row['id']! as int,
    };
  });

  List<String> problemsOf(String text) => _bookMapProblems(
        _parseBookMap(text),
        contentIds: contentIds,
        allIds: allIds,
      );

  test('docs/book-map.md places every content section exactly once', () {
    expect(_parseBookMap(markdown), isNotEmpty);
    expect(problemsOf(markdown), isEmpty);
  });

  test('the map fails when an id is removed from it', () {
    final changed = markdown.replaceFirst('| 171 |', '| — |');
    expect(problemsOf(changed), ['قسم محتوى 171 في 0 صفوف، والمطلوب صف واحد']);
  });

  test('the map fails when an id is listed twice', () {
    final changed = markdown.replaceFirst('| 4 |', '| 4, 5 |');
    expect(problemsOf(changed), ['قسم محتوى 5 في 2 صفوف، والمطلوب صف واحد']);
  });

  test('the map fails when an id is not in the database', () {
    final changed = markdown.replaceFirst('| 4 |', '| 4, 99999 |');
    expect(
      problemsOf(changed),
      ['معرّف غير موجود في القاعدة: 99999 (ص69)'],
    );
  });

  test('the map fails on a status outside the four', () {
    final changed = markdown.replaceFirst('| لا محتوى |', '| قورن تقريبًا |');
    expect(problemsOf(changed), ['حالة غير معروفة: «قورن تقريبًا» (ص445–464)']);
  });

  test('a «قورن» row must name a pull request, not only a ticket', () {
    const row = '| 69 | أذكار الاستيقاظ | 4 | قورن | #172، طلب #217 |';
    expect(markdown, contains(row));
    expect(problemsOf(markdown), isEmpty);
    final ticketOnly = markdown.replaceFirst(
      row,
      '| 69 | أذكار الاستيقاظ | 4 | قورن | #172 |',
    );
    expect(problemsOf(ticketOnly), ['صف «قورن» بلا رقم طلب دمج (ص69)']);
  });

  test('the map fails on a gap or an overlap in the pages', () {
    final gap = markdown.replaceFirst('| 70 |', '| 71 |');
    expect(problemsOf(gap), isNotEmpty);
    final overlap = markdown.replaceFirst('| 72–73 |', '| 72–74 |');
    expect(problemsOf(overlap), isNotEmpty);
  });
}
