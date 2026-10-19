import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class VibrationManager {
  static const MethodChannel channel = MethodChannel("vibration_channel");

  /// One pulse of 250 ms that does not depend on the phone's touch-vibration
  /// setting on any Android version (media usage: AudioAttributes on 8 to 12,
  /// VibrationAttributes from 13), so a reader counting by the volume keys
  /// feels the end. Only the app's own switch turns it off.
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
