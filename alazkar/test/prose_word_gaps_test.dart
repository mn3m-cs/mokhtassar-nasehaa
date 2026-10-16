import 'package:alazkar/src/core/models/zikr.dart';
import 'package:alazkar/src/features/settings/data/repository/zikr_text_repo.dart';
import 'package:alazkar/src/features/theme/domain/repository/theme_storage.dart';
import 'package:alazkar/src/features/theme/presentation/controller/cubit/theme_cubit.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/components/zikr_item_card.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/controller/bloc/zikr_content_viewer_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_storage.dart';

/// The card's menu holds the section's bloc; laying out text never uses it.
class _UnusedViewerBloc extends Fake implements ZikrContentViewerBloc {
  @override
  Stream<ZikrContentViewerState> get stream => const Stream.empty();
}

/// From «فائدة في التزام الأدعية الصحيحة»: long words that leave short lines.
const _body = 'ومن العجب العجاب أن تعرض عن الدعوات التي ذكرها الله في كتابه '
    'عن الأنبياء، والأولياء، والأصفياء مقرونة بالإجابة، ثم تنتقي ألفاظ '
    'الشعراء والكتاب كأنك قد دعوت في زعمك بجميع دعواتهم';

/// From «أذكار الموت».
const _fadl = 'قال رسول الله صلى الله عليه وسلم: «مَنْ كان آخِرُ كلامِه: '
    'لا إلهَ إلا اللهُ دَخَلَ الجنةَ».';

void main() {
  Future<void> pumpPassage(WidgetTester tester) async {
    final themeCubit = ThemeCubit(
      ZikrTextRepo(MemoryStorage()),
      ThemeStorage(MemoryStorage()),
    );
    addTearDown(themeCubit.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: themeCubit),
              BlocProvider<ZikrContentViewerBloc>.value(
                value: _UnusedViewerBloc(),
              ),
            ],
            child: const Scaffold(
              body: SingleChildScrollView(
                child: ZikrItemCard(
                  isCounted: false,
                  zikr: Zikr(
                    id: 1,
                    titleId: 1,
                    order: 1,
                    body: _body,
                    source: '',
                    fadl: _fadl,
                    hokm: '',
                    count: 0,
                    search: '',
                    sourceIndex: '',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  RenderParagraph paragraphOf(WidgetTester tester, String text) =>
      tester.renderObject(
        find.byWidgetPredicate(
          (widget) => widget is RichText && widget.text.toPlainText() == text,
        ),
      );

  /// The width each space between two words takes once the lines are laid
  /// out.
  List<double> spaceWidths(RenderParagraph paragraph) {
    final text = paragraph.text.toPlainText();
    return [
      for (var i = 0; i < text.length; i++)
        if (text[i] == ' ')
          paragraph
              .getBoxesForSelection(
                TextSelection(baseOffset: i, extentOffset: i + 1),
              )
              .single
              .toRect()
              .width,
    ];
  }

  for (final (name, text) in [('passage', _body), ("passage's fadl", _fadl)]) {
    testWidgets('every word gap in a $name is one normal space',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      await pumpPassage(tester);

      final paragraph = paragraphOf(tester, text);
      final widths = spaceWidths(paragraph);

      expect(
        paragraph
            .getOffsetForCaret(TextPosition(offset: text.length), Rect.zero)
            .dy,
        greaterThan(0),
        reason: 'the text must wrap for a line to be stretched',
      );
      expect(widths, isNotEmpty);
      expect(
        widths,
        everyElement(moreOrLessEquals(widths.first, epsilon: .01)),
      );
    });
  }
}
