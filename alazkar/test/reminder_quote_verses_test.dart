import 'dart:io';

import 'package:alazkar/src/core/di/dependency_injection.dart';
import 'package:alazkar/src/core/models/zikr.dart';
import 'package:alazkar/src/core/models/zikr_extension.dart';
import 'package:alazkar/src/features/quran/data/repository/uthmani_repository.dart';
import 'package:alazkar/src/features/reminders/domain/reminder_quotes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A verse in the morning and evening set is the verse the app shows for its
/// record, read through the same code and the same Quran database, from ﴿ to
/// ﴾ with nothing before or after, and no number after the last verse, as the
/// book prints it on page 29.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database azkar;

  setUpAll(() async {
    sqfliteFfiInit();
    sqflite.databaseFactory = databaseFactoryFfi;
    await databaseFactoryFfi.setDatabasesPath(
      Directory.systemTemp.createTempSync('reminder_verses').path,
    );
    if (!sl.isRegistered<UthmaniRepository>()) {
      sl.registerSingleton(UthmaniRepository());
    }
    azkar = await databaseFactoryFfi.openDatabase(
      File('assets/db/Al-Azkar.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
  });

  tearDownAll(() async {
    await azkar.close();
    await sl<UthmaniRepository>().close();
    sl.unregister<UthmaniRepository>();
  });

  test('each verse reads as the app shows it for its record', () async {
    final verses = kReminderQuotes[1]!.where((q) => q.zikrId != null);
    expect(verses.map((q) => q.zikrId), [1228, 1229, 1230]);
    for (final quote in verses) {
      final row = (await azkar.query(
        'contents',
        where: 'id = ?',
        whereArgs: [quote.zikrId],
      ))
          .single;
      final shown = await Zikr.fromMap(row).toPlainText();
      final verse = shown.substring(
        shown.indexOf('﴿'),
        shown.lastIndexOf('﴾') + 1,
      );
      // The book prints no number after the last verse, so it goes.
      final lastNumber = RegExp(r' [٠-٩]+ ﴾$');
      expect(verse, contains(lastNumber), reason: '${quote.zikrId}');
      expect(
        quote.text,
        verse.replaceFirst(lastNumber, ' ﴾'),
        reason: '${quote.zikrId}',
      );
      expect(quote.text, startsWith('﴿'));
      expect(quote.text, endsWith('﴾'));
    }
  });
}
