import 'package:alazkar/app.dart';
import 'package:alazkar/services.dart';
import 'package:alazkar/src/core/manager/vibration_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Journeys through the real app on a device: bundled database, storage and
/// navigation, nothing mocked. Run on a fresh install:
/// `fvm flutter test integration_test --flavor prod -d <device>`.
///
/// The app's blocs are singletons that close with the app, so the journeys
/// run in order inside one app session, returning home between them.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initServices);

  Future<void> backHome(WidgetTester tester) async {
    while (find.byTooltip('البحث').evaluate().isEmpty) {
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }
  }

  Future<void> dismissTip(WidgetTester tester) async {
    final gotIt = find.text('فهمت');
    if (gotIt.evaluate().isNotEmpty) {
      await tester.tap(gotIt);
      await tester.pumpAndSettle();
    }
  }

  Future<void> openSection(WidgetTester tester, String name) async {
    await tester.tap(find.text(name).first);
    // The shake tip, shown on the third section opened, loops its
    // animation and never settles, so wait a fixed time before closing it.
    await tester.pump(const Duration(seconds: 2));
    await dismissTip(tester);
    await tester.pumpAndSettle();
  }

  testWidgets('core reading journeys', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Default favourites are the home tiles, in book order (right to left,
    // then down).
    const expected = [
      'أذكار الصباح',
      'أذكار المساء',
      'أذكار الاستيقاظ',
      'ما يقول بعد الصلاة',
      'أذكار النوم',
      'أذكار المسافر',
    ];
    final positions = {
      for (final name in expected)
        name: tester.getCenter(find.text(name).first),
    };
    final readingOrder = [...expected]..sort((a, b) {
        final pa = positions[a]!;
        final pb = positions[b]!;
        if ((pa.dy - pb.dy).abs() > 20) return pa.dy.compareTo(pb.dy);
        return pb.dx.compareTo(pa.dx);
      });
    expect(readingOrder, expected, reason: 'favourite tiles in book order');

    // The vibration's native side is the only thing replaced, so the
    // journey can see when the app asks the phone to vibrate.
    final vibrations = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      VibrationManager.channel,
      (call) async {
        vibrations.add(call.method);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(VibrationManager.channel, null),
    );

    // Tapping a zikr's text counts it and marks it done in the header.
    await openSection(tester, 'أذكار الصباح');
    expect(find.text('أتممت 0 من 27'), findsOneWidget);
    await tester
        .tap(find.textContaining('أصبحنا على', findRichText: true).first);
    await tester.pumpAndSettle();
    expect(find.text('أتممت 1 من 27'), findsOneWidget, reason: 'counted');
    expect(
      find.bySemanticsLabel(RegExp('تم العدّ')),
      findsOneWidget,
      reason: 'done',
    );
    expect(vibrations, isEmpty, reason: 'a zikr said once does not vibrate');

    // A zikr said three times vibrates on its third tap, not before.
    final radeetu = find.textContaining('رَضِيتُ باللهِ', findRichText: true);
    for (var tap = 1; tap <= 3; tap++) {
      await tester.ensureVisible(radeetu.first);
      await tester.pumpAndSettle();
      await tester.tap(radeetu.first);
      await tester.pumpAndSettle();
      expect(vibrations, tap < 3 ? isEmpty : ['count_done'],
          reason: 'tap $tap');
    }
    expect(find.text('أتممت 2 من 27'), findsOneWidget);

    // The section ends with the next section in book order.
    await tester.scrollUntilVisible(
      find.text('الباب التالي'),
      600,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('الباب التالي'));
    await tester.pumpAndSettle();
    await dismissTip(tester);
    expect(find.text('أتممت 0 من 25'), findsOneWidget, reason: 'next section');
    expect(find.text('أذكار المساء'), findsWidgets);

    // ...and leads back to the previous one.
    await tester.scrollUntilVisible(
      find.text('الباب السابق'),
      600,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('الباب السابق'));
    await tester.pumpAndSettle();
    expect(
      find.text('أتممت 0 من 27'),
      findsOneWidget,
      reason: 'previous section',
    );
    await backHome(tester);

    // Searching the index finds a section.
    await tester.tap(find.byTooltip('البحث'));
    await tester.pumpAndSettle();
    expect(
      find.text('اكتب كلمة للبحث في الفهرس أو في نصوص الأذكار'),
      findsOneWidget,
      reason: 'search prompt',
    );
    await tester.enterText(find.byType(TextFormField), 'النوم');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(
      find.textContaining('أذكار النوم'),
      findsWidgets,
      reason: 'search result',
    );

    // A section opened from search returns to the index, search closed.
    await openSection(tester, 'أذكار النوم');
    await tester.scrollUntilVisible(
      find.text('العودة إلى الفهرس'),
      600,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('العودة إلى الفهرس'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNothing, reason: 'search closed');
    expect(find.byTooltip('البحث'), findsOneWidget, reason: 'on the index');

    // The back key closes search instead of leaving the app.
    await tester.tap(find.byTooltip('البحث'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.byTooltip('البحث'),
      findsOneWidget,
      reason: 'back from search returns to the index, not out of the app',
    );

    // A reading-only section names its part of the book and leads on.
    await tester.scrollUntilVisible(
      find.text('حول الكتاب'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('حول الكتاب'));
    await tester.pumpAndSettle();
    await openSection(tester, 'تمهيد الكتاب');
    expect(find.text('حول الكتاب'), findsOneWidget, reason: 'parent shown');
    await tester.scrollUntilVisible(
      find.text('الباب التالي'),
      600,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('الباب التالي'));
    await tester.pumpAndSettle();
    expect(find.text('المقدمة'), findsWidgets, reason: 'next in book order');
  });
}
