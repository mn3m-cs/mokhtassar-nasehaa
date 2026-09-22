import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled hierarchy supports deep trees and rejects invalid shapes',
      () async {
    sqfliteFfiInit();
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'zaad-hierarchy-test-',
    );
    addTearDown(() => temporaryDirectory.delete(recursive: true));

    final databaseFile = File('${temporaryDirectory.path}/Al-Azkar.db');
    await File('assets/db/Al-Azkar.db').copy(databaseFile.path);
    final database = await databaseFactoryFfi.openDatabase(databaseFile.path);
    addTearDown(database.close);
    await database.execute('PRAGMA foreign_keys = ON');

    await database.insert('titles', {
      'id': 1000,
      'order': 1000,
      'name': 'العبادات',
      'freq': 'd',
      'nodeType': 'category',
    });
    await database.insert('titles', {
      'id': 1001,
      'order': 1,
      'name': 'الصلاة',
      'freq': 'd',
      'parentId': 1000,
      'nodeType': 'category',
    });
    await database.insert('titles', {
      'id': 1002,
      'order': 1,
      'name': 'أذكار داخل الصلاة',
      'freq': 'd',
      'parentId': 1001,
      'nodeType': 'category',
    });
    await database.insert('titles', {
      'id': 1003,
      'order': 1,
      'name': 'دعاء تجريبي',
      'freq': 'd',
      'parentId': 1002,
      'nodeType': 'content',
    });

    final path = await database.rawQuery('''
      WITH RECURSIVE ancestors(id, parentId, name, depth) AS (
        SELECT id, parentId, name, 0
        FROM titles
        WHERE id = 1003

        UNION ALL

        SELECT titles.id, titles.parentId, titles.name, ancestors.depth + 1
        FROM titles
        JOIN ancestors ON titles.id = ancestors.parentId
      )
      SELECT name FROM ancestors ORDER BY depth DESC
    ''');
    expect(
      path.map((row) => row['name']),
      ['العبادات', 'الصلاة', 'أذكار داخل الصلاة', 'دعاء تجريبي'],
    );

    await expectLater(
      database.insert('titles', {
        'id': 1010,
        'order': 2,
        'name': 'أب مفقود',
        'freq': 'd',
        'parentId': 9999,
        'nodeType': 'content',
      }),
      throwsA(isA<DatabaseException>()),
    );
    await expectLater(
      database.insert('titles', {
        'id': 1011,
        'order': 2,
        'name': 'ابن تحت محتوى',
        'freq': 'd',
        'parentId': 1003,
        'nodeType': 'content',
      }),
      throwsA(isA<DatabaseException>()),
    );
    await expectLater(
      database.insert('titles', {
        'id': 1012,
        'order': 1,
        'name': 'ترتيب مكرر',
        'freq': 'd',
        'parentId': 1000,
        'nodeType': 'category',
      }),
      throwsA(isA<DatabaseException>()),
    );
    await expectLater(
      database.update(
        'titles',
        {'parentId': 1002},
        where: 'id = ?',
        whereArgs: [1000],
      ),
      throwsA(isA<DatabaseException>()),
    );
    await expectLater(
      database.insert('contents', {
        'id': 10000,
        'titleId': 1002,
        'order': 1,
        'body': 'لا يجوز إسناد المحتوى إلى عقدة تنظيمية',
        'count': 1,
      }),
      throwsA(isA<DatabaseException>()),
    );
  });
}
