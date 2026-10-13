import 'package:alazkar/src/features/reminders/data/models/reminder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract class ReminderPlatform {
  Future<void> schedule(List<PlannedReminder> reminders);
  Future<bool> notificationsAllowed();
  Future<bool> requestNotificationPermission();

  /// The app's page in the phone settings, where notifications and
  /// background work are allowed.
  Future<void> openAppSettings();
}

class ReminderChannel implements ReminderPlatform {
  static const MethodChannel channel = MethodChannel('reminder_channel');

  static bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<void> schedule(List<PlannedReminder> reminders) async {
    if (!_isAndroid) return;
    await channel.invokeMethod<void>(
      'schedule',
      reminders.map((reminder) => reminder.toMap()).toList(),
    );
  }

  @override
  Future<bool> notificationsAllowed() async {
    if (!_isAndroid) return false;
    return await channel.invokeMethod<bool>('notificationsAllowed') ?? false;
  }

  @override
  Future<bool> requestNotificationPermission() async {
    if (!_isAndroid) return false;
    return await channel.invokeMethod<bool>('requestNotificationPermission') ??
        false;
  }

  @override
  Future<void> openAppSettings() async {
    if (!_isAndroid) return;
    await channel.invokeMethod<void>('openAppSettings');
  }

  /// The section a tapped notification asked for when it started the app.
  static Future<int?> takeLaunchTitleId() async {
    if (!_isAndroid) return null;
    return channel.invokeMethod<int>('takeLaunchTitleId');
  }

  /// Called when a notification is tapped while the app is already running.
  static void onOpenTitle(void Function(int titleId) open) {
    channel.setMethodCallHandler((call) async {
      if (call.method == 'openTitle') open(call.arguments as int);
    });
  }
}
