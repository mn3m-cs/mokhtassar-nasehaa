/// The typefaces a reader can choose for the azkar text. Quranic verses keep
/// the Uthmanic Hafs script whatever the choice.
enum ZikrFont {
  notoNaskh("NotoNaskhArabic", "نوتو نسخ"),
  kitab("Kitab", "كتاب"),
  amiri("Amiri", "أميري");

  final String family;
  final String label;
  const ZikrFont(this.family, this.label);
}
