import 'package:alazkar/src/core/models/zikr_title.dart';

/// How long a section keeps the reader's counts and place, by the kind of
/// azkar in it.
enum ProgressKeeping {
  /// The azkar of the day and night, said once a day: kept until midnight,
  /// with no starting again.
  forToday,

  /// Azkar said at each occasion, such as after every prayer: each opening
  /// starts at the top with the book's counts.
  none,

  /// The absolute azkar and supplications, and the pages about the book:
  /// kept until the reader starts again.
  always,
}

/// «أذكار الصباح», «أذكار المساء» and «أذكار النوم».
const Set<int> kDailyTitleIds = {1, 2, 18};

/// «حول الكتاب» and the chapters of the book's second part, «الأذكار
/// والأدعية المطلقة»: «أنواع وصيغ الأوراد المأثورة», «النوع الرابع عشر» and
/// «جامع أدعية القرآن المجيد والسنة الصحيحة». Every section under them, at any
/// depth, keeps its progress.
const Set<int> kKeptCategoryIds = {99, 140, 158, 191};

/// The sections of the second part that stand before its first chapter, at
/// the top of the navigation as its index prints them (#220).
const Set<int> kKeptTitleIds = {147, 192, 193, 194, 195, 196};

ProgressKeeping progressKeepingOf(ZikrTitle title, List<ZikrTitle> allTitles) {
  if (kDailyTitleIds.contains(title.id)) return ProgressKeeping.forToday;
  if (kKeptTitleIds.contains(title.id)) return ProgressKeeping.always;
  final parents = {for (final t in allTitles) t.id: t.parentId};
  for (int? id = title.parentId; id != null; id = parents[id]) {
    if (kKeptCategoryIds.contains(id)) return ProgressKeeping.always;
  }
  return ProgressKeeping.none;
}
