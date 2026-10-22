import 'dart:io';

import 'package:alazkar/src/core/models/zikr.dart';
import 'package:alazkar/src/features/settings/data/repository/zikr_text_repo.dart';
import 'package:alazkar/src/features/theme/domain/repository/theme_storage.dart';
import 'package:alazkar/src/features/theme/presentation/controller/cubit/theme_cubit.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/components/zikr_item_card.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/controller/bloc/zikr_content_viewer_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/memory_storage.dart';
import 'support/screen_picture.dart';

/// Draws «من آداب الرؤيا» (pp135-136) card by card from a database, to show
/// the list numbers and count brackets of #227. The database comes from
/// `--dart-define=LIST_NUMBERS_DB=<file>` (the bundled one by default), and
/// the picture goes to `--dart-define=LIST_NUMBERS_PICTURE=<file>`.
const _database = String.fromEnvironment(
  'LIST_NUMBERS_DB',
  defaultValue: 'assets/db/Al-Azkar.db',
);
const _picture = String.fromEnvironment(
  'LIST_NUMBERS_PICTURE',
  defaultValue: 'build/test_pictures/list_numbers_dreams.png',
);

/// The card's menu holds the section's bloc; drawing never uses it.
class _UnusedViewerBloc extends Fake implements ZikrContentViewerBloc {
  @override
  Stream<ZikrContentViewerState> get stream => const Stream.empty();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Zikr> dreams;

  setUpAll(() async {
    await loadAppFonts();
    sqfliteFfiInit();
    final database = await databaseFactoryFfi.openDatabase(
      File(_database).absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    dreams = (await database.rawQuery(
      'SELECT * FROM contents WHERE titleId = 30 ORDER BY "order"',
    ))
        .map(Zikr.fromMap)
        .toList();
    await database.close();
  });

  testWidgets('«من آداب الرؤيا» picture', (tester) async {
    final themeCubit = ThemeCubit(
      ZikrTextRepo(MemoryStorage()),
      ThemeStorage(MemoryStorage()),
    );
    addTearDown(themeCubit.close);

    await drawScreenPicture(
      tester,
      path: _picture,
      size: const Size(412, 2700),
      screen: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFFF9EF),
          ),
          fontFamily: 'Cairo',
        ),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: themeCubit),
              BlocProvider<ZikrContentViewerBloc>.value(
                value: _UnusedViewerBloc(),
              ),
            ],
            child: Scaffold(
              appBar: AppBar(title: const Text('من آداب الرؤيا')),
              body: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 6, bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final zikr in dreams)
                      ZikrItemCard(zikr: zikr, isCounted: zikr.count > 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(File(_picture).existsSync(), isTrue);
  });
}
