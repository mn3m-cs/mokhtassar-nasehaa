import 'package:alazkar/app.dart';
import 'package:alazkar/services.dart';
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

  Future<void> openFavourites(WidgetTester tester) async {
    await tester.tap(find.text('المفضلة'));
    await tester.pumpAndSettle();
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
    await tester.pumpAndSettle();
    await dismissTip(tester);
  }

  Finder header(String text) => find.textContaining(text, findRichText: true);

  testWidgets('core reading journeys', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Default favourites are listed in book order.
    await openFavourites(tester);
    const expected = [
      'أذكار الصباح',
      'أذكار المساء',
      'أذكار الاستيقاظ',
      'ما يقول بعد الصلاة',
      'أذكار النوم',
      'أذكار المسافر',
    ];
    final tops = [
      for (final name in expected) tester.getTopLeft(find.text(name)).dy,
    ];
    expect(tops, [...tops]..sort(), reason: 'favourites in book order');

    // Finishing a zikr counts it down and moves to the next.
    await openSection(tester, 'أذكار الصباح');
    expect(find.text('1 من 28'), findsOneWidget);
    await tester.tap(find.byType(PageView));
    await tester.pumpAndSettle();
    expect(find.text('2 من 28'), findsOneWidget, reason: 'moved on');
    expect(find.text('3'), findsOneWidget, reason: 'next zikr counter');

    // Next section follows the book.
    await tester.tap(find.byTooltip('الباب التالي'));
    await tester.pumpAndSettle();
    await dismissTip(tester);
    expect(header('أذكار المساء'), findsOneWidget, reason: 'next section');
    expect(header('أذكار الصباح والمساء'), findsOneWidget, reason: 'path');
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
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.byTooltip('البحث'),
      findsOneWidget,
      reason: 'back from search returns to the index, not out of the app',
    );

    // Continuous reading drags from one section into the next.
    await tester.tap(find.byTooltip('الإعدادات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('القراءة المتصلة'));
    await tester.pumpAndSettle();
    await backHome(tester);
    await tester.tap(find.text('فهرس'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حول الكتاب'));
    await tester.pumpAndSettle();
    await openSection(tester, 'تمهيد الكتاب');
    expect(header('تمهيد الكتاب'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(600, 0));
    await tester.pumpAndSettle();
    await dismissTip(tester);
    expect(header('المقدمة'), findsOneWidget, reason: 'continuous reading');
  });
}
