import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class VibrationManager {
  static const MethodChannel channel = MethodChannel("vibration_channel");

  /// Two short pulses that do not depend on the phone's touch-vibration
  /// setting, so a reader counting by the volume keys feels the end.
  static Future<void> countDone() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      await HapticFeedback.heavyImpact();
      return;
    }
    try {
      await channel.invokeMethod('count_done');
    } on PlatformException {
      await HapticFeedback.heavyImpact();
    }
  }
}
