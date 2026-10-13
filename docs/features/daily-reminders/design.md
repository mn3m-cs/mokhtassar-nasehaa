# Design: Daily reminders for the morning, evening and sleep azkar

**Ticket:** #126 (daily reminders)
**Intent:** [intent.md](intent.md)
**Status:** Approved in conversation, section by section, on 2026-10-13. Revised 2026-10-13: entries hold local date and time instead of an absolute moment, so a time-zone change keeps the local time.
**Follow-up ticket:** #134 (periodic and spoken reminders), out of scope here

## Summary

The reader can turn on three daily reminders: «أذكار الصباح», «أذكار المساء» and «أذكار النوم». Each fires either at a time the reader picks or at a time tied to the prayer: half an hour after Fajr for the morning, half an hour after Asr or half an hour before Maghrib for the evening.

The Dart side computes the next 90 days of trigger times and hands them to Android. Android keeps the list and sets one system alarm at a time, so reminders keep coming while the app is closed, without running Dart in the background.

The work ships in two pull requests:

| Phase | Delivers |
|---|---|
| 1 | Fixed-time reminders: settings screen, notification, permission, reboot and clock-change handling |
| 2 | Prayer-relative times: prayer-time calculation, location, city list, calculation method |

## Decisions taken with the owner

| Decision | Choice |
|---|---|
| Sections | Morning (title 1), evening (title 2), sleep (title 18) |
| Default state | All off until the reader turns one on |
| Defaults on first turn-on | Morning: after Fajr + 30 min. Evening: after Asr + 30 min. Sleep: 22:00 |
| Evening options | Fixed time, Asr + 30 min, or Maghrib − 30 min |
| Notification text | The section's title from the book, nothing else |
| Lateness | Up to 15 minutes is acceptable, so no exact-alarm permission |
| Location | Approximate device location first; the city list if refused or unavailable |
| Scheduling approach | Precomputed 90-day list handed to Android (approach 1 of 3) |

The phase 1 default for the morning and evening is a fixed time (morning 06:00, evening 17:00), because prayer-relative times arrive only in phase 2.

## Approaches considered

1. **Precomputed 90-day list (chosen).** Dart computes every trigger time; Android stores the list and walks it. One source of truth for prayer times, no notification plugin, small size cost. It stops after 90 days without the app being opened; the last week's notifications say so.
2. **Prayer times computed in Kotlin.** Never runs out, but two implementations of the same calculation (Dart for display, Kotlin for scheduling) can drift apart.
3. **Notification plugin plus background Dart.** Quickest to write, but a clear size cost (#114, app size), and Xiaomi-type phones often kill background work, so notifications would not arrive.

## Components

### Dart

| Unit | Purpose | Depends on |
|---|---|---|
| `PrayerTimesCalculator` (phase 2) | Coordinates + method + madhab + date → Fajr, Asr, Maghrib | The prayer-times library only |
| `ReminderPlanner` | Settings + "now" (+ calculator in phase 2) → sorted list of `(local date, minute of day, titleId, title, body)` for the next 90 days | Pure; no platform calls |
| `ReminderStorage` | Reads and writes reminder settings, location and method on the existing `KVStorage` | `KVStorage` |
| `ReminderChannel` | Sends the list to Android; asks for the notification and location permissions; delivers "open section N" from a tapped notification | `MethodChannel("reminder_channel")` |
| `RemindersCubit` + `RemindersScreen` | The settings screen | All of the above |

A reminder setting is `{enabled, kind, minuteOfDay}`, where `kind` is one of `fixed`, `afterFajr`, `afterAsr`, `beforeMaghrib`. The 30-minute offset is a constant, not a setting.

### Android (Kotlin, no new library)

| Unit | Purpose |
|---|---|
| `ReminderScheduler` | Stores the list in `SharedPreferences`, converts each local date and minute to a moment in the phone's current time zone, drops past entries, and sets one inexact `AlarmManager.setWindow` alarm (15-minute window) for the earliest entry |
| `ReminderReceiver` | Fires on the alarm: posts the notification, then asks the scheduler for the next entry |
| `BootReceiver` | On `BOOT_COMPLETED`, `TIME_SET`, `TIMEZONE_CHANGED`: reschedules from the stored list |
| Notification | Channel «التذكير»; the title is the section's title from the book; tapping it opens `MainActivity` with the title id |

`MainActivity` passes the title id to Dart on a cold start and through `onNewIntent` when the app is already open. Dart pushes `ZikrContentViewerScreen.route(zikrTitleId:)` on top of the home screen through `App.navigatorKey`.

Permissions added: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, and in phase 2 `ACCESS_COARSE_LOCATION`. Neither exact-alarm permission is declared.

## Data flow

1. The reader changes a setting, or opens the app.
2. `ReminderPlanner` builds the 90-day list.
3. `ReminderChannel` hands it to Android.
4. `ReminderScheduler` stores it and sets an alarm for the earliest entry.
5. At that time `ReminderReceiver` posts the notification and sets the next alarm.
6. After a reboot or a clock change, `BootReceiver` sets the alarm again from the stored list.

Entries carry the local date and minute, not an absolute moment, so after a time-zone change the same list fires at the same local time. Entries more than an hour overdue (the phone was off) are dropped instead of shown late.

The notification titles are carried in the list, read from the database's titles table by id, so the Kotlin side contains no Arabic text of its own.

## Settings screen

A new «التذكير» entry in Settings opens a screen with three cards:

- **«أذكار الصباح»:** switch; time choice «وقت أختاره» or «بعد الفجر بنصف ساعة». For a fixed time, the time is shown and tappable. For a prayer-relative time, today's computed time is shown, for example «اليوم: ٥:١٢ ص».
- **«أذكار المساء»:** the same, with «وقت أختاره», «بعد العصر بنصف ساعة» and «قبل المغرب بنصف ساعة».
- **«أذكار النوم»:** switch and «وقت أختاره» only.
- **«الموقع» (phase 2),** shown only when a prayer-relative option is chosen:
  - the current city (nearest city to the device location, or the chosen one);
  - «تحديث موقعي» and «اختيار مدينة», the latter a searchable list;
  - «طريقة الحساب», set from the country and changeable;
  - «مذهب العصر»: الجمهور or الحنفي.

Permissions are asked in context only:
- **Notification:** when the first reminder is turned on.
- **Location:** when the first prayer-relative option is chosen. If refused, the city list opens.

## Prayer times and location (phase 2)

- **Library:** a small open-source prayer-times library, computing on the phone with no network. Its licence and size are checked before it is adopted. Times are computed in the phone's local time zone, so summer time follows automatically. For high latitudes the library's standard rule applies.
- **Default calculation method by country**, changeable by the reader. Once the reader picks a method, it stays even if the country changes.

  | Country | Method |
  |---|---|
  | Egypt, Sudan, Libya | Egyptian General Authority of Survey |
  | Saudi Arabia, Yemen | Umm al-Qura |
  | UAE, Qatar, Kuwait | Each country's own method |
  | Pakistan, India, Bangladesh | University of Islamic Sciences, Karachi |
  | Turkey | Diyanet |
  | North America | ISNA |
  | Anywhere else | Muslim World League |

- **Location:** the approximate location comes from Android's `LocationManager`, with no plugin. It is read once on request, stored on the phone, never sent anywhere and never tracked in the background.
- **City list:** capitals plus the major cities of the Muslim world, each with its Arabic name, country code and coordinates; about 500 entries. The source is open city data whose licence requires attribution, which goes on the About screen. The country is taken from the nearest city in the list, so no geocoding service is needed.
- **Privacy:** `privacy.md` and the Play data-safety form state that the approximate location is used only to compute prayer times and stays on the phone.

## Failure handling

| Situation | Behaviour |
|---|---|
| Notification permission refused | The switch returns to off; message «الإشعارات ممنوعة لهذا التطبيق، يمكنك السماح بها من إعدادات الهاتف»; nothing is scheduled |
| Permission revoked later in system settings | Checked on each app start; the card shows that notifications are blocked |
| Location refused or unavailable | The city list opens; if no city is chosen, the option falls back to «وقت أختاره» |
| List running out (under 7 days left, app not opened) | Those notifications carry a second line, «افتح التطبيق لتجديد التذكير». This is app text, not the book's, and is shown to the owner before release |
| Phone kills background apps | Unaffected: the system alarm wakes a receiver, with no background service. The screen links to the battery setting for readers whose notifications still do not arrive |

## Testing

| Level | What |
|---|---|
| Unit | Prayer times for Cairo and Makkah against the official tables (within 2 minutes); the 90-day list for each kind, including a summer-time change day; method by country; nearest city |
| Unit | Storage defaults and persistence; the cubit turns a reminder off when the permission is refused |
| Device journey (emulator) | Turn on a reminder, grant and refuse the permission, check `dumpsys alarm` for the pending alarm |
| Manual (emulator) | Reboot and time-zone change; fire the receiver and tap the notification with the app closed and open |
| Real phone | One full day of real reminders on the owner's phone |
| Size | Release APK size before and after each phase, recorded in the pull request |

## Out of scope

- Periodic or spoken reminders (#134).
- Reminders for other sections, or written by the reader.
- iOS, desktop and web; the Settings entry appears only on Android.
- The home-screen widget (#132) and saving reading progress (#127).
