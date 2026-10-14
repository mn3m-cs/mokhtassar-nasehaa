# Intent: Daily reminders for the morning, evening and sleep azkar

**Ticket:** #126 (daily reminders)
**Status:** Approved
**Revision:** 3
**Approval required before risky work:** No. The change adds a runtime permission and scheduled alarms, but touches no existing data and no content.

## Revision Log

| Rev | Date | Changed criteria | Reason |
| --- | --- | --- | --- |
| 1 | 2026-10-12 | — | Initial draft |
| 3 | 2026-10-14 | Scope, constraints, AC-008 | After trying phase 1, the owner ruled out a clock time for the morning and evening: their reminders are only «بعد الفجر» / «بعد العصر» / «قبل المغرب» by 5–60 minutes (default 30). Phases 1 and 2 ship together |
| 2 | 2026-10-13 | Scope, assumptions, AC-003, AC-008 to AC-010 | Owner added prayer-relative times and chose device location with a city-list fallback; design in [design.md](design.md) |

## Goal

A reader who turns on a reminder gets a notification every day at the time they chose. Tapping it opens that section of the book.

## Scope

**In scope**
- Three reminders, one each for «أذكار الصباح» (title 1), «أذكار المساء» (title 2) and «أذكار النوم» (title 18), each with its own on/off switch in Settings. The morning fires a chosen number of minutes after Fajr; the evening a chosen number of minutes after Asr or before Maghrib; sleep at a clock time the reader picks.
- The notification permission, asked for only when the reader turns a reminder on.
- Reminders keep working after a reboot, a time change and a time-zone change.
- Tapping the notification opens the section, whether the app was closed or already open.
- Prayer times are computed on the phone from the approximate device location, or from a city the reader picks. The offset is 5 to 60 minutes in steps of 5, default 30.

**Out of scope**
- Times tied to sunrise or sunset, or to prayers other than Fajr, Asr and Maghrib.
- Periodic or spoken reminders (#134).
- Reminders for other sections, or reminders the reader writes.
- iOS, desktop and web. The switches appear only on Android.
- A home-screen widget (#132).
- Saving reading progress (#127).

## Context

**Discovered facts**
- The app has no notifications, alarms or reminder code today.
- Sections open with `ZikrContentViewerScreen.route(zikrTitleId:)`, and `App.navigatorKey` is a global navigator key.
- `MainActivity` already hosts two method channels: `volume_button_channel` and `vibration_channel` (#125).
- `minSdkVersion` and `targetSdkVersion` come from Flutter 3.47.2 (min 24, target 36). Target 33 and above requires the runtime `POST_NOTIFICATIONS` permission.
- Settings are stored through `SettingsStorage` on a Hive key-value box, with a `SettingsCubit` and a switch widget per setting.
- App size is already an open concern (#114: 12.1 MB download).
- Owner rule: nothing the reader sees may be presented as the book's text unless it is the book's text. The book's section titles are the book's text.

**Product constraints (from the owner)**
- The owner chose the three sections and put reminders first (2026-10-10).
- Confirmed 2026-10-13: reminders are off until the reader turns one on; the notification shows the section's title from the book; up to 15 minutes late is acceptable.
- Added 2026-10-13: the morning half an hour after Fajr; the evening half an hour after Asr or before Maghrib. Location from the device first, a city list as the fallback.
- Defaults on first turn-on: morning after Fajr + 30 minutes, evening after Asr + 30 minutes, sleep 22:00.
- Ruled 2026-10-14: no clock time for the morning or evening (the morning azkar's time runs from after Fajr to sunrise). Phase 1 is not released on its own.

## Risk Review

| Risk area | Applies? | Required handling |
| --- | --- | --- |
| Security/privacy | Low | No data leaves the phone; no new network access. |
| Persistent data | Yes, settings only | New keys only; nothing existing is migrated. |
| External effects/cost | No | — |
| Platform policy | Yes | No `SCHEDULE_EXACT_ALARM` or `USE_EXACT_ALARM`. Notification permission requested in context. |
| App size | Yes | Measure the release size before and after (#114). |
| UX | Yes | Manual check on a real phone, in both themes. |

## Acceptance Criteria

### AC-001: Turning a reminder on asks for permission once, in context
- **Scenario:** fresh install on Android 13 or later, permission never asked.
- **Action:** the reader opens the app, then turns on the morning reminder.
- **Expected:** no permission prompt at first launch. The system prompt appears when the switch is turned on. If granted, the switch stays on and shows the time.
- **Must not:** ask on launch, or ask again after the reader denied it twice (Android stops showing the dialog then).
- **Verification:** device journey on an Android 13+ emulator.
- **Priority:** Required

### AC-002: Denied permission leaves the reminder off and explains why
- **Scenario:** the reader denies the permission.
- **Action:** the reader turns a reminder on.
- **Expected:** the switch returns to off, and a message says that notifications are blocked and can be allowed in the phone's settings.
- **Must not:** schedule an alarm that can never show.
- **Verification:** device journey with the permission revoked through `adb shell pm revoke`.
- **Priority:** Required

### AC-003: The notification arrives at the chosen time and shows only the book's title
- **Scenario:** the morning reminder is on, set to time T.
- **Action:** the device clock reaches T.
- **Expected:** a notification titled «أذكار الصباح» appears between T and T + 15 minutes, once.
- **Must not:** show any text that is not the section's title in the book, or fire twice for one day. The one exception is the renewal line when the 90-day list is almost used up (see the design), which the owner sees before release.
- **Verification:** unit tests for computing the next trigger time; on the emulator, `dumpsys alarm` shows one pending alarm per enabled reminder, and firing the receiver shows the notification in `dumpsys notification`.
- **Priority:** Required

### AC-004: Tapping the notification opens that section
- **Scenario:** a reminder notification is showing.
- **Action:** the reader taps it, once with the app closed and once with it open on another screen.
- **Expected:** the app shows that section (for example «أذكار النوم») on top of the home screen, so the back button returns home.
- **Verification:** device journey for the open-app case; manual check of the closed-app case on the emulator.
- **Priority:** Required

### AC-005: Reminders survive reboot and clock changes
- **Scenario:** two reminders are on.
- **Action:** reboot the device; separately, change the time zone.
- **Expected:** after each, `dumpsys alarm` shows the same reminders pending at the right local time.
- **Verification:** emulator, `adb reboot` and `adb shell cmd alarm set-timezone`.
- **Priority:** Required

### AC-006: Changing or turning off a reminder takes effect at once
- **Scenario:** the evening reminder is on at 17:00.
- **Action:** the reader changes it to 18:30, then turns it off.
- **Expected:** one alarm at 18:30 after the change, and none after turning it off.
- **Must not:** leave the old 17:00 alarm or a duplicate.
- **Verification:** emulator `dumpsys alarm`, plus a unit test of the settings logic.
- **Priority:** Required

### AC-007: No exact-alarm permission and a measured size cost
- **Scenario:** release build.
- **Action:** inspect the merged manifest and compare the release APK size with main.
- **Expected:** neither exact-alarm permission is declared; the size difference is recorded in the pull request.
- **Verification:** `aapt dump permissions`, plus the APK size before and after.
- **Priority:** Important

### AC-008: A prayer-relative reminder follows the day's prayer time (phase 2)
- **Scenario:** the morning reminder is set to 30 minutes after Fajr, with Cairo as the location. The reader can choose 5 to 60 minutes in steps of 5, and for the evening either after Asr or before Maghrib; there is no clock time for either.
- **Action:** compute the planned times for the next 90 days.
- **Expected:** each day's time is that day's Fajr in Cairo plus 30 minutes, within 2 minutes of the official Egyptian timetable.
- **Verification:** unit test against published timetables for Cairo and Makkah.
- **Priority:** Required

### AC-009: Location comes from the device, or from the city list when refused (phase 2)
- **Scenario:** the reader turns on the morning or evening reminder for the first time.
- **Action:** grant, then on a fresh install refuse, the approximate-location permission.
- **Expected:** if granted, the nearest city's name is shown; if refused, the city list opens; with no city chosen, the morning or evening reminder stays off and the screen says a location is needed.
- **Must not:** send the location anywhere, or read it in the background.
- **Verification:** device journey with the permission granted and revoked; code review that no network call is made.
- **Priority:** Required

### AC-010: The calculation method follows the country unless the reader picked one (phase 2)
- **Scenario:** the location is in Egypt, then moves to Saudi Arabia.
- **Action:** update the location.
- **Expected:** the method changes from the Egyptian authority to Umm al-Qura; if the reader had picked a method by hand, it stays.
- **Verification:** unit test.
- **Priority:** Important

## Blocking Decisions

None. The owner confirmed the product choices on 2026-10-13.

## Verification Plan

| Criterion | Evidence | Status |
| --- | --- | --- |
| AC-001 | Emulator API 34, fresh install: no prompt at launch, system prompt when the switch is turned on | Verified (phase 1 pull request) |
| AC-002 | Emulator: deny → switch off, blocked line, no alarm; `pm revoke` → blocked line on next launch; `reminders_cubit_test.dart` | Verified |
| AC-003 | `reminder_planner_test.dart`; emulator notifications titled from the database, inside the window. Under power saving (Doze) an inexact alarm can arrive later than 15 minutes; it is then still shown (`ReminderDueTest`) | Verified, with the Doze caveat |
| AC-004 | Emulator: tap with the app closed, with another section open, and with a share sheet above the app | Verified |
| AC-005 | Emulator: time zone moved to Asia/Dubai kept the local time; power-off across a reminder showed it on boot | Verified |
| AC-006 | `reminders_cubit_test.dart`; emulator: one alarm after each change | Verified |
| AC-007 | No exact-alarm permission; arm64 APK 22,711,350 → 23,039,974 bytes (+321 KB) | Verified |
| AC-008 | Unit test against timetables | Pending |
| AC-009 | Device journey, permission granted and revoked | Pending |
| AC-010 | Unit test | Pending |
