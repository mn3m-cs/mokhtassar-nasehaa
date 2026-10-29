import 'package:alazkar/src/core/models/zikr.dart';

/// A home card as it was before the navigation became the book's index
/// (#220): its old name, and the azkar it opened, in their old order. The
/// index split some of these sections and renamed them all; a card still
/// opens what it used to, in one page.
class HomeCard {
  /// The id the section had before #220, which still keys the reader's
  /// counts and place on the card's page.
  final int id;
  final String name;

  /// `contents.id` of the azkar, as the section held them at `2688f25`.
  final List<int> zikrIds;

  /// A default favourite. Any other card is shown only to a reader who had
  /// saved its section before #220.
  final bool isDefault;

  /// Whether opening the card skips prose before its first zikr. A prose
  /// line ending in a colon is the instruction for the zikr after it, so it
  /// starts the card instead. Prose-only cards opt out.
  final bool startsAtFirstZikr;

  const HomeCard(
    this.id,
    this.name,
    this.zikrIds, {
    this.isDefault = true,
    this.startsAtFirstZikr = true,
  });

  /// The part of [azkar] shown when this card opens.
  ///
  /// The boundary is derived from the current database rows rather than a
  /// list of ids, so a new introductory passage is skipped automatically.
  List<Zikr> visibleAzkar(List<Zikr> azkar) {
    if (!startsAtFirstZikr) return azkar;
    final firstZikr = azkar.indexWhere(
      (zikr) => zikr.count > 0 || zikr.body.trimRight().endsWith(':'),
    );
    return azkar.sublist(firstZikr == -1 ? azkar.length : firstZikr);
  }

  /// The card's row in `favourite_titles`: its negated id, because the index
  /// section that kept the id, if any, is another favourite.
  int get favouriteId => -id;
}

const List<HomeCard> kHomeCards = [
  HomeCard(1, 'أذكار الصباح', [
    1228, 1229, 1230, 1231, 1232, 1, 2, 3, 4, 11, 5, 6, 9, 7, 8, 10, 12, //
    13, 14, 15, 16, 17, 18, 19, 23, 21, 24, 25, 26, 27, 1233, 1194, 1234, 28,
  ]),
  HomeCard(2, 'أذكار المساء', [
    1235, 32, 33, 34, 35, 38, 36, 37, 39, 41, 40, 43, 44, 45, 46, 47, 49, //
    52, 883, 884, 885, 1236, 886,
  ]),
  HomeCard(4, 'أذكار الاستيقاظ', [57, 58, 59]),
  HomeCard(
    9,
    'أذكار الأذان',
    [
      1533, 82, 1534, 1535, 1536, 1537, 1538, 1539, 83, 1540, 84, 85, 898, //
      1541, 899, 900, 901, 1542, 902, 1543, 903, 904, 1544, 905, 906, 1545,
    ],
    isDefault: false,
  ),
  HomeCard(16, 'ما يقول بعد الصلاة', [
    946, 1195, 134, 135, 136, 137, 138, 139, 140, 141, 1250, 143, 144, //
    1196, 947, 145, 948, 952, 956, 959, 1197, 148, 1198, 149, 1199, 1200, //
    962, 1201, 1202, 1203, 151, 152,
  ]),
  HomeCard(18, 'أذكار النوم', [
    157, 158, 1641, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, //
    170, 1642, 171, 172, 173, 963, 964, 965, 966, 967, 968, 174, 175, 1643,
    176,
  ]),
  HomeCard(49, 'أذكار المسافر', [
    1273, 298, 1274, 299, 300, 301, 1275, 1276, 1277, 302, 1278, 303, 1279, //
    304, 305, 1280, 306, 307, 882, 308, 309, 310, 311, 1281, 312, 1282, //
    313, 1283, 314, 315, 1284, 871, 872, 873, 1285, 874, 1286, 1287, 875, //
    1288, 1289,
  ]),
  HomeCard(
    176,
    'ورد التسبيح',
    [
      1761,
      1762,
      1763,
      1764,
      1765,
      1766,
      1767,
      1768,
      1769,
      1770,
      1771,
      1772,
      1773,
    ],
    isDefault: false,
    startsAtFirstZikr: false,
  ),
];

/// The card that had the section id [id] before #220, if any.
HomeCard? homeCardById(int id) {
  for (final card in kHomeCards) {
    if (card.id == id) return card;
  }
  return null;
}
