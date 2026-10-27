import 'package:alazkar/src/core/extension/extension_platform.dart';

late final String kAppVersion;

const String kArBasmallah = "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ";
const Iterable<int> kArabicDiacriticsChar = [
  1617,
  124,
  1614,
  124,
  1611,
  124,
  1615,
  124,
  1612,
  124,
  1616,
  124,
  1613,
  124,
  1618,
];

String kGetStorageName =
    PlatformExtension.isDesktop ? "alazkar_storage" : "GetStorage";
String kHiveBoxName = "alazkar_box";

const double kFontChangeBy = 2;
const double kFontDefault = 30;
const double kFontMin = 15;
const double kFontMax = 45;

const String kDeveloperEmail = "mohamedabdo581@gmail.com";

/// The font that draws the book's honorific glyphs (ﷺ ﵁ ﷿ …) where the
/// reader's font has none of them (#213).
const List<String> kGlyphFallback = ['NotoNaskhArabic'];

/// Each honorific glyph the book prints, and the words it stands for. Copied
/// and sent text, and the screen reader, use the words: the receiving phone
/// may have no font for the glyphs of 2021 (﵀–﵄).
const Map<String, String> kHonorificWords = {
  'ﷺ': 'صلى الله عليه وسلم',
  '﵄': 'رضي الله عنهما',
  '﵃': 'رضي الله عنهم',
  '﵂': 'رضي الله عنها',
  '﵁': 'رضي الله عنه',
  '﵀': 'رحمه الله',
  '﷾': 'سبحانه وتعالى',
  '﷿': 'عز وجل',
  'ﷻ': 'جل جلاله',
};
