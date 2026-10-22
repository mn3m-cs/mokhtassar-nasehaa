import 'package:alazkar/src/features/reminders/data/models/reminder.dart';
import 'package:alazkar/src/features/reminders/domain/reminder_planner.dart';
import 'package:alazkar/src/features/reminders/domain/reminder_quotes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const titles = {1: 'أذكار الصباح', 2: 'أذكار المساء', 18: 'أذكار النوم'};
  const off = ReminderSetting(enabled: false, minuteOfDay: 0);

  List<PlannedReminder> planOnly(ReminderSlot slot) => planReminders(
        settings: {
          for (final s in ReminderSlot.values)
            s: s == slot
                ? const ReminderSetting(enabled: true, minuteOfDay: 6 * 60)
                : off,
        },
        titles: titles,
        now: DateTime(2026, 10, 13, 5),
      );

  test('every reminder has its own set, of seven quotes or more', () {
    for (final slot in ReminderSlot.values) {
      expect(kReminderQuotes[slot.titleId], isNotNull, reason: slot.name);
      expect(kReminderQuotes[slot.titleId]!.length, greaterThanOrEqualTo(7));
    }
    final sets = {
      for (final set in kReminderQuotes.values) set.map((q) => q.text).join(),
    };
    expect(sets, hasLength(kReminderQuotes.length));
  });

  test('a quote is whole and each one names its speaker and its reporter', () {
    for (final set in kReminderQuotes.values) {
      expect(set.map((q) => q.text).toSet(), hasLength(set.length));
      for (final quote in set) {
        expect(quote.text.length, lessThanOrEqualTo(250));
        expect(quote.text, isNot(contains('\n')));
        expect(quote.source, startsWith('النبي ﷺ — '));
        expect(quote.source, matches('رواه|متفق|اتفق'));
      }
    }
  });

  test('each quote reads as the page it cites prints it, not cut short', () {
    // Marks, punctuation and Quran brackets are added for reading, so the
    // comparison is of the letters and the spaces between words.
    String letters(String s) => s
        .replaceAll(RegExp('[\u064B-\u0652\u0670ـ،؛:.,()﴿﴾«»]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    for (final set in kReminderQuotes.values) {
      for (final quote in set) {
        expect(quote.page, matches(r'^https://(www\.)?islamweb\.net/'));
        expect(letters(quote.text), letters(quote.reference),
            reason: quote.page);
      }
    }
  });

  test('no two reminders show the same quote on one day, over a year', () {
    final planned = planReminders(
      settings: {
        for (final s in ReminderSlot.values)
          s: const ReminderSetting(enabled: true, minuteOfDay: 6 * 60),
      },
      titles: titles,
      now: DateTime(2026, 10, 13, 5),
      days: 365,
    );
    final byDay = <DateTime, List<String>>{};
    for (final r in planned) {
      final quote = r.body.split('\n').firstWhere((l) => l != kRenewHint);
      byDay
          .putIfAbsent(DateTime(r.at.year, r.at.month, r.at.day), () => [])
          .add(quote);
    }
    expect(byDay, hasLength(365));
    for (final MapEntry(key: day, value: quotes) in byDay.entries) {
      expect(quotes, hasLength(ReminderSlot.values.length), reason: '$day');
      expect(quotes.toSet(), hasLength(quotes.length), reason: '$day');
    }
  });

  test('two reminders in a row never carry the same quote', () {
    for (final slot in ReminderSlot.values) {
      final planned = planOnly(slot);
      for (var i = 1; i < planned.length; i++) {
        expect(planned[i].body, isNot(planned[i - 1].body));
      }
    }
  });

  test('no quote returns within a week', () {
    for (final slot in ReminderSlot.values) {
      final planned = planOnly(slot).take(kReminderDays - kRenewHintDays);
      final texts = planned.map((r) => r.body).toList();
      for (var i = 0; i + 7 <= texts.length; i++) {
        expect(texts.sublist(i, i + 7).toSet(), hasLength(7));
      }
    }
  });

  test('each reminder shows a quote from its own set, under its title', () {
    for (final slot in ReminderSlot.values) {
      final set = kReminderQuotes[slot.titleId]!;
      final allowed = {for (final q in set) '${q.text}\n${q.source}'};
      for (final r in planOnly(slot).take(kReminderDays - kRenewHintDays)) {
        expect(r.title, titles[slot.titleId]);
        expect(allowed, contains(r.body));
      }
    }
  });

  test('the morning set holds a quote the sleep set does not', () {
    final morning = kReminderQuotes[1]!.map((q) => q.text).toSet();
    final sleep = kReminderQuotes[18]!.map((q) => q.text).toSet();
    expect(morning.difference(sleep), isNotEmpty);
    expect(sleep.difference(morning), isNotEmpty);
  });

  test('re-planning on another day keeps the quote of the same date', () {
    final first = planOnly(ReminderSlot.morning);
    final later = planReminders(
      settings: {
        ReminderSlot.morning: const ReminderSetting(
          enabled: true,
          minuteOfDay: 6 * 60,
        ),
        ReminderSlot.evening: off,
        ReminderSlot.sleep: off,
      },
      titles: titles,
      now: DateTime(2026, 10, 20, 5),
    );
    final date = DateTime(2026, 10, 25, 6);
    expect(
      later.firstWhere((r) => r.at == date).body,
      first.firstWhere((r) => r.at == date).body,
    );
  });

  test('a title with no set gets the renewal line alone, or nothing', () {
    expect(reminderBody(null), '');
    expect(reminderBody(null, renewHint: kRenewHint), kRenewHint);
    expect(quoteFor(99, DateTime(2026, 10, 13)), isNull);
  });
}
