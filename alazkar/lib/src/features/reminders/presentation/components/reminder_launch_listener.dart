import 'package:alazkar/app.dart';
import 'package:alazkar/src/core/di/dependency_injection.dart';
import 'package:alazkar/src/core/helpers/azkar_helper.dart';
import 'package:alazkar/src/core/models/home_card.dart';
import 'package:alazkar/src/features/reminders/data/models/reminder.dart';
import 'package:alazkar/src/features/reminders/data/reminder_platform.dart';
import 'package:alazkar/src/features/reminders/presentation/controller/reminders_cubit.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/screens/zikr_content_viewer_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A reminder's title: the name of the home card it opens, or else the
/// section title exactly as the database holds it.
Future<Map<int, String>> loadReminderTitles(AzkarDBHelper db) async {
  return {
    for (final slot in ReminderSlot.values)
      slot.titleId: homeCardById(slot.titleId)?.name ??
          (await db.getTitlesById(slot.titleId)).name,
  };
}

/// Opens the section of a tapped reminder, and plans the reminders again
/// on every app start and every return to the app, so the list never runs
/// out while the app is used, even when it stays open for days.
class ReminderLaunchListener extends StatefulWidget {
  final Widget child;

  const ReminderLaunchListener({super.key, required this.child});

  @override
  State<ReminderLaunchListener> createState() => _ReminderLaunchListenerState();
}

class _ReminderLaunchListenerState extends State<ReminderLaunchListener>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    if (defaultTargetPlatform != TargetPlatform.android) return;
    WidgetsBinding.instance.addObserver(this);
    ReminderChannel.onOpenTitle(_open);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final titleId = await ReminderChannel.takeLaunchTitleId();
      if (titleId != null) _open(titleId);
      await sl<RemindersCubit>().start();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) sl<RemindersCubit>().start();
  }

  /// A reminder opens its home card, as the card on the home page does.
  void _open(int titleId) {
    MyApp.navigatorKey.currentState?.push(
      ZikrContentViewerScreen.route(
        zikrTitleId: titleId,
        card: homeCardById(titleId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
