import 'dart:io';
import 'dart:ui' as ui;

import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:alazkar/src/features/home/presentation/components/home_header.dart';
import 'package:alazkar/src/features/home/presentation/components/index_row.dart';
import 'package:alazkar/src/features/home/presentation/components/section_browser.dart';
import 'package:alazkar/src/features/home/presentation/controller/home/home_bloc.dart';
import 'package:alazkar/src/features/settings/data/repository/zikr_text_repo.dart';
import 'package:alazkar/src/features/theme/domain/repository/theme_storage.dart';
import 'package:alazkar/src/features/theme/presentation/app_theme.dart';
import 'package:alazkar/src/features/theme/presentation/controller/cubit/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/memory_storage.dart';
import 'support/screen_picture.dart';

/// Test pictures for the navigation as the book's index (#220), drawn from the
/// bundled database. Run on `main` for the pictures before the change and on
/// the branch for the ones after; the cases tell the two trees apart by
/// whether «أذكار الاستيقاظ» is a category. `--dart-define=PICTURE_DIR=<dir>`
/// chooses where the PNGs go.
const _dir =
    String.fromEnvironment('PICTURE_DIR', defaultValue: 'build/test_pictures');

/// One picture: the categories to open, in order, the row the picture starts
/// at (the first category opened, unless [top] says otherwise), and the
/// favourites shown above the index, if any.
class _View {
  const _View({
    this.open = const [],
    this.top,
    this.favourites,
    this.height = 915,
  });

  final List<String> open;
  final String? top;
  final List<int>? favourites;
  final double height;
}

class _Case {
  const _Case(this.file, {required this.before, required this.after});

  final String file;
  final _View before;
  final _View after;
}

const _cases = [
  _Case(
    'case01_index_closed',
    before: _View(height: 1750),
    after: _View(height: 1750),
  ),
  _Case(
    'case02_waking',
    before: _View(top: 'أذكار الاستيقاظ'),
    after: _View(open: ['أذكار الاستيقاظ']),
  ),
  _Case(
    'case03_adhan',
    before: _View(top: 'أذكار المسجد'),
    after: _View(open: ['أذكار الأذان']),
  ),
  _Case(
    'case04_one_line',
    before: _View(
      open: ['الأذكار المطلقة', 'الباقيات الصالحات', 'الدعاء للوالدين'],
      top: 'الباقيات الصالحات',
    ),
    after: _View(
      open: [
        'أنواع وصِيَغ الأوراد المأثورة',
        'النوع الخامس: وِرْدُ الباقياتِ الصَّالحات',
        'النوع الثاني عشر: وِرْدُ الدعاء للوالدين في حياتهما وبعدَ موتهما',
      ],
      top: 'النوع الخامس: وِرْدُ الباقياتِ الصَّالحات',
    ),
  ),
  _Case(
    'case05_wirds',
    before: _View(
      open: [
        'الأدعية المطلقة',
        'جامع أدعية القرآن المجيد والسنة الصحيحة (الأدعية المطلقة)',
      ],
      height: 1100,
    ),
    after: _View(
      open: [
        'جامعُ أدعيةِ القرآنِ المجيدِ والسُّنَّةِ الصحيحة (الأدعية المُطلقة)',
      ],
      top: 'النوع الرابعَ عَشَرَ: أدعية القرآن الكريم والسُّنَّة الصحيحة '
          '(الأدعية المطلقة)',
      height: 1100,
    ),
  ),
  _Case(
    'case06_hajj',
    before: _View(
      open: [
        'الحج والعمرة والزيارة',
        'الإحرام',
        'الطواف والسعي',
        'عرفة ومزدلفة ومنى',
        'زيارة المدينة',
      ],
      top: 'الحج والعمرة والزيارة',
      height: 1500,
    ),
    after: _View(open: ['أدعية الحَجِّ والعُمْرَةِ والزِّيارة'], height: 1500),
  ),
  _Case(
    'case07_favourites',
    before: _View(favourites: [1, 2, 4, 9, 16, 18, 49, 176]),
    after: _View(favourites: [1, 2, 4, 9, 16, 18, 49, 74]),
  ),
  _Case(
    'case08_kinds_tahmid',
    before: _View(open: ['الأذكار المطلقة', 'التحميد'], height: 1300),
    after: _View(
      open: [
        'أنواع وصِيَغ الأوراد المأثورة',
        'النوع السابع: وِرْدُ التحميد',
        'من صِيَغِ الحمد:',
      ],
      height: 1300,
    ),
  ),
  _Case(
    'case09_eid_level',
    before: _View(
      open: [
        'الصلاة',
        'صلاة العيد',
        'صلاة الكسوف',
        'صلاة الاستسقاء',
        'صلوات متفرقة',
      ],
      top: 'الصلاة',
      height: 1300,
    ),
    after: _View(
      open: ['أذكار الصلاة'],
      top: 'ما يقول بعد الصلاة',
    ),
  ),
  _Case(
    'case10_second_part',
    before: _View(
      open: ['الأذكار المطلقة', 'الأدعية المطلقة'],
      top: 'الأذكار المتفرقة',
      height: 1300,
    ),
    after: _View(top: 'الأذكار المتفرِّقة'),
  ),
  _Case(
    'case11_travel',
    before: _View(open: ['السفر']),
    after: _View(open: ['أذكار المُسافِر'], height: 1000),
  ),
];

const _pixelRatio = 2.625;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<ZikrTitle> titles;
  late ThemeData theme;

  setUpAll(() async {
    await loadAppFonts();
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(
      File('assets/db/Al-Azkar.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    titles = (await db.query('titles', orderBy: '"order"'))
        .map(ZikrTitle.fromMap)
        .toList();
    await db.close();
    final storage = MemoryStorage();
    theme = buildAppTheme(
      ThemeCubit(ZikrTextRepo(storage), ThemeStorage(storage)).state,
    );
  });

  for (final c in _cases) {
    testWidgets('draws ${c.file}', (tester) async {
      final after = titles.any((title) =>
          title.name == 'أذكار الاستيقاظ' &&
          title.nodeType == ZikrTitleNodeType.category);
      final view = after ? c.after : c.before;
      final favourites = view.favourites;

      tester.view.devicePixelRatio = _pixelRatio;
      tester.view.physicalSize = Size(412, view.height) * _pixelRatio;
      addTearDown(tester.view.reset);

      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme,
            localizationsDelegates: const [
              GlobalCupertinoLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ar', 'EG')],
            locale: const Locale('ar', 'EG'),
            home: Scaffold(
              body: SafeArea(
                child: SectionBrowser(
                  titles: titles,
                  header: favourites == null
                      ? null
                      : HomeHeader(
                          favourites: HomeLoadedState(
                            titles: titles,
                            titlesToShow: titles,
                            isSearching: false,
                            favouriteTitlesIds: favourites,
                            cardSections: const {},
                          ).favouriteTiles(),
                        ),
                  itemBuilder: (context, row) => IndexRow(row: row),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      Future<void> toTop(String name) async {
        final row = find.text(name);
        // The row is built only near the screen: from the top of the list,
        // scroll down to it.
        if (row.evaluate().isEmpty) {
          await tester.drag(
              find.byType(Scrollable).first, const Offset(0, 1e5));
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(row, 300);
          await tester.pumpAndSettle();
        }
        expect(row, findsOneWidget, reason: name);
        await Scrollable.ensureVisible(tester.element(row));
        await tester.pumpAndSettle();
      }

      for (final name in view.open) {
        await toTop(name);
        await tester.tap(find.text(name));
        await tester.pumpAndSettle();
      }
      final top = view.top ?? (view.open.isEmpty ? null : view.open.first);
      if (top != null) await toTop(top);

      final phase = after ? 'after' : 'before';
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: _pixelRatio);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('$_dir/${c.file}_$phase.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
      });
    });
  }
}
