/// The typefaces a reader can choose for the azkar text. Quranic verses keep
/// the Uthmanic Hafs script whatever the choice.
enum ZikrFont {
  kitab("Kitab", "كتاب"),
  amiri("Amiri", "أميري"),
  notoNaskh("NotoNaskhArabic", "نوتو نسخ");

  final String family;
  final String label;
  const ZikrFont(this.family, this.label);
}
