import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The section files in `data_pipeline/sections` are a copy of the bundled
/// database, written by `data_pipeline/export_sections.py` (#236). The
/// database is the source: every title has exactly one file, and every field
/// of the title and of its rows matches the database, row ids included.
void main() {
  test('every section file matches its title in the bundled database',
      () async {
    sqfliteFfiInit();
    final database = await databaseFactoryFfi.openDatabase(
      File('assets/db/Al-Azkar.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    addTearDown(database.close);

    final titles = {
      for (final row in await database.rawQuery(
        'SELECT id, "order", name, freq, parentId, nodeType FROM titles',
      ))
        row['id']! as int: row,
    };
    final contents = <int, List<Map<String, Object?>>>{};
    for (final row in await database.rawQuery('''
      SELECT id, titleId, body, count, hokm, source, fadl, style
      FROM contents
      ORDER BY titleId, "order"
    ''')) {
      contents.putIfAbsent(row['titleId']! as int, () => []).add(row);
    }

    final problems = <String>[];
    final fileOf = <int, String>{};
    final files = Directory('../data_pipeline/sections')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      final name = file.uri.pathSegments.last;
      final scheme = jsonDecode(file.readAsStringSync()) as Map;
      final title = scheme['title'] as Map;
      final id = title['id'];
      if (id is! int) {
        problems.add('$name: no title.id');
        continue;
      }
      if (fileOf.containsKey(id)) {
        problems.add('$name: title $id already in ${fileOf[id]}');
        continue;
      }
      fileOf[id] = name;
      final row = titles[id];
      if (row == null) {
        problems.add('$name: title $id is not in the database');
        continue;
      }
      for (final field in ['order', 'name', 'freq', 'parentId', 'nodeType']) {
        if (title[field] != row[field]) {
          problems.add('$name: title.$field is ${jsonEncode(title[field])}, '
              'the database has ${jsonEncode(row[field])}');
        }
      }

      final items = scheme['items'] as List;
      final rows = contents[id] ?? const [];
      if (items.length != rows.length) {
        problems.add('$name: ${items.length} items, '
            'the database has ${rows.length} rows');
      }
      for (var i = 0; i < items.length && i < rows.length; i++) {
        final item = items[i] as Map;
        final expected = rows[i];
        if (item['id'] != expected['id']) {
          problems.add('$name: item ${i + 1} has id ${item['id']}, '
              'the database has ${expected['id']} in that place');
          continue;
        }
        for (final field in ['body', 'count', 'hokm', 'source', 'fadl']) {
          if (item[field] != expected[field]) {
            problems.add('$name: item ${item['id']} differs in $field');
          }
        }
        if ((item['style'] ?? '') != expected['style']) {
          problems.add('$name: item ${item['id']} differs in style');
        }
      }
    }

    for (final id in titles.keys.where((id) => !fileOf.containsKey(id))) {
      problems.add('title $id «${titles[id]!['name']}» has no file');
    }

    expect(
      problems,
      isEmpty,
      reason: '${problems.length} differences; '
          'run data_pipeline/export_sections.py:\n'
          '${problems.take(30).join('\n')}',
    );
  });
}
