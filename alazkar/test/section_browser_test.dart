import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:alazkar/src/features/home/presentation/components/section_browser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const root = ZikrTitle(
    id: 1,
    order: 1,
    name: 'العبادات',
    freq: 'd',
    nodeType: ZikrTitleNodeType.category,
  );
  const prayer = ZikrTitle(
    id: 2,
    order: 1,
    name: 'الصلاة',
    freq: 'd',
    parentId: 1,
    nodeType: ZikrTitleNodeType.category,
  );
  const insidePrayer = ZikrTitle(
    id: 3,
    order: 1,
    name: 'داخل الصلاة',
    freq: 'd',
    parentId: 2,
    nodeType: ZikrTitleNodeType.category,
  );
  const emptyCategory = ZikrTitle(
    id: 4,
    order: 1,
    name: 'قسم فارغ',
    freq: 'd',
    parentId: 3,
    nodeType: ZikrTitleNodeType.category,
  );

  Widget app(List<ZikrTitle> titles) {
    return MaterialApp(
      home: Scaffold(
        body: SectionBrowser(
          titles: titles,
          itemBuilder: (context, title, localOrder, openCategory) => ListTile(
            leading: Text('$localOrder'),
            title: Text(title.name),
            onTap: openCategory,
          ),
        ),
      ),
    );
  }

  testWidgets('navigates through any hierarchy depth and shows its path',
      (tester) async {
    await tester.pumpWidget(app([root, prayer, insidePrayer, emptyCategory]));

    expect(find.text('العبادات'), findsOneWidget);
    expect(find.text('الصلاة'), findsNothing);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.text('العبادات'));
    await tester.pump();
    expect(find.text('الفهرس'), findsOneWidget);
    expect(find.text('الصلاة'), findsOneWidget);

    await tester.tap(find.text('الصلاة'));
    await tester.pump();
    await tester.tap(find.text('داخل الصلاة'));
    await tester.pump();

    expect(find.text('العبادات'), findsOneWidget);
    expect(find.text('الصلاة'), findsOneWidget);
    expect(find.text('داخل الصلاة'), findsOneWidget);
    expect(find.text('قسم فارغ'), findsOneWidget);

    await tester.tap(find.text('قسم فارغ'));
    await tester.pump();
    expect(find.text('لا توجد أقسام أو أذكار هنا'), findsOneWidget);
  });

  testWidgets('back button returns exactly one hierarchy level',
      (tester) async {
    await tester.pumpWidget(app([root, prayer, insidePrayer]));
    await tester.tap(find.text('العبادات'));
    await tester.pump();
    await tester.tap(find.text('الصلاة'));
    await tester.pump();

    await tester.tap(find.byTooltip('رجوع'));
    await tester.pump();

    expect(find.text('الصلاة'), findsOneWidget);
    expect(find.text('داخل الصلاة'), findsNothing);
  });

  testWidgets('returns to the nearest valid level when filters hide the path',
      (tester) async {
    const anotherRoot = ZikrTitle(
      id: 20,
      order: 1,
      name: 'قسم ظاهر',
      freq: 'd',
      nodeType: ZikrTitleNodeType.category,
    );
    await tester.pumpWidget(app([root, prayer]));
    await tester.tap(find.text('العبادات'));
    await tester.pump();

    await tester.pumpWidget(app([anotherRoot]));
    await tester.pump();

    expect(find.text('قسم ظاهر'), findsOneWidget);
    expect(find.text('الفهرس'), findsNothing);
  });

  testWidgets('restores the scroll offset after returning from a category',
      (tester) async {
    final roots = List.generate(
      30,
      (index) => ZikrTitle(
        id: index + 10,
        order: index + 1,
        name: 'قسم $index',
        freq: 'd',
        nodeType: ZikrTitleNodeType.category,
      ),
    );
    final child = ZikrTitle(
      id: 100,
      order: 1,
      name: 'ابن القسم الأخير',
      freq: 'd',
      parentId: roots.last.id,
      nodeType: ZikrTitleNodeType.category,
    );
    await tester.pumpWidget(app([...roots, child]));

    await tester.scrollUntilVisible(
      find.text('قسم 29'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final rootOffset = tester
        .widget<ListView>(find.byType(ListView))
        .controller!
        .position
        .pixels;
    expect(rootOffset, greaterThan(0));

    await tester.tap(find.text('قسم 29'));
    await tester.pump();
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pump();

    final restoredOffset = tester
        .widget<ListView>(find.byType(ListView))
        .controller!
        .position
        .pixels;
    expect(restoredOffset, rootOffset);
  });
}
