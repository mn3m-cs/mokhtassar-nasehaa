import 'package:alazkar/src/core/di/dependency_injection.dart';
import 'package:alazkar/src/features/reminders/data/models/reminder.dart';
import 'package:alazkar/src/features/reminders/data/reminder_platform.dart';
import 'package:alazkar/src/features/reminders/data/repository/reminder_storage.dart';
import 'package:alazkar/src/features/reminders/presentation/controller/reminders_cubit.dart';
import 'package:alazkar/src/features/reminders/presentation/screens/reminders_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_storage.dart';

class _GrantingPlatform implements ReminderPlatform {
  int settingsOpened = 0;

  @override
  Future<void> openAppSettings() async => settingsOpened++;

  @override
  Future<void> schedule(List<PlannedReminder> reminders) async {}

  @override
  Future<bool> notificationsAllowed() async => true;

  @override
  Future<bool> requestNotificationPermission() async => true;
}

void main() {
  late _GrantingPlatform platform;

  setUp(() async {
    await sl.reset();
    platform = _GrantingPlatform();
    final cubit = RemindersCubit(
      ReminderStorage(MemoryStorage()),
      platform,
      () async => {1: 'أذكار الصباح', 2: 'أذكار المساء', 18: 'أذكار النوم'},
    );
    await cubit.start();
    sl.registerSingleton(cubit);
  });

  testWidgets(
      'the time is picked on the dial only, because typed Arabic-Indic '
      'hours are rejected by the picker', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar', 'EG'),
        supportedLocales: [Locale('ar', 'EG')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: RemindersScreen(),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('reminder-switch-sleep')));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.schedule).last);
    await tester.pumpAndSettle();

    expect(find.byType(TimePickerDialog), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_outlined), findsNothing);
  });

  testWidgets(
      'the screen links to the phone settings for readers whose '
      'reminders do not arrive', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar', 'EG'),
        supportedLocales: [Locale('ar', 'EG')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: RemindersScreen(),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('reminder-app-settings')));
    await tester.pumpAndSettle();

    expect(platform.settingsOpened, 1);
  });
}
