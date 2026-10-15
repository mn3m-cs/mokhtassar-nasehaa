import 'package:alazkar/src/features/reminders/data/models/reminder.dart';
import 'package:alazkar/src/features/reminders/data/reminder_platform.dart';

class FakeReminderPlatform implements ReminderPlatform {
  bool allowed;
  bool grants;
  final List<List<PlannedReminder>> scheduled = [];
  int settingsOpened = 0;
  LatLng? location;
  int locationRequests = 0;

  FakeReminderPlatform(
      {this.allowed = true, this.grants = true, this.location});

  @override
  Future<void> schedule(List<PlannedReminder> reminders) async =>
      scheduled.add(reminders);

  @override
  Future<bool> notificationsAllowed() async => allowed;

  @override
  Future<void> openAppSettings() async => settingsOpened++;

  @override
  Future<bool> requestNotificationPermission() async {
    allowed = grants;
    return grants;
  }

  @override
  Future<LatLng?> requestLocation() async {
    locationRequests++;
    return location;
  }
}
