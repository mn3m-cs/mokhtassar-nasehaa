# Store listing

Issue #128 updates only this directory. Play Console upload remains the owner's step.
The Arabic app screenshots are shared by the Arabic and English listings.

## Verification

From the repository root:

```sh
python3 fastlane/validate_metadata.py
```

This checks the exact approved titles and Arabic short description, Play's text
limits, six PNGs per locale, their 1080×1920 dimensions and byte-for-byte equality
between locales. Text counts exclude the final file newline.

From `alazkar/`, with the Flutter version in `.fvmrc` and Linux SQLite installed:

```sh
fvm flutter analyze
fvm flutter test
fvm flutter test ../fastlane/store_screenshots_test.dart
```

The six screenshot tests use `test/support/screen_picture.dart`, the real bundled
databases, Cairo and the other app fonts, the package's Material Symbols font,
`buildAppTheme`, and the production screens. Each capture is 360×640 logical
pixels at 3× (1080×1920 PNG). Output goes to `alazkar/build/store_screenshots/`.
Tests check loaded reader cards, the counter/source, real search results, PNG
size and Flutter rendering exceptions. The reminder platform is the existing
in-process implementation of `ReminderPlatform` used in tests; this draws the
reminders settings screen, not an Android notification. The city comes from the
bundled city data; the reminder date is fixed at 2026-10-29 with UTC+2.

To replace the listing images after reviewing the generated captures, from the
repository root:

```sh
cp alazkar/build/store_screenshots/*.png fastlane/metadata/android/ar/images/phoneScreenshots/
cp alazkar/build/store_screenshots/*.png fastlane/metadata/android/en-US/images/phoneScreenshots/
python3 fastlane/validate_metadata.py
```

## Review evidence for #128

`review/128/before/00–05.png` preserves the listing images from main `ded9d25`.
`review/128/before-after.png` pairs those six images with their replacements, in
order: index, section with counter, source dialog, night mode, reminders, search.
The originals are pasted at full size. The after pictures are **صورة اختبار**.

Regenerate the review sheet with Pillow installed:

```sh
python3 fastlane/compare_screenshots.py
```

The author credit was checked visually against PDF page 3 of
`book/mukhtasar-naseeha-10th-edition.pdf`: «تأليف محمد أحمد إسماعيل المقدم».
The page-by-page comparison statement follows the About screen; the completed
chapter comparisons and their merged PRs are recorded in `docs/book-map.md`.
