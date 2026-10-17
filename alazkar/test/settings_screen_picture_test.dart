import 'dart:io';

import 'package:alazkar/src/features/settings/data/repository/settings_storage.dart';
import 'package:alazkar/src/features/settings/data/repository/zikr_text_repo.dart';
import 'package:alazkar/src/features/settings/presentation/controller/cubit/settings_cubit.dart';
import 'package:alazkar/src/features/settings/presentation/screens/settings_screen.dart';
import 'package:alazkar/src/features/theme/domain/repository/theme_storage.dart';
import 'package:alazkar/src/features/theme/presentation/controller/cubit/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_storage.dart';
import 'support/screen_picture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAppFonts);

  testWidgets('the Settings screen is drawn with the real Arabic font',
      (tester) async {
    final storage = MemoryStorage();
    const path = 'build/test_pictures/settings_screen.png';

    await drawScreenPicture(
      tester,
      path: path,
      screen: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => SettingsCubit(SettingsStorage(storage))),
          BlocProvider(
            create: (_) =>
                ThemeCubit(ZikrTextRepo(storage), ThemeStorage(storage)),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFFF9EF),
            ),
            fontFamily: 'Cairo',
          ),
          localizationsDelegates: const [
            GlobalCupertinoLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ar', 'EG')],
          home: const SettingsScreen(),
        ),
      ),
    );

    expect(find.text('الإعدادات'), findsOneWidget);
    final file = File(path);
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), greaterThan(10000));
  });
}
