import 'dart:io';

import 'package:alazkar/src/core/models/zikr.dart';
import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:alazkar/src/features/settings/data/repository/zikr_text_repo.dart';
import 'package:alazkar/src/features/share_as_image/data/models/shareable_image_card_settings.dart';
import 'package:alazkar/src/features/share_as_image/presentation/components/shareable_image_card.dart';
import 'package:alazkar/src/features/theme/domain/models/zikr_font.dart';
import 'package:alazkar/src/features/theme/domain/repository/theme_storage.dart';
import 'package:alazkar/src/features/theme/presentation/app_theme.dart';
import 'package:alazkar/src/features/theme/presentation/controller/cubit/theme_cubit.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/components/zikr_item_card.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/components/zikr_source_dialog.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/controller/bloc/zikr_content_viewer_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/memory_storage.dart';
import 'support/screen_picture.dart';

/// The pictures of #213's cases. The same file draws the "before" pictures
/// when run on the commit before it, with its database.
const _pictures = String.fromEnvironment(
  'HONORIFIC_PICTURES',
  defaultValue: 'build/test_pictures/honorifics',
);

class _UnusedViewerBloc extends Fake implements ZikrContentViewerBloc {
  @override
  Stream<ZikrContentViewerState> get stream => const Stream.empty();
}

class _OpenSource extends StatefulWidget {
  final Zikr zikr;
  const _OpenSource(this.zikr);

  @override
  State<_OpenSource> createState() => _OpenSourceState();
}

class _OpenSourceState extends State<_OpenSource> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => showZikrSourceDialog(context, widget.zikr),
    );
  }

  @override
  Widget build(BuildContext context) => const Scaffold();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final zikr = <int, Zikr>{};
  late ZikrTitle title;

  setUpAll(() async {
    await loadAppFonts();
    sqfliteFfiInit();
    final database = await databaseFactoryFfi.openDatabase(
      File('assets/db/Al-Azkar.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    for (final row in await database.rawQuery(
      'SELECT * FROM contents WHERE id IN (1148, 1691, 1357, 17)',
    )) {
      zikr[row['id']! as int] = Zikr.fromMap(row);
    }
    title = ZikrTitle.fromMap(
      (await database.rawQuery('SELECT * FROM titles WHERE id = 156')).single,
    );
    await database.close();
  });

  Future<ThemeCubit> theme({
    ZikrFont font = ZikrFont.notoNaskh,
    Brightness brightness = Brightness.light,
  }) async {
    final cubit = ThemeCubit(
      ZikrTextRepo(MemoryStorage()),
      ThemeStorage(MemoryStorage()),
    );
    addTearDown(cubit.close);
    await cubit.changeZikrFont(font);
    await cubit.changeBrightness(brightness);
    return cubit;
  }

  Widget cards(ThemeCubit cubit, List<Zikr> shown) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(cubit.state),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: cubit),
              BlocProvider<ZikrContentViewerBloc>.value(
                value: _UnusedViewerBloc(),
              ),
            ],
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final z in shown)
                      ZikrItemCard(zikr: z, isCounted: z.count > 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  for (final font in ZikrFont.values) {
    testWidgets('case 1: zikr 1148 in ${font.label}', (tester) async {
      await drawScreenPicture(
        tester,
        path: '$_pictures/case1_${font.name}.png',
        size: const Size(412, 560),
        screen: cards(await theme(font: font), [zikr[1148]!]),
      );
    });
  }

  testWidgets('case 2: ﵀ and ﵃ in Amiri', (tester) async {
    await drawScreenPicture(
      tester,
      path: '$_pictures/case2_amiri.png',
      size: const Size(412, 520),
      screen: cards(
        await theme(font: ZikrFont.amiri),
        [zikr[1691]!, zikr[1357]!],
      ),
    );
  });

  testWidgets('case 3: the source dialog', (tester) async {
    final cubit = await theme();
    await drawScreenPicture(
      tester,
      path: '$_pictures/case3_source.png',
      size: const Size(412, 700),
      screen: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(cubit.state),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: _OpenSource(zikr[17]!),
        ),
      ),
    );
  });

  testWidgets('case 4: the shared image', (tester) async {
    final cubit = await theme();
    await drawScreenPicture(
      tester,
      path: '$_pictures/case4_share_image.png',
      size: const Size(1080, 1080),
      pixelRatio: 1,
      screen: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(cubit.state),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Material(
            child: ShareableImageCard(
              zikrTitle: title,
              zikr: zikr[1148]!,
              settings: const ShareableImageCardSettings.defaultSettings(),
            ),
          ),
        ),
      ),
    );
  });

  testWidgets('case 5: zikr 1148 at night', (tester) async {
    await drawScreenPicture(
      tester,
      path: '$_pictures/case5_night.png',
      size: const Size(412, 560),
      screen: cards(
        await theme(brightness: Brightness.dark),
        [zikr[1148]!],
      ),
    );
  });
}
