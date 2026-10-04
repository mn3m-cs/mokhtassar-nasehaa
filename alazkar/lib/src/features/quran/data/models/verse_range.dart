// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';

class VerseRange extends Equatable {
  final int startSura;
  final int startAyah;
  final int endingSura;
  final int endingAyah;

  const VerseRange(
    this.startSura,
    this.startAyah,
    this.endingSura,
    this.endingAyah,
  );

  const VerseRange.same(
    this.startSura,
    this.startAyah,
  )   : endingSura = startSura,
        endingAyah = startAyah;

  bool isSingleVerse() {
    return startAyah == endingAyah && startSura == endingSura;
  }

  /// A passage from the start of a surah is headed by the basmala, as the
  /// book prints it; one from the middle of a surah is not. Al-Fatiha's
  /// basmala is its first verse, already in the text, and At-Tawbah has none.
  bool get opensWithBasmala =>
      startAyah == 1 && startSura != 1 && startSura != 9;

  @override
  List<Object> get props => [startSura, startAyah, endingSura, endingAyah];
}
