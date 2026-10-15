import 'dart:async';
import 'dart:convert';

import 'package:alazkar/src/core/storage/kv_storage.dart';

class ReadingProgress {
  /// Remaining count by zikr id, only for azkar counted below the book's count.
  final Map<int, int> counts;

  /// The zikr that was in view.
  final int? zikrId;

  const ReadingProgress({required this.counts, this.zikrId});
}

/// Progress is kept for the calendar day it was saved on; the azkar of a new
/// day start fresh.
bool isSameReadingDay(DateTime saved, DateTime now) =>
    saved.year == now.year && saved.month == now.month && saved.day == now.day;

class ReadingProgressStorage {
  final KVStorage _box;
  final DateTime Function() _now;

  ReadingProgressStorage(this._box, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  static String _key(int titleId) => 'reading_progress_$titleId';

  static String _day(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Null when nothing is saved, or the saved entry is from an earlier day or
  /// unreadable; such an entry is removed.
  ReadingProgress? read(int titleId) {
    final key = _key(titleId);
    final raw = _box.read<Object>(key);
    if (raw == null) return null;

    final progress = _parse(raw);
    if (progress == null) unawaited(_box.remove(key));
    return progress;
  }

  ReadingProgress? _parse(Object raw) {
    try {
      if (raw is! String) return null;
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;

      final day = DateTime.tryParse(json['day'] as String);
      if (day == null || !isSameReadingDay(day, _now())) return null;

      final counts = (json['counts'] as Map<String, dynamic>).map(
        (id, count) => MapEntry(int.parse(id), count as int),
      );
      return ReadingProgress(counts: counts, zikrId: json['zikr'] as int?);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(int titleId, ReadingProgress progress) {
    return _box.write(
      _key(titleId),
      jsonEncode({
        'day': _day(_now()),
        'counts': {
          for (final entry in progress.counts.entries)
            '${entry.key}': entry.value,
        },
        'zikr': progress.zikrId,
      }),
    );
  }

  Future<void> clear(int titleId) => _box.remove(_key(titleId));
}
