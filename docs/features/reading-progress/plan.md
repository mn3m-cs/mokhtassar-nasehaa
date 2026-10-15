# Plan: Remember counting progress and the reading position (#127)

**Ticket:** #127
**Branch:** `feat/reading-progress`, cut from `main`
**Status:** Approved for implementation

## Goal

Leaving a section half-way and coming back the same day finds the same
«أتممت n من m», the same remaining counts on each zikr, and the same zikr in
view. A new day starts fresh. The reader can start a section again from zero.

## Decisions

- **D1. A day is the phone's calendar date.** Progress saved on one date is
  ignored, and removed, on any later date. The rule lives in one function
  (`isSameReadingDay`) so a different boundary can replace it later without
  touching anything else.
- **D2. The position is a zikr, not a pixel offset.** The font size can change
  between visits, so the saved position is the id of the zikr in view
  (`activeZikr`). Reopening brings that zikr into view, the same way a search
  result does. A section opened from a search result (`zikrOrder` given) goes to
  that result, not to the saved position; its counts are still restored.
- **D3. Counts are saved by zikr id.** Only azkar whose remaining count differs
  from the book's count are stored. On restore, an id that is no longer in the
  list (the reader changed the source filter) is ignored, and every value is
  clamped to `0..initialCount`. `initialCounts` keep the book's counts, so
  «أتممت n من m» and the vibration on finishing a repeated zikr behave as
  before.
- **D4. Start again.** An icon button in the reader's app bar,
  `Icons.restart_alt` with the tooltip «البدء من جديد», shown only while some
  zikr in the section has been counted. It opens a dialog: title
  «إعادة العدّ من البداية؟», actions «إلغاء» and «إعادة». «إعادة» restores the
  book's counts, clears the saved progress for that section, and scrolls to the
  top.
- **D5. Every section is saved**, including sections with nothing to count:
  their reading position is still worth keeping.
- **D6. No new dependency.** Storage goes through the existing `KVStorage`.

## Rules for the implementer

- Every word the reader sees comes from the book, except UI labels, which are
  the app's own. The only new labels are the three in D4; use them verbatim.
- Format only the files you touch, with `fvm dart format <files>` (or
  `dart format <files>` if fvm is not installed). Never format the whole tree.
- `flutter analyze` must report no issues; `flutter test` must pass in full.
- Commit messages: plain English, imperative, no mention of Claude or AI, no
  `Co-Authored-By` line. Push to `feat/reading-progress`. Do not open a pull
  request and do not merge.
- Follow the surrounding code's style: short doc comments that say *why*, no
  comments that restate the code, names in the existing idiom.

## Task 1: `ReadingProgressStorage`

**File:** `alazkar/lib/src/features/zikr_content_viewer/data/repository/reading_progress_storage.dart`

```dart
class ReadingProgress {
  /// Remaining count by zikr id, only for azkar counted below the book's count.
  final Map<int, int> counts;

  /// The zikr that was in view.
  final int? zikrId;
  const ReadingProgress({required this.counts, this.zikrId});
}

bool isSameReadingDay(DateTime saved, DateTime now) =>
    saved.year == now.year && saved.month == now.month && saved.day == now.day;

class ReadingProgressStorage {
  ReadingProgressStorage(this._box, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  ReadingProgress? read(int titleId);   // null when absent, stale or corrupt; a stale or corrupt entry is removed
  Future<void> write(int titleId, ReadingProgress progress);
  Future<void> clear(int titleId);
}
```

- Key: `reading_progress_<titleId>`. Value: a JSON string
  `{"day":"2026-10-15","counts":{"12":3},"zikr":12}`, so the Hive box only ever
  holds a string.
- A value that does not parse, or has the wrong shape, reads as `null`; it never
  throws.
- Register it in `alazkar/lib/src/core/di/dependency_injection.dart` as a lazy
  singleton next to `ReminderStorage`.

**Tests:** `alazkar/test/reading_progress_storage_test.dart`, with
`test/support/memory_storage.dart` and an injected clock:
- written today, read today: same counts and zikr id;
- written yesterday, read today: `null`, and the key is gone;
- a corrupt value: `null`, no exception;
- `clear` removes it.

## Task 2: The bloc restores and saves

**Files:** `zikr_content_viewer_bloc.dart`, `_state.dart`, `_event.dart` in
`alazkar/lib/src/features/zikr_content_viewer/presentation/controller/bloc/`.

- The bloc takes a fifth constructor argument, `ReadingProgressStorage`; update
  the factory in `dependency_injection.dart`.
- `_start`: after filtering, read the progress for `event.zikrTitleId`. Apply
  the counts (D3) to the azkar list. When `event.zikrOrder` is null and the saved
  zikr id is in the list, set `activeZikrIndex` to it and put the id in a new
  state field `resumeZikrId` (nullable; add it to `props` and keep it through
  `copyWith`).
- `_decrease` and `_focus`: after emitting, write the progress: the counts that
  differ from `initialCounts`, and `activeZikr?.id`.
- A new `ZikrContentViewerRestartEvent`: restore the book's counts
  (`initialCounts`), set `activeZikrIndex` to 0, clear `resumeZikrId`, and
  `clear` the stored progress.
- A state getter `hasProgress`: true when any counted zikr's count is below its
  initial count.

**Tests:** `alazkar/test/zikr_viewer_progress_test.dart`. Build the bloc with a
fake `AzkarDBHelper` (`implements AzkarDBHelper`, returning a fixed title and
list), a real `SettingsStorage`, `ZikrFilterStorage` and
`ReadingProgressStorage` over `MemoryStorage`, and a fake `HomeBloc` or the real
one if it constructs cheaply. The constructor calls the volume-key channel, so
mock `VolumeButtonManager.channel` with
`TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler`.
Cover:
- count twice, close the bloc, start a new bloc on the same section: the same
  counts, the same `finishedCount`, and `resumeZikrId` is the zikr counted;
- the same, with the clock moved to the next day: the book's counts and no
  `resumeZikrId`;
- start with `zikrOrder` from a search: counts restored, `resumeZikrId` null,
  `activeZikrIndex` on the searched zikr;
- a saved id missing from the list, and a saved count above the book's count:
  ignored and clamped;
- restart: the book's counts, and a new bloc on that section finds nothing
  saved.

## Task 3: The screen

**File:** `alazkar/lib/src/features/zikr_content_viewer/presentation/screens/zikr_content_viewer_screen.dart`

- In `_onStateChange`, on a new section: after `jumpTo(0)`, bring
  `resumeZikrId` into view when there is no search focus.
- On restart (same section, every count back to the book's): `jumpTo(0)`.
- App-bar action before the bookmark button: the restart button and dialog
  from D4, shown when `state.hasProgress`. Give the button the key
  `ValueKey('reader-restart')`.

**Tests:** a widget test is optional here; the device journey in Task 4 covers
the screen.

## Task 4: Device journey

**File:** `alazkar/integration_test/app_journeys_test.dart`

Add a journey: open «أذكار الصباح», count a zikr until it is done and one more
tap on the next, note the «أتممت n من m» subtitle, go back to the index, open
the section again, and find the same subtitle. Then tap the restart button,
confirm with «إعادة», and find «أتممت 0 من m».

The VM has no emulator, so write this test but do not run it; say so in the
final report. Killing the app between visits is checked by hand on the
emulator afterwards.

## Done when

- `flutter analyze` is clean and `flutter test` passes in full.
- Tasks 1–4 are committed and pushed to `feat/reading-progress`.
- The final report lists each commit and anything left undone.
