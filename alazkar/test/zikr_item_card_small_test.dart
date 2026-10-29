import 'package:alazkar/src/core/models/zikr.dart';
import 'package:alazkar/src/features/settings/data/repository/zikr_text_repo.dart';
import 'package:alazkar/src/features/theme/domain/repository/theme_storage.dart';
import 'package:alazkar/src/features/theme/presentation/controller/cubit/theme_cubit.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/components/zikr_item_card.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/controller/bloc/zikr_content_viewer_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_storage.dart';

/// The card's menu holds the section's bloc; these tests never open it.
class _UnusedViewerBloc extends Fake implements ZikrContentViewerBloc {
  @override
  Stream<ZikrContentViewerState> get stream => const Stream.empty();
}

/// Record 1204: the closing date of «المقدمة», p. 9.
const _date = 'الإسكندرية في الجمعة\n6 من ذي القعدة 1407هـ\n'
    'الموافق 3 من يوليو 1987م';

void main() {
  Future<void> pumpPassage(WidgetTester tester, {required String style}) async {
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
            child: Scaffold(
              body: ZikrItemCard(
                isCounted: false,
                zikr: Zikr(
                  id: 1204,
                  titleId: 102,
                  order: 2,
                  body: _date,
                  source: 'المقدمة. (ص9)',
                  fadl: '',
                  hokm: '',
                  count: 0,
                  search: '',
                  sourceIndex: '',
                  style: style,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('a small line has no actions menu (#140)', (tester) async {
    await pumpPassage(tester, style: 'small');

    expect(find.text(_date), findsOneWidget);
    expect(find.byTooltip('خيارات الذكر'), findsNothing);
  });

  testWidgets('an ordinary passage hides the button and exposes long press',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpPassage(tester, style: '');

    expect(find.byTooltip('خيارات الذكر'), findsNothing);
    final passageSemantics = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics && widget.properties.hint == 'خيارات الفقرة',
    );
    expect(passageSemantics, findsOneWidget);
    expect(
      tester
          .getSemantics(passageSemantics)
          .getSemanticsData()
          .hasAction(SemanticsAction.longPress),
      isTrue,
    );
    semantics.dispose();
  });
}
