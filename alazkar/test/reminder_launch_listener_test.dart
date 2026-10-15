import 'package:alazkar/src/core/di/dependency_injection.dart';
import 'package:alazkar/src/features/reminders/data/reminder_platform.dart';
import 'package:alazkar/src/features/reminders/data/repository/city_repository.dart';
import 'package:alazkar/src/features/reminders/data/repository/reminder_storage.dart';
import 'package:alazkar/src/features/reminders/presentation/components/reminder_launch_listener.dart';
import 'package:alazkar/src/features/reminders/presentation/controller/reminders_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_reminder_platform.dart';
import 'support/memory_storage.dart';
import 'support/test_cities.dart';

void main() {
  late FakeReminderPlatform platform;

  setUp(() async {
    await sl.reset();
    platform = FakeReminderPlatform();
    sl.registerSingleton(
      RemindersCubit(
        ReminderStorage(MemoryStorage()),
        platform,
        () async => {1: 'أذكار الصباح', 2: 'أذكار المساء', 18: 'أذكار النوم'},
        CityRepository(read: () async => kTestCitiesJson),
      ),
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ReminderChannel.channel, (_) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ReminderChannel.channel, null);
  });

  testWidgets(
      'coming back to an app left open plans the reminders again, so the '
      'list never runs out', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(
      const MaterialApp(home: ReminderLaunchListener(child: SizedBox())),
    );
    await tester.pumpAndSettle();
    final afterStart = platform.scheduled.length;
    expect(afterStart, greaterThan(0));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(platform.scheduled.length, greaterThan(afterStart));
    debugDefaultTargetPlatformOverride = null;
  });
}
