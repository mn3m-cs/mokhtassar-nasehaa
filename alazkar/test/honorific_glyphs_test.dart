import 'dart:convert';
import 'dart:io';

import 'package:alazkar/src/core/constants/const.dart';
import 'package:alazkar/src/core/helpers/azkar_helper.dart';
import 'package:alazkar/src/core/helpers/bookmarks_helper.dart';
import 'package:alazkar/src/core/manager/volume_button_manager.dart';
import 'package:alazkar/src/features/home/presentation/controller/home/home_bloc.dart';
import 'package:alazkar/src/features/settings/data/repository/settings_storage.dart';
import 'package:alazkar/src/features/theme/domain/models/zikr_font.dart';
import 'package:alazkar/src/features/theme/presentation/app_theme.dart';
import 'package:alazkar/src/features/theme/presentation/controller/cubit/theme_cubit.dart';
import 'package:alazkar/src/features/zikr_content_viewer/data/repository/reading_progress_storage.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/components/custom_text_formatter.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/controller/bloc/zikr_content_viewer_bloc.dart';
import 'package:alazkar/src/features/zikr_source_filter/data/repository/zikr_filter_storage.dart';
import 'package:alazkar/src/features/zikr_source_filter/presentation/controller/cubit/zikr_source_filter_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/memory_storage.dart';
import 'support/screen_picture.dart';

/// The glyphs migration 168 writes (#213); ﷻ was already a glyph.
final _migrated = kHonorificWords.keys.where((glyph) => glyph != 'ﷻ');

const _marks = '[ً-ْٰـ]*';

/// [words] with or without diacritics, as a pattern.
String _wordsPattern(String words) => words
    .split(' ')
    .map((word) => word.split('').map(RegExp.escape).join(_marks) + _marks)
    .join(r'\s+');

Future<Database> _bundled() {
  sqfliteFfiInit();
  return databaseFactoryFfi.openDatabase(
    File('assets/db/Al-Azkar.db').absolute.path,
    options: OpenDatabaseOptions(readOnly: true),
  );
}

/// Each cell migration 168 changed, as it was before (#213).
Map<String, Map<String, dynamic>> _before() => (jsonDecode(
      File('test/fixtures/honorifics_before_168.json').readAsStringSync(),
    ) as Map<String, dynamic>)
        .cast<String, Map<String, dynamic>>();

class _NoBookmarks implements BookmarksDBHelper {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the bundled database', () {
    late Database database;
    setUpAll(() async => database = await _bundled());
    tearDownAll(() => database.close());

    test('prints no honorific of the book in words', () async {
      final phrases = {
        for (final glyph in _migrated)
          glyph: RegExp(
            '(?<![ء-ي])${_wordsPattern(kHonorificWords[glyph]!)}'
            '(?![ء-ي])',
          ),
      };
      final found = <String>[];
      for (final row in await database.rawQuery(
        'SELECT id, body, source, fadl FROM contents',
      )) {
        for (final column in ['body', 'source', 'fadl']) {
          final outsideQuran = (row[column]! as String).replaceAll(
            RegExp('﴿.*?﴾'),
            '',
          );
          phrases.forEach((glyph, phrase) {
            if (phrase.hasMatch(outsideQuran)) {
              found.add('${row['id']} $column: ${kHonorificWords[glyph]}');
            }
          });
        }
      }
      expect(found, isEmpty);
    });

    test('changed only the words of an honorific in each cell', () async {
      final before = _before();
      expect(before, isNotEmpty);
      final count =
          await database.rawQuery('SELECT COUNT(*) AS n FROM contents');
      expect(count.single['n'], 1637);

      final differ = <String>[];
      for (final MapEntry(key: id, value: cells) in before.entries) {
        final row = (await database.rawQuery(
          'SELECT body, source, fadl FROM contents WHERE id = ?',
          [int.parse(id)],
        ))
            .single;
        cells.forEach((column, old) {
          final now = row[column]! as String;
          // The text as it is now, each glyph read as the words it may have
          // replaced, must spell the old text exactly.
          final spelled = now.split('').map((char) {
            final words = kHonorificWords[char];
            return words == null
                ? RegExp.escape(char)
                : '(?:${RegExp.escape(char)}|${_wordsPattern(words)})';
          }).join();
          if (now == old ||
              !RegExp('^$spelled\$', dotAll: true).hasMatch(old as String)) {
            differ.add('$id $column');
          }
        });
      }
      expect(differ, isEmpty);
    });

    test('keeps in search the words it turned into glyphs', () async {
      final missing = <String>[];
      for (final MapEntry(key: id, value: cells) in _before().entries) {
        final old = cells['body'] as String?;
        if (old == null) continue;
        final row = (await database.rawQuery(
          'SELECT search FROM contents WHERE id = ?',
          [int.parse(id)],
        ))
            .single;
        for (final glyph in _migrated) {
          final words = kHonorificWords[glyph]!;
          if (old.contains(RegExp(_wordsPattern(words))) &&
              !(row['search']! as String).contains(words)) {
            missing.add('$id: $words');
          }
        }
      }
      expect(missing, isEmpty);
    });
  });

  group('drawing', () {
    setUpAll(loadAppFonts);

    Future<double> width(WidgetTester tester, Widget screen) async {
      await tester.pumpWidget(screen);
      return tester
          .renderObject<RenderParagraph>(find.byType(RichText))
          .size
          .width;
    }

    Widget plain(Widget text) => Directionality(
          textDirection: TextDirection.rtl,
          child: Center(child: text),
        );

    // The fonts that have a glyph of their own, measured with fontTools
    // (#213); NotoNaskhArabic has them all, Cairo none.
    const ownGlyphs = {
      'Amiri': 'ﷺﷻ',
      'IBMPlexSansArabic': 'ﷺﷻ',
      'Kitab': 'ﷺﷻ',
      'NotoNaskhArabic': 'ﷺﷻ﵀﵁﵂﵃﵄﷾﷿',
    };

    /// [glyph] alone in [family], with no fallback.
    double alone(String glyph, String family) {
      final painter = TextPainter(
        text: TextSpan(
          text: glyph,
          style: TextStyle(fontFamily: family, fontSize: 40),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    /// The width [glyph] has when the font that draws it is [family] if it
    /// has the glyph, and NotoNaskhArabic if not.
    double drawn(String glyph, String family) => alone(glyph,
        (ownGlyphs[family] ?? '').contains(glyph) ? family : 'NotoNaskhArabic');

    testWidgets('a zikr draws every glyph in every font', (tester) async {
      for (final font in ZikrFont.values) {
        Widget zikr(String text) => plain(
              StringFormatter(
                text: text,
                fontSize: 40,
                enableDiacritics: true,
                fontFamily: font.family,
              ),
            );
        for (final glyph in kHonorificWords.keys) {
          expect(
            await width(tester, zikr(glyph)),
            closeTo(drawn(glyph, font.family), .01),
            reason: '$glyph in ${font.label}',
          );
        }
      }
    });

    testWidgets('the virtue line and the source draw every glyph', (
      tester,
    ) async {
      Widget themed(String text) => MaterialApp(
            theme: buildAppTheme(
              const ThemeState(
                color: Colors.brown,
                brightness: Brightness.light,
                useMaterial3: true,
                fontSize: 30,
                zikrFont: ZikrFont.notoNaskh,
              ),
            ),
            home: Material(
              child: Center(
                child: Builder(
                  builder: (context) => Text(
                    text,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontSize: 40),
                  ),
                ),
              ),
            ),
          );
      for (final glyph in kHonorificWords.keys) {
        expect(
          await width(tester, themed(glyph)),
          closeTo(drawn(glyph, 'Cairo'), .01),
          reason: glyph,
        );
      }
    });

    testWidgets('the screen reader reads a glyph as its words', (tester) async {
      final semantics = tester.ensureSemantics();
      await width(
        tester,
        plain(
          const StringFormatter(
            text: 'عن أبي هريرة ﵁ أن رسول الله ﷺ قال',
            fontSize: 30,
            enableDiacritics: true,
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(RichText)).label,
        'عن أبي هريرة رضي الله عنه أن رسول الله صلى الله عليه وسلم قال',
      );
      semantics.dispose();
    });
  });

  group('copying a zikr', () {
    late Directory dir;
    late AzkarDBHelper azkarDB;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    setUpAll(() async {
      sqfliteFfiInit();
      dir = Directory.systemTemp.createTempSync('honorific_glyphs');
      databaseFactory = databaseFactoryFfi;
      await databaseFactoryFfi.setDatabasesPath(dir.path);
      azkarDB = AzkarDBHelper();
      await azkarDB.init();
      messenger.setMockMethodCallHandler(
        VolumeButtonManager.channel,
        (_) async => null,
      );
    });

    tearDownAll(() {
      messenger.setMockMethodCallHandler(VolumeButtonManager.channel, null);
      dir.deleteSync(recursive: true);
    });

    test('writes the glyphs as words', () async {
      final filterStorage = ZikrFilterStorage(MemoryStorage());
      final home = HomeBloc(
        ZikrSourceFilterCubit(filterStorage),
        filterStorage,
        azkarDB,
        _NoBookmarks(),
      );
      final bloc = ZikrContentViewerBloc(
        home,
        SettingsStorage(MemoryStorage()),
        filterStorage,
        azkarDB,
        ReadingProgressStorage(MemoryStorage()),
      );
      addTearDown(() async {
        await bloc.close();
        await home.close();
      });

      final inSource = await azkarDB.getContentById(17);
      expect(inSource.source, contains('﵁'));
      final inBody = await azkarDB.getContentById(1148);
      expect(inBody.body, contains('﵁'));

      final glyphs = RegExp(kHonorificWords.keys.join('|'));
      final source = await bloc.sharedZikrText(inSource);
      expect(source, contains('عن عبد الله بن خُبيب رضي الله عنه أن النبي'));
      expect(source, isNot(contains(glyphs)));
      final body = await bloc.sharedZikrText(inBody);
      expect(body, contains('عن أبي هريرة رضي الله عنه أن رسول الله'));
      expect(body, isNot(contains(glyphs)));
    });
  });
}
