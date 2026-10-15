import 'dart:async';

import 'package:alazkar/src/core/di/dependency_injection.dart';
import 'package:alazkar/src/features/reminders/data/models/reminder.dart';
import 'package:alazkar/src/features/reminders/data/reminder_platform.dart';
import 'package:alazkar/src/features/reminders/data/repository/city_repository.dart';
import 'package:alazkar/src/features/reminders/data/repository/reminder_storage.dart';
import 'package:alazkar/src/features/reminders/presentation/controller/reminders_cubit.dart';
import 'package:alazkar/src/features/reminders/presentation/screens/city_picker_screen.dart';
import 'package:alazkar/src/features/reminders/presentation/screens/reminders_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_storage.dart';
import 'support/test_cities.dart';

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

  LatLng? location;

  /// When set, the phone is still looking for its location.
  Completer<LatLng?>? pending;

  @override
  Future<LatLng?> requestLocation() =>
      pending?.future ?? Future.value(location);
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
      CityRepository(read: () async => kTestCitiesJson),
    );
    await cubit.start();
    sl.registerSingleton(cubit);
  });

  Widget app() => const MaterialApp(
        locale: Locale('ar', 'EG'),
        supportedLocales: [Locale('ar', 'EG')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: RemindersScreen(),
      );

  testWidgets(
      'the time is picked on the dial only, because typed Arabic-Indic '
      'hours are rejected by the picker', (tester) async {
    await tester.pumpWidget(app());
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
    await tester.pumpWidget(app());

    await tester.tap(find.byKey(const ValueKey('reminder-app-settings')));
    await tester.pumpAndSettle();

    expect(platform.settingsOpened, 1);
  });

  testWidgets(
      'the morning is set in minutes after Fajr, 5 to 60, and shows '
      "today's time; only sleep has a clock time", (tester) async {
    platform.location = (latitude: 30.01, longitude: 31.21);
    await tester.pumpWidget(app());

    await tester.tap(find.byKey(const ValueKey('reminder-switch-morning')));
    await tester.pumpAndSettle();

    final offset = tester.widget<DropdownButton<int>>(
      find.byKey(const ValueKey('reminder-offset-morning')),
    );
    expect(offset.value, 30);
    expect(offset.items!.map((item) => item.value), kOffsetChoices);
    expect(find.text('بعد الفجر'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('reminder-today-morning')), findsOneWidget);
    expect(find.textContaining('القاهرة'), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsOneWidget);
  });

  testWidgets('the evening offers after Asr or before Maghrib', (tester) async {
    platform.location = (latitude: 30.01, longitude: 31.21);
    await tester.pumpWidget(app());
    await tester.tap(find.byKey(const ValueKey('reminder-switch-evening')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('قبل المغرب'));
    await tester.pumpAndSettle();

    expect(
      sl<RemindersCubit>().state.settings[ReminderSlot.evening]!.kind,
      ReminderKind.beforeMaghrib,
    );
  });

  testWidgets(
      'a refused location opens the city list, and a picked city turns '
      'the morning on', (tester) async {
    await tester.pumpWidget(app());

    await tester.tap(find.byKey(const ValueKey('reminder-switch-morning')));
    await tester.pumpAndSettle();
    expect(find.byType(CityPickerScreen), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('city-search')), 'مكه');
    await tester.pumpAndSettle();
    expect(find.text('القاهرة'), findsNothing);
    await tester.tap(find.text('مكة المكرمة'));
    await tester.pumpAndSettle();

    expect(find.byType(CityPickerScreen), findsNothing);
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('reminder-switch-morning')),
          )
          .value,
      isTrue,
    );
    expect(find.text('مكة المكرمة، السعودية'), findsOneWidget);
  });

  testWidgets(
      'leaving the city list without a choice keeps the morning off and '
      'says a location is needed', (tester) async {
    await tester.pumpWidget(app());

    await tester.tap(find.byKey(const ValueKey('reminder-switch-morning')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('city-search')), 'لندن');
    await tester.pumpAndSettle();
    expect(find.text('لا توجد نتائج'), findsOneWidget);
    // pageBack() looks for the English "Back" tooltip; this app is in Arabic.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('reminder-switch-morning')),
          )
          .value,
      isFalse,
    );
    await tester.scrollUntilVisible(find.text(kLocationNeeded), 200);
    expect(find.text(kLocationNeeded), findsOneWidget);
    // Above the place card, so a short phone shows it without scrolling
    // past the card.
    expect(
      tester.getTopLeft(find.text(kLocationNeeded)).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey('reminder-place'))).dy,
      ),
    );
  });

  testWidgets(
      'the place card shows progress while the phone looks for its '
      'location', (tester) async {
    platform.pending = Completer<LatLng?>();
    await tester.pumpWidget(app());

    await tester.tap(find.byKey(const ValueKey('reminder-switch-morning')));
    await tester.pump();
    await tester.pump();

    await tester.scrollUntilVisible(find.byType(LinearProgressIndicator), 200);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    platform.pending!.complete((latitude: 30.01, longitude: 31.21));
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.textContaining('القاهرة'), findsOneWidget);
  });
}
