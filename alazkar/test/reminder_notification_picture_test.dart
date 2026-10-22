import 'package:alazkar/src/features/reminders/data/models/reminder.dart';
import 'package:alazkar/src/features/reminders/domain/reminder_planner.dart';
import 'package:alazkar/src/features/reminders/domain/reminder_quotes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/screen_picture.dart';

/// Draws the text the planner chose for a reminder, as a notification would
/// show it, collapsed (first line) and opened (all lines). It is a test
/// picture: Android draws the real notification.
Widget _card({
  required Brightness brightness,
  required String title,
  required String body,
  required bool opened,
}) {
  final dark = brightness == Brightness.dark;
  final lines = body.split('\n');
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: 'Cairo', brightness: brightness),
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: dark ? const Color(0xFF121212) : Colors.grey.shade300,
        body: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Material(
              borderRadius: BorderRadius.circular(16),
              color: dark ? const Color(0xFF2B2B2B) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (opened)
                      Text(
                        lines.join('\n'),
                        style: const TextStyle(height: 1.6),
                      )
                    else
                      Text(
                        lines.first,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAppFonts);

  const titles = {1: 'أذكار الصباح', 2: 'أذكار المساء', 18: 'أذكار النوم'};
  const off = ReminderSetting(enabled: false, minuteOfDay: 0);

  PlannedReminder first(ReminderSlot slot, {int skip = 0}) => planReminders(
        settings: {
          for (final s in ReminderSlot.values)
            s: s == slot
                ? const ReminderSetting(enabled: true, minuteOfDay: 6 * 60)
                : off,
        },
        titles: titles,
        now: DateTime(2026, 10, 13, 5),
      )[skip];

  final longest = [
    for (final set in kReminderQuotes.entries)
      for (final q in set.value) (set.key, q),
  ].reduce((a, b) => a.$2.text.length >= b.$2.text.length ? a : b);

  (ReminderQuote, PlannedReminder) planned(PlannedReminder r) =>
      (quoteFor(r.titleId, r.at)!, r);

  final cases = <String, (ReminderQuote, PlannedReminder)>{
    'morning': planned(first(ReminderSlot.morning)),
    'last_week': planned(first(ReminderSlot.morning, skip: kReminderDays - 3)),
    'evening': planned(first(ReminderSlot.evening)),
    'sleep': planned(first(ReminderSlot.sleep)),
    'longest': (
      longest.$2,
      PlannedReminder(
        at: DateTime(2026, 10, 13, 6),
        titleId: longest.$1,
        title: titles[longest.$1]!,
        body: reminderBody(longest.$2),
      ),
    ),
  };

  for (final MapEntry(key: name, value: (quote, reminder)) in cases.entries) {
    for (final brightness in Brightness.values) {
      for (final opened in [false, true]) {
        if (!opened && name != 'morning') continue;
        final state = opened ? 'opened' : 'collapsed';
        testWidgets('$name $state ${brightness.name}', (tester) async {
          final path =
              'build/test_pictures/reminder_${name}_${state}_${brightness.name}.png';
          await drawScreenPicture(
            tester,
            path: path,
            size: const Size(412, 360),
            screen: _card(
              brightness: brightness,
              title: reminder.title,
              body: reminder.body,
              opened: opened,
            ),
          );
          expect(find.text(reminder.title), findsOneWidget);
          expect(
            opened
                ? find.textContaining('${quote.text}\n${quote.source}')
                : find.text(quote.text),
            findsOneWidget,
          );
        });
      }
    }
  }
}
