import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ScreenAwakeManager {
  static const MethodChannel channel = MethodChannel("screen_channel");

  /// Asks Android to keep the screen on (`FLAG_KEEP_SCREEN_ON`) or to let it
  /// time out again. Other platforms do nothing.
  static Future<void> keepOn(bool on) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await channel.invokeMethod('keep_screen_on', on);
    } on PlatformException {
      // The screen then times out as usual; nothing else is lost.
    }
  }
}
