import 'package:flutter_test/flutter_test.dart';

import 'support/screen_picture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the font check fails when the app fonts were not loaded', () {
    expect(
      checkArabicFontLoaded,
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('The app fonts were not loaded'),
        ),
      ),
    );
  });

  test('the font check passes after loadAppFonts', () async {
    await loadAppFonts();
    expect(checkArabicFontLoaded, returnsNormally);
  });
}
