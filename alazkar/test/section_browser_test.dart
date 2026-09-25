import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:alazkar/src/features/home/presentation/components/fehrs_item_card.dart';
import 'package:alazkar/src/features/home/presentation/components/section_browser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const worship = ZikrTitle(
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
  const opening = ZikrTitle(
    id: 4,
    order: 1,
    name: 'دعاء الاستفتاح',
    freq: 'd',
    parentId: 3,
  );
  const afterPrayer = ZikrTitle(
    id: 5,
    order: 2,
    name: 'بعد الصلاة',
    freq: 'd',
    parentId: 2,
  );
  const morning = ZikrTitle(id: 6, order: 2, name: 'أذكار الصباح', freq: 'd');
  const all = [morning, afterPrayer, opening, insidePrayer, prayer, worship];

  Widget app(List<ZikrTitle> titles) {
    return MaterialApp(
      home: Scaffold(
        body: SectionBrowser(
          titles: titles,
          itemBuilder: (context, row) => ListTile(
            key: ValueKey(row.title.id),
            leading: Text('${row.depth}:${row.localOrder}'),
            title: Text(row.title.name),
            onTap: row.title.nodeType == ZikrTitleNodeType.category
                ? row.toggle
                : null,
          ),
        ),
      ),
    );
  }

  List<String> visibleNames(WidgetTester tester) => tester
      .widgetList<ListTile>(find.byType(ListTile))
      .map((tile) => (tile.title! as Text).data!)
      .toList();

  testWidgets('starts collapsed and shows only root sections in order',
      (tester) async {
    await tester.pumpWidget(app(all));

    expect(visibleNames(tester), ['العبادات', 'أذكار الصباح']);
  });

  testWidgets('expands in place through three levels with depth and order',
      (tester) async {
    await tester.pumpWidget(app(all));

    await tester.tap(find.text('العبادات'));
    await tester.pump();
    await tester.tap(find.text('الصلاة'));
    await tester.pump();
    await tester.tap(find.text('داخل الصلاة'));
    await tester.pump();

    expect(visibleNames(tester), [
      'العبادات',
      'الصلاة',
      'داخل الصلاة',
      'دعاء الاستفتاح',
      'بعد الصلاة',
      'أذكار الصباح',
    ]);
    expect(find.text('3:1'), findsOneWidget, reason: 'opening is depth 3');
    expect(find.text('2:2'), findsOneWidget, reason: 'after prayer is 2nd');
  });

  testWidgets('collapsing a parent hides every descendant', (tester) async {
    await tester.pumpWidget(app(all));
    for (final name in ['العبادات', 'الصلاة', 'داخل الصلاة']) {
      await tester.tap(find.text(name));
      await tester.pump();
    }

    await tester.tap(find.text('العبادات'));
    await tester.pump();

    expect(visibleNames(tester), ['العبادات', 'أذكار الصباح']);
  });

  testWidgets('keeps expanded sections open when the filter changes',
      (tester) async {
    await tester.pumpWidget(app(all));
    await tester.tap(find.text('العبادات'));
    await tester.pump();

    await tester.pumpWidget(app([worship, prayer]));
    await tester.pump();

    expect(visibleNames(tester), ['العبادات', 'الصلاة']);
  });

  testWidgets('places the expand arrow on the reading start side',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: FehrsItemCard(
              zikrTitle: worship,
              displayOrder: 1,
              depth: 0,
              onCategoryTap: () {},
            ),
          ),
        ),
      ),
    );

    final arrow = tester.getCenter(find.byIcon(Icons.chevron_right));
    final title = tester.getCenter(find.text('العبادات'));
    expect(arrow.dx, greaterThan(title.dx));
  });
}
