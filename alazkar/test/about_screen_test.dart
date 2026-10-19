import 'package:alazkar/src/core/constants/const.dart';
import 'package:alazkar/src/features/about/presentation/screens/about_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Set from the package info on app start; the screen shows it.
  kAppVersion = '1.0.0 (1)';

  testWidgets('the About screen credits the city data', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AboutScreen()));

    await tester.scrollUntilVisible(find.text('بيانات المدن'), 200);

    expect(find.text('بيانات المدن'), findsOneWidget);
    expect(find.textContaining('geonames.org'), findsOneWidget);
  });

  testWidgets('the source tile names the 10th edition and opens its page',
      (tester) async {
    final opened = <String>[];
    await tester.pumpWidget(
      MaterialApp(home: AboutScreen(openUrl: (url) async => opened.add(url))),
    );

    expect(
      find.text(
        'الكتاب: مختصر النصيحة في الأذكار والأدعية الصحيحة\n'
        'تأليف: محمد أحمد إسماعيل المقدم\n'
        'الطبعة العاشرة المعدلة، ١٤٤٦هـ - ٢٠٢٥م\n'
        'almukaddem.com',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('المصدر'));

    expect(opened, ['https://almukaddem.com/ar/3240']);
  });
}
