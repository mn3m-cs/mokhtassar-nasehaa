import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The report by shaking and its tip are gone (#240): the package is no
/// longer a dependency, and nothing in the app watches for a shake or counts
/// the reader's visits to show the tip. Every Dart file under `lib` is read,
/// so a file added later is checked too.
void main() {
  test('the shake package is not a dependency', () {
    for (final file in ['pubspec.yaml', 'pubspec.lock']) {
      expect(
        File(file).readAsStringSync(),
        isNot(contains(RegExp(r'^\s+shake:', multiLine: true))),
        reason: file,
      );
    }
  });

  test('no code in lib watches for a shake or shows the shake tip', () {
    final sources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();
    expect(sources, isNotEmpty);
    for (final file in sources) {
      final text = file.readAsStringSync();
      for (final trace in [
        'package:shake/',
        'ShakeDetector',
        'ShakeTutorialDialog',
        'has_shown_shake_tutorial',
        'viewer_open_count',
      ]) {
        expect(text, isNot(contains(trace)), reason: '${file.path}: $trace');
      }
    }
  });
}
