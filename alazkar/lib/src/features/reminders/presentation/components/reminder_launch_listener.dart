import 'package:alazkar/app.dart';
import 'package:alazkar/src/core/di/dependency_injection.dart';
import 'package:alazkar/src/core/helpers/azkar_helper.dart';
import 'package:alazkar/src/features/reminders/data/models/reminder.dart';
import 'package:alazkar/src/features/reminders/data/reminder_platform.dart';
import 'package:alazkar/src/features/reminders/presentation/controller/reminders_cubit.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/screens/zikr_content_viewer_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The section titles exactly as the database holds them.
Future<Map<int, String>> loadReminderTitles(AzkarDBHelper db) async {
  return {
    for (final slot in ReminderSlot.values)
      slot.titleId: (await db.getTitlesById(slot.titleId)).name,
  };
}

/// Opens the section of a tapped reminder, and plans the reminders again
/// on every app start so the list never runs out while the app is used.
class ReminderLaunchListener extends StatefulWidget {
  final Widget child;

  const ReminderLaunchListener({super.key, required this.child});

  @override
  State<ReminderLaunchListener> createState() => _ReminderLaunchListenerState();
}

class _ReminderLaunchListenerState extends State<ReminderLaunchListener> {
  @override
  void initState() {
    super.initState();
    if (defaultTargetPlatform != TargetPlatform.android) return;
    ReminderChannel.onOpenTitle(_open);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final titleId = await ReminderChannel.takeLaunchTitleId();
      if (titleId != null) _open(titleId);
      await sl<RemindersCubit>().start();
    });
  }

  void _open(int titleId) {
    MyApp.navigatorKey.currentState?.push(
      ZikrContentViewerScreen.route(zikrTitleId: titleId),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
