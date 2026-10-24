import 'dart:async';
import 'dart:io';

import 'package:alazkar/src/core/utils/app_print.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class BookmarksDBHelper {
  /* ************* Variables ************* */

  static const String dbName = "Bookmarks.db";
  static const int dbVersion = 5;

  /// Sections that always stay in favourites and can never be removed:
  /// morning, evening, waking up, after prayer, sleep.
  static const List<int> pinnedTitleIds = [1, 2, 4, 16, 18];

  /// Default favourites, in book order: the pinned sections, then travelling,
  /// which is only a default and may be removed.
  static const List<int> defaultTitleIds = [...pinnedTitleIds, 49];

  static bool isPinned(int titleId) => pinnedTitleIds.contains(titleId);

  /// Defaults shipped before version 3; they were ids of the upstream app and
  /// point to unrelated sections here.
  static const List<int> legacyDefaultTitleIds = [2, 84, 89, 94, 99, 191, 254];

  /// Sections that left the navigation when it became the book's index
  /// (#220, Al-Azkar.db 167), each with the section that now holds its first
  /// rows: an introduction that is no line of the index, or a heading the
  /// index does not list.
  static const Map<int, int> movedTitleIds = {
    139: 49,
    157: 156,
    161: 151,
    176: 74,
    187: 188,
  };

  /* ************* Singleton Constructor ************* */

  static BookmarksDBHelper? _databaseHelper;
  static Database? _database;

  factory BookmarksDBHelper() {
    _databaseHelper ??= BookmarksDBHelper._createInstance();
    return _databaseHelper!;
  }

  BookmarksDBHelper._createInstance();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<void> init() async {
    // Ensure the database is initialized
    await database;
  }

  /* ************* Database Creation ************* */

  // init
  Future<Database> _initDatabase() async {
    late final String path;
    if (Platform.isWindows) {
      final dbPath = (await getApplicationSupportDirectory()).path;
      path = join(dbPath, dbName);
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, dbName);
    }

    return openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreateDatabase,
      onUpgrade: _onUpgradeDatabase,
      onDowngrade: _onDowngradeDatabase,
    );
  }

  /// On create database
  Future<void> _onCreateDatabase(Database db, int version) async {
    appPrint("Create Bookmarks.db");

    /// Create favourite_contents table
    await db.execute('''
    CREATE TABLE "favourite_contents" (
      "id"	INTEGER NOT NULL UNIQUE,
      "contentId"	INTEGER NOT NULL UNIQUE,
      PRIMARY KEY("id" AUTOINCREMENT)
    );
    ''');

    /// Create favourite_titles table
    await db.execute('''
    CREATE TABLE "favourite_titles" (
      "id"	INTEGER NOT NULL UNIQUE,
      "titleId"	INTEGER NOT NULL UNIQUE,
      PRIMARY KEY("id" AUTOINCREMENT)
    );
    ''');

    ///
    await addDefaultTitles(db);
  }

  /// default favourite titles
  static Future<void> addDefaultTitles(Database db) async {
    final batch = db.batch();
    for (final titleId in defaultTitleIds) {
      batch.rawInsert(
        'INSERT OR IGNORE INTO favourite_titles(titleId) VALUES(?)',
        [titleId],
      );
    }
    await batch.commit(noResult: true);
  }

  /// Puts back any pinned section that is missing; other rows are untouched.
  static Future<void> restorePinnedTitles(Database db) async {
    final batch = db.batch();
    for (final titleId in pinnedTitleIds) {
      batch.rawInsert(
        'INSERT OR IGNORE INTO favourite_titles(titleId) VALUES(?)',
        [titleId],
      );
    }
    await batch.commit(noResult: true);
  }

  /// Replaces the legacy defaults when the user never added a favourite of
  /// their own; any personal choice leaves the table untouched.
  static Future<void> replaceLegacyDefaults(Database db) async {
    final rows = await db.rawQuery('SELECT titleId FROM favourite_titles');
    final titleIds = rows.map((row) => row['titleId']! as int).toSet();
    if (titleIds.isEmpty || !titleIds.every(legacyDefaultTitleIds.contains)) {
      return;
    }
    await db.delete('favourite_titles');
    await addDefaultTitles(db);
  }

  /// Moves the favourites saved on [movedTitleIds] to the sections that hold
  /// their rows now; a section already in favourites is not added twice.
  static Future<void> moveFavouriteTitles(Database db) async {
    final batch = db.batch();
    movedTitleIds.forEach((from, to) {
      batch.rawUpdate(
        'UPDATE OR IGNORE favourite_titles SET titleId = ? WHERE titleId = ?',
        [to, from],
      );
      batch.rawDelete('DELETE FROM favourite_titles WHERE titleId = ?', [from]);
    });
    await batch.commit(noResult: true);
  }

  /// On upgrade database version
  Future<void> _onUpgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) =>
      upgrade(db, oldVersion);

  /// Legacy defaults are judged on the stored rows before anything is added,
  /// so adding the new defaults first cannot hide them.
  static Future<void> upgrade(Database db, int oldVersion) async {
    if (oldVersion < 3) {
      await replaceLegacyDefaults(db);
    }
    if (oldVersion < 2) {
      await addDefaultTitles(db);
    }
    if (oldVersion < 4) {
      await restorePinnedTitles(db);
    }
    if (oldVersion < 5) {
      await moveFavouriteTitles(db);
    }
  }

  /// On downgrade database version
  Future<void> _onDowngradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {}

  /* ************* Functions ************* */

  Future<List<int>> getAllFavoriteTitles() async {
    final Database db = await database;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''SELECT * from favourite_titles order by titleId asc''',
    );

    return List.generate(maps.length, (i) {
      return maps[i]["titleId"] as int;
    });
  }

  /// Add title to favourite
  Future<void> addTitleToFavourite({
    required int titleId,
  }) async {
    final db = await database;
    await db.rawInsert(
      'INSERT OR IGNORE INTO favourite_titles( titleId) VALUES(?)',
      [titleId],
    );
  }

  Future<void> deleteTitleFromFavourite({
    required int titleId,
  }) async {
    if (isPinned(titleId)) return;
    final db = await database;

    await db
        .rawDelete("DELETE FROM favourite_titles WHERE titleId = ?", [titleId]);
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
