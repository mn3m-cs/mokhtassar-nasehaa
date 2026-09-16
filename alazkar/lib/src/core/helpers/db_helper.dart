import 'dart:async';
import 'dart:io';

import 'package:alazkar/src/core/utils/app_print.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  late final String dbName;
  late final int dbVersion;

  DBHelper({required this.dbName, required this.dbVersion}) {
    appPrint("# DatabaseHelper for $dbName");
  }

  Future<String> getDbPath() async {
    late final String path;

    if (Platform.isWindows) {
      final dbPath = (await getApplicationSupportDirectory()).path;
      path = join(dbPath, dbName);
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, dbName);
    }

    return path;
  }

  Future<void> copyFromAssets(String path, String dbAssetPath) async {
    appPrint("$dbName copying new db...");

    final ByteData assetData = await rootBundle.load(dbAssetPath);
    final List<int> assetBytes = assetData.buffer.asUint8List();
    final File databaseFile = File(path);

    await databaseFile.writeAsBytes(assetBytes, flush: true);

    final int writtenBytes = await databaseFile.length();
    if (writtenBytes != assetBytes.length) {
      throw FileSystemException(
        "Incomplete database copy: expected ${assetBytes.length} bytes, wrote $writtenBytes",
        path,
      );
    }

    appPrint("$dbName copy done");
  }

  Future<Database> initDatabase() async {
    appPrint("$dbName init db");
    final String path = await getDbPath();
    final bool exist = await databaseExists(path);

    final assetDBPath = join('assets/db/$dbName');

    if (!exist) {
      await copyFromAssets(path, assetDBPath);
    }
    final Database database = await openDatabase(path);
    final int currentVersion = await database.getVersion();
    await database.close();

    if (currentVersion < dbVersion) {
      appPrint("$dbName detect new version");
      await deleteDatabase(path);
      await copyFromAssets(path, assetDBPath);
    }

    return openDatabase(path, version: dbVersion);
  }
}
