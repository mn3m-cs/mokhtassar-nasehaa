import 'dart:async';

import 'package:alazkar/app.dart';
import 'package:alazkar/src/core/helpers/azkar_helper.dart';
import 'package:alazkar/src/core/manager/volume_button_manager.dart';
import 'package:alazkar/src/core/models/zikr.dart';
import 'package:alazkar/src/core/models/zikr_extension.dart';
import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:alazkar/src/core/utils/app_print.dart';
import 'package:alazkar/src/core/utils/show_toast.dart';
import 'package:alazkar/src/features/home/presentation/controller/home/home_bloc.dart';
import 'package:alazkar/src/features/search/data/models/title_paths.dart';
import 'package:alazkar/src/features/settings/data/repository/settings_storage.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/components/zikr_share_dialog.dart';
import 'package:alazkar/src/features/zikr_source_filter/data/models/zikr_filter.dart';
import 'package:alazkar/src/features/zikr_source_filter/data/models/zikr_filter_list_extension.dart';
import 'package:alazkar/src/features/zikr_source_filter/data/repository/zikr_filter_storage.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'zikr_content_viewer_event.dart';
part 'zikr_content_viewer_state.dart';

class ZikrContentViewerBloc
    extends Bloc<ZikrContentViewerEvent, ZikrContentViewerState> {
  final HomeBloc homeBloc;
  final SettingsStorage settingsStorage;
  final ZikrFilterStorage zikrFilterStorage;
  final AzkarDBHelper azkarDBHelper;

  static final MethodChannel _volumeBtnChannel = VolumeButtonManager.channel;

  ZikrContentViewerBloc(
    this.homeBloc,
    this.settingsStorage,
    this.zikrFilterStorage,
    this.azkarDBHelper,
  ) : super(ZikrContentViewerLoadingState()) {
    VolumeButtonManager.setActivationStatus(
      activate: settingsStorage.praiseWithVolumeKeys,
    );
    _volumeBtnChannel.setMethodCallHandler(_activateVolumeHandler);

    on<ZikrContentViewerStartEvent>(_start);
    on<ZikrContentViewerDecreaseEvent>(_decrease);
    on<ZikrContentViewerCopyEvent>(_copy);
    on<ZikrContentViewerShareEvent>(_share);
    on<ZikrContentViewerNextTitleEvent>(_nextTitle);
    on<ZikrContentViewerPreviousTitleEvent>(_previousTitle);
    on<ZikrContentViewerFocusEvent>(_focus);
  }

  Future<void> _start(
    ZikrContentViewerStartEvent event,
    Emitter<ZikrContentViewerState> emit,
  ) async {
    emit(ZikrContentViewerLoadingState());

    final showTextInBrackets = settingsStorage.showTextInBrackets();
    final RegExp regExp = RegExp(r'\(.*?\)');

    /// get all zikr
    final List<Zikr> azkarToSet;
    final azkarFromDB =
        (await azkarDBHelper.getContentByTitleId(event.zikrTitleId))
            .map(
              (e) => showTextInBrackets || e.body.contains("QuranText")
                  ? e
                  : e.copyWith(body: e.body.replaceAll(regExp, "")),
            )
            .toList();
    final zikrTitle = await azkarDBHelper.getTitlesById(event.zikrTitleId);
    final sectionPath =
        buildParentPath(zikrTitle, await azkarDBHelper.getAllTitles());

    /// filter out zikr
    final List<Filter> filters = zikrFilterStorage.getAllFilters();
    azkarToSet = filters.getFilteredZikr(azkarFromDB);

    final focusIndex =
        azkarToSet.indexWhere((zikr) => zikr.order == event.zikrOrder);
    emit(
      ZikrContentViewerLoadedState(
        zikrTitle: zikrTitle,
        azkar: azkarToSet,
        activeZikrIndex: focusIndex == -1 ? 0 : focusIndex,
        initialCounts: {for (final zikr in azkarToSet) zikr.id: zikr.count},
        sectionPath: sectionPath,
        focusOrder: event.zikrOrder,
      ),
    );
  }

  Future<void> _decrease(
    ZikrContentViewerDecreaseEvent event,
    Emitter<ZikrContentViewerState> emit,
  ) async {
    final state = this.state;
    if (state is! ZikrContentViewerLoadedState) return;

    if (event.zikr.count == 0) return;

    final countToSet = event.zikr.count - 1;
    if (countToSet == 0) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    final azkarToSet = state.azkar.map((e) {
      if (e.id != event.zikr.id) return e;
      return e.copyWith(count: countToSet);
    }).toList();

    // The zikr just counted becomes the one the keys continue.
    emit(
      state.copyWith(
        azkar: azkarToSet,
        activeZikrIndex:
            state.azkar.indexWhere((zikr) => zikr.id == event.zikr.id),
      ),
    );
  }

  void _focus(
    ZikrContentViewerFocusEvent event,
    Emitter<ZikrContentViewerState> emit,
  ) {
    final state = this.state;
    if (state is! ZikrContentViewerLoadedState) return;
    if (state.activeZikrIndex == event.index) return;
    emit(state.copyWith(activeZikrIndex: event.index));
  }

  Future<String> sharedZikrText(Zikr zikr) async {
    final Zikr zikrFromDB = await azkarDBHelper.getContentById(zikr.id);

    final activeZikr = zikrFromDB;
    final fadlTxt = activeZikr.fadl.isEmpty
        ? ""
        : "\n\n-------\nالفضل:\n${activeZikr.fadl}";
    final plainText =
        "${await activeZikr.toPlainText()}\n\n-------\nعدد مرات الذكر:  ${activeZikr.count}$fadlTxt\n\n-------\nالحكم: ${activeZikr.hokm}\n\n==============\nالمصدر:\n${activeZikr.source}";
    return plainText;
  }

  Future<void> _copy(
    ZikrContentViewerCopyEvent event,
    Emitter<ZikrContentViewerState> emit,
  ) async {
    final plainText = await sharedZikrText(event.zikr);
    if (plainText.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: plainText));

    showToast("تم نسخ الذكر");
  }

  Future<void> _share(
    ZikrContentViewerShareEvent event,
    Emitter<ZikrContentViewerState> emit,
  ) async {
    showDialog(
      context: MyApp.navigatorKey.currentState!.context,
      builder: (context) {
        return ZikrShareDialog(
          zikrId: event.zikr.id,
        );
      },
    );
  }

  Future _activateVolumeHandler(MethodCall call) async {
    final state = this.state;
    if (state is! ZikrContentViewerLoadedState) return;

    await VolumeButtonManager.handler(
      call: call,
      onVolumeUpPressed: () {
        final zikr = state.keyTarget;
        if (zikr != null) add(ZikrContentViewerDecreaseEvent(zikr));
      },
      onVolumeDownPressed: () {
        final zikr = state.keyTarget;
        if (zikr != null) add(ZikrContentViewerDecreaseEvent(zikr));
      },
    );
  }

  @override
  Future<void> close() {
    VolumeButtonManager.setActivationStatus(
      activate: false,
    );
    return super.close();
  }

  Future<void> _nextTitle(
    ZikrContentViewerNextTitleEvent event,
    Emitter<ZikrContentViewerState> emit,
  ) async {
    final state = this.state;
    if (state is! ZikrContentViewerLoadedState) return;

    final homeState = homeBloc.state;
    if (homeState is! HomeLoadedState) return;

    try {
      final titles = homeState.readingOrder();
      final int currentTitleIndex =
          titles.indexWhere((e) => e.id == state.zikrTitle.id);
      appPrint(currentTitleIndex);
      if (currentTitleIndex == -1) return;
      if (currentTitleIndex == titles.length - 1) {
        showToast("هذا آخر الكتاب");
        return;
      }
      add(ZikrContentViewerStartEvent(titles[currentTitleIndex + 1].id));
    } catch (e) {
      appPrint(e);
    }
  }

  Future<void> _previousTitle(
    ZikrContentViewerPreviousTitleEvent event,
    Emitter<ZikrContentViewerState> emit,
  ) async {
    final state = this.state;
    if (state is! ZikrContentViewerLoadedState) return;

    final homeState = homeBloc.state;
    if (homeState is! HomeLoadedState) return;

    try {
      final titles = homeState.readingOrder();
      final int currentTitleIndex =
          titles.indexWhere((e) => e.id == state.zikrTitle.id);
      if (currentTitleIndex == -1 || currentTitleIndex == 0) return;
      add(ZikrContentViewerStartEvent(titles[currentTitleIndex - 1].id));
    } catch (e) {
      appPrint(e);
    }
  }
}
