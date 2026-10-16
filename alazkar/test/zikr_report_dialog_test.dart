import 'package:alazkar/src/core/constants/const.dart';
import 'package:alazkar/src/core/models/zikr.dart';
import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/components/zikr_report_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  kAppVersion = '1.4.0 (2020)';

  const zikrTitle =
      ZikrTitle(id: 7, order: 7, name: 'ما يقول إذا خرج من الخلاء', freq: '');
  const zikr = Zikr(
    id: 42,
    titleId: 7,
    order: 1,
    body: 'غُفْرَانَكَ',
    source: '',
    fadl: '',
    hokm: '',
    count: 1,
    search: '',
    sourceIndex: '',
  );

  late List<String> clipboard;

  setUp(() {
    clipboard = [];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboard.add((call.arguments as Map)['text'] as String);
      }
      return null;
    });
    messenger.setMockMethodCallHandler(
      const MethodChannel('PonnamKarthik/fluttertoast'),
      (call) async => true,
    );
  });

  Future<void> openDialog(WidgetTester tester, Brightness brightness) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.brown,
            brightness: brightness,
          ),
        ),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const ZikrReportDialog(
                zikr: zikr,
                zikrTitle: zikrTitle,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('the dialog shows the reworded texts', (tester) async {
    await openDialog(tester, Brightness.light);

    expect(find.text('الإبلاغ عن خطأ'), findsOneWidget);
    expect(
      find.text(
        'هل وجدت خطأً في هذا الذكر؟ اكتب لنا موضعه، وسنراجعه على الكتاب ونصحّحه إن شاء الله.',
      ),
      findsOneWidget,
    );
    expect(find.text('مثال: كلمة مكتوبة بغير ما في الكتاب'), findsOneWidget);
    expect(find.text('الذكر:'), findsOneWidget);
    expect(find.text('غُفْرَانَكَ'), findsOneWidget);
    expect(find.text('تبليغ عن خطأ'), findsNothing);
  });

  testWidgets('the header and buttons take their colours from the theme',
      (tester) async {
    await openDialog(tester, Brightness.dark);
    final colorScheme =
        Theme.of(tester.element(find.byType(ZikrReportDialog))).colorScheme;

    final icon =
        tester.widget<Icon>(find.byIcon(Icons.report_problem_outlined));
    expect(icon.color, colorScheme.primary);

    final send = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'إرسال'),
    );
    expect(
      send.style!.backgroundColor!.resolve(<WidgetState>{}),
      colorScheme.primary,
    );
    expect(
      tester.getSize(find.widgetWithText(ElevatedButton, 'إرسال')).width,
      tester.getSize(find.widgetWithText(TextButton, 'إلغاء')).width,
    );

    final cancel = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'إلغاء'),
    );
    expect(
      cancel.style!.foregroundColor!.resolve(<WidgetState>{}),
      colorScheme.onSurfaceVariant,
    );
  });

  testWidgets('an empty report is refused and nothing is sent', (tester) async {
    await openDialog(tester, Brightness.light);

    await tester.tap(find.text('إرسال'));
    await tester.pumpAndSettle();

    expect(find.text('لا يمكن إرسال بلاغ فارغ'), findsOneWidget);
    expect(find.byType(ZikrReportDialog), findsOneWidget);
    expect(clipboard, isEmpty);
  });

  testWidgets('a report keeps its subject and body when mail cannot open',
      (tester) async {
    await openDialog(tester, Brightness.light);

    await tester.enterText(find.byType(TextFormField), 'كلمة ناقصة');
    await tester.tap(find.text('إرسال'));
    await tester.pumpAndSettle();

    expect(find.byType(ZikrReportDialog), findsNothing);
    const report = '[زاد الذاكر - v1.4.0 (2020)] تبليغ عن خطأ\n'
        '\n'
        '[7] ما يقول إذا خرج من الخلاء\n'
        '\n'
        '[رقم: 42 | ترتيب: 1]\n'
        '"غُفْرَانَكَ"\n'
        '\n'
        '• بلاغ المستخدم عن الخطأ:\n'
        'كلمة ناقصة\n';
    expect(clipboard, [report]);

    await tester.pump(const Duration(seconds: 2));
  });
}
