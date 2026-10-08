import 'package:alazkar/src/core/models/zikr.dart';
import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:alazkar/src/features/share_as_image/data/models/shareable_image_card_settings.dart';
import 'package:alazkar/src/features/share_as_image/presentation/components/shareable_image_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const zikrTitle = ZikrTitle(id: 1, order: 1, name: 'أذكار الصباح', freq: 'd');
  const zikr = Zikr(
    id: 1,
    titleId: 1,
    order: 1,
    body: 'أستغفرُ اللهَ',
    source: '',
    fadl: '',
    hokm: '',
    count: 100,
    search: '',
    sourceIndex: '',
  );

  Future<ColorScheme> pumpCard(
      WidgetTester tester, Brightness brightness) async {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.brown,
      brightness: brightness,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: colorScheme),
        home: const FittedBox(
          child: ShareableImageCard(
            zikrTitle: zikrTitle,
            zikr: zikr,
            settings: ShareableImageCardSettings.defaultSettings(),
          ),
        ),
      ),
    );
    return colorScheme;
  }

  Color background(WidgetTester tester) => tester
      .widget<Container>(
        find
            .descendant(
              of: find.byType(ShareableImageCard),
              matching: find.byType(Container),
            )
            .first,
      )
      .color!;

  Color bodyColor(WidgetTester tester) =>
      tester.widget<Text>(find.text('أستغفرُ اللهَ')).style!.color!;

  testWidgets('light mode draws a light image with dark text', (tester) async {
    final colorScheme = await pumpCard(tester, Brightness.light);

    expect(background(tester), colorScheme.surface);
    expect(bodyColor(tester), colorScheme.onSurface);
  });

  testWidgets('night mode keeps the dark image with white text',
      (tester) async {
    await pumpCard(tester, Brightness.dark);

    expect(background(tester), const Color(0xff1a110e));
    expect(bodyColor(tester), Colors.white);
  });
}
