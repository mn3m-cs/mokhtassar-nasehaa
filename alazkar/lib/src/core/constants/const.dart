import 'package:alazkar/src/core/extension/extension_platform.dart';

late final String kAppVersion;

const String kEstaaza =
    "أَعُوذُ بِاللَّهِ (السَّمِيعِ الْعَلِيمِ) مِنَ الشَّيْطَانِ الرَّجِيمِ (مِنْ هَمْزِهِ وَنَفْخِهِ وَنَفْثِهِ)";
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

const String kDeveloperEmail = "muslimpack.org@gmail.com";
