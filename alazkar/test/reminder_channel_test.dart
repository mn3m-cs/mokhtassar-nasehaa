import 'package:alazkar/src/features/reminders/data/reminder_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void answer(Object? location) {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      ReminderChannel.channel,
      (call) async => call.method == 'requestLocation' ? location : null,
    );
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
      messenger.setMockMethodCallHandler(ReminderChannel.channel, null);
    });
  }

  test('the device location arrives as latitude and longitude', () async {
    answer({'latitude': 30.05, 'longitude': 31.24});

    expect(
      await ReminderChannel().requestLocation(),
      (latitude: 30.05, longitude: 31.24),
    );
  });

  test('a refused or missing location arrives as null', () async {
    answer(null);

    expect(await ReminderChannel().requestLocation(), isNull);
  });
}
