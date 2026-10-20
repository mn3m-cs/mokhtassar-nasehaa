import 'dart:io';

import 'package:alazkar/src/core/manager/screen_awake_manager.dart';
import 'package:alazkar/src/core/widgets/keep_screen_on.dart';
import 'package:alazkar/src/features/settings/data/repository/settings_storage.dart';
import 'package:alazkar/src/features/settings/presentation/components/keep_screen_on_switch.dart';
import 'package:alazkar/src/features/settings/presentation/controller/cubit/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_storage.dart';
import 'support/screen_picture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAppFonts);

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <Object?>[];

  setUp(() {
    // Widget tests run as Android by default, so no platform override.
    calls.clear();
    messenger.setMockMethodCallHandler(ScreenAwakeManager.channel,
        (call) async {
      expect(call.method, 'keep_screen_on');
      calls.add(call.arguments);
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(ScreenAwakeManager.channel, null);
  });

  Widget reader({required bool enabled}) => Directionality(
        textDirection: TextDirection.rtl,
        child: KeepScreenOn(enabled: enabled, child: const SizedBox()),
      );

  testWidgets('opening the reader with the switch on keeps the screen on',
      (tester) async {
    await tester.pumpWidget(reader(enabled: true));

    expect(calls, [true]);
  });

  testWidgets('leaving the reader lets the screen time out', (tester) async {
    await tester.pumpWidget(reader(enabled: true));
    await tester.pumpWidget(const SizedBox());

    expect(calls, [true, false]);
  });

  testWidgets('the background releases it and coming back asks again',
      (tester) async {
    await tester.pumpWidget(reader(enabled: true));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(calls, [true, false]);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(calls, [true, false, true]);
  });

  testWidgets('switching it off in the reader releases it', (tester) async {
    await tester.pumpWidget(reader(enabled: true));
    await tester.pumpWidget(reader(enabled: false));

    expect(calls, [true, false]);
  });

  testWidgets('with the switch off the screen is never asked to stay on',
      (tester) async {
    await tester.pumpWidget(reader(enabled: false));
    await tester.pumpWidget(const SizedBox());

    expect(calls, isEmpty);
  });

  test('the switch starts on and an off choice is remembered', () async {
    final storage = SettingsStorage(MemoryStorage());
    expect(storage.keepScreenOn, isTrue);

    await storage.changeKeepScreenOnStatus(value: false);

    expect(storage.keepScreenOn, isFalse);
  });

  for (final on in [true, false]) {
    testWidgets('the settings switch drawn ${on ? 'on' : 'off'}',
        (tester) async {
      final storage = MemoryStorage();
      await SettingsStorage(storage).changeKeepScreenOnStatus(value: on);
      final path =
          'build/test_pictures/keep_screen_on_${on ? 'on' : 'off'}.png';

      await drawScreenPicture(
        tester,
        path: path,
        screen: BlocProvider(
          create: (_) => SettingsCubit(SettingsStorage(storage)),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme:
                  ColorScheme.fromSeed(seedColor: const Color(0xFFFFF9EF)),
              fontFamily: 'Cairo',
            ),
            home: const Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(body: Center(child: KeepScreenOnSwitch())),
            ),
          ),
        ),
      );

      expect(find.text('إبقاء الشاشة مضاءة أثناء القراءة'), findsOneWidget);
      expect(
          tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, on);
      expect(File(path).existsSync(), isTrue);
    });
  }
}
