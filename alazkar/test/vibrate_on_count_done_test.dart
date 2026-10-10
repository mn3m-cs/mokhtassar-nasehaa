import 'package:alazkar/src/core/manager/vibration_manager.dart';
import 'package:alazkar/src/core/models/zikr.dart';
import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:alazkar/src/features/settings/data/repository/settings_storage.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/controller/bloc/zikr_content_viewer_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Zikr zikr(int id, int count) => Zikr(
        id: id,
        titleId: 1,
        order: id,
        body: 'نص',
        source: '',
        fadl: '',
        hokm: '',
        count: count,
        search: '',
        sourceIndex: '',
      );

  ZikrContentViewerLoadedState state(List<Zikr> initial, List<Zikr> current) =>
      ZikrContentViewerLoadedState(
        zikrTitle: const ZikrTitle(id: 1, order: 1, name: 'قسم', freq: 'd'),
        azkar: current,
        activeZikrIndex: 0,
        initialCounts: {for (final z in initial) z.id: z.count},
      );

  group('the tap that completes a zikr', () {
    test('said three times ends on its last tap only', () {
      final s = state([zikr(1, 3)], [zikr(1, 3)]);

      expect(s.completesRepeated(zikr(1, 3)), isFalse);
      expect(s.completesRepeated(zikr(1, 2)), isFalse);
      expect(s.completesRepeated(zikr(1, 1)), isTrue);
    });

    test('said once never counts as repeated', () {
      final s = state([zikr(1, 1)], [zikr(1, 1)]);

      expect(s.completesRepeated(zikr(1, 1)), isFalse);
    });
  });

  group('settings', () {
    test('the vibration starts switched on', () {
      expect(SettingsStorage(MemoryStorage()).vibrateOnCountDone, isTrue);
    });

    test('switching it off is remembered', () async {
      final storage = SettingsStorage(MemoryStorage());

      await storage.changeVibrateOnCountDoneStatus(value: false);

      expect(storage.vibrateOnCountDone, isFalse);
    });
  });

  group('on Android', () {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final vibrationCalls = <String>[];
    final hapticCalls = <Object?>[];

    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      vibrationCalls.clear();
      hapticCalls.clear();
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          hapticCalls.add(call.arguments);
        }
        return null;
      });
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      messenger.setMockMethodCallHandler(VibrationManager.channel, null);
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });

    test('the vibration goes through the app channel', () async {
      messenger.setMockMethodCallHandler(VibrationManager.channel,
          (call) async {
        vibrationCalls.add(call.method);
        return null;
      });

      await VibrationManager.countDone();

      expect(vibrationCalls, ['count_done']);
      expect(hapticCalls, isEmpty);
    });

    test('a failing channel falls back to a strong haptic', () async {
      messenger.setMockMethodCallHandler(VibrationManager.channel,
          (call) => Future.error(PlatformException(code: 'no_vibrator')));

      await VibrationManager.countDone();

      expect(hapticCalls, ['HapticFeedbackType.heavyImpact']);
    });
  });
}
