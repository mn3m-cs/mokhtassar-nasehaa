import 'dart:async';

import 'package:alazkar/app.dart';
import 'package:alazkar/src/core/helpers/azkar_helper.dart';
import 'package:alazkar/src/core/manager/vibration_manager.dart';
import 'package:alazkar/src/core/manager/volume_button_manager.dart';
import 'package:alazkar/src/core/models/home_card.dart';
import 'package:alazkar/src/core/models/zikr.dart';
import 'package:alazkar/src/core/models/zikr_extension.dart';
import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:alazkar/src/core/utils/app_print.dart';
import 'package:alazkar/src/core/utils/show_toast.dart';
import 'package:alazkar/src/features/home/presentation/controller/home/home_bloc.dart';
import 'package:alazkar/src/features/search/data/models/title_paths.dart';
import 'package:alazkar/src/features/settings/data/repository/settings_storage.dart';
import 'package:alazkar/src/features/zikr_content_viewer/data/models/progress_keeping.dart';
import 'package:alazkar/src/features/zikr_content_viewer/data/repository/reading_progress_storage.dart';
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
  final ReadingProgressStorage readingProgressStorage;

  static final MethodChannel _volumeBtnChannel = VolumeButtonManager.channel;

  ZikrContentViewerBloc(
    this.homeBloc,
    this.settingsStorage,
    this.zikrFilterStorage,
    this.azkarDBHelper,
    this.readingProgressStorage,
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
    on<ZikrContentViewerRestartEvent>(_restart);
  }

  Future<void> _start(
    ZikrContentViewerStartEvent event,
    Emitter<ZikrContentViewerState> emit,
  ) async {
    emit(ZikrContentViewerLoadingState());

    final showTextInBrackets = settingsStorage.showTextInBrackets();
    final RegExp regExp = RegExp(r'\(.*?\)');

    /// get all zikr
    final card = event.card;
    final List<Zikr> azkarToSet;
    final rows = card == null
        ? await azkarDBHelper.getContentByTitleId(event.zikrTitleId)
        : await azkarDBHelper.getContentByIds(card.zikrIds);
    final azkarFromDB = rows
        .map(
          (e) => showTextInBrackets || e.body.contains("QuranText")
              ? e
              : e.copyWith(body: e.body.replaceAll(regExp, "")),
        )
        .toList();
    final allTitles = await azkarDBHelper.getAllTitles();
    final ZikrTitle zikrTitle;
    final String sectionPath;
    if (card == null) {
      zikrTitle = await azkarDBHelper.getTitlesById(event.zikrTitleId);
      sectionPath = buildParentPath(zikrTitle, allTitles);
    } else {
      // A card sits where the section of its first zikr sits, so it keeps
      // its progress as that section does.
      final first = rows.isEmpty
          ? null
          : allTitles.where((t) => t.id == rows.first.titleId).firstOrNull;
      if (first == null) {
        appPrint("home card ${card.id}: its first zikr is in no section");
      }
      zikrTitle = ZikrTitle(
        id: card.id,
        order: first?.order ?? 0,
        name: card.name,
        freq: first?.freq ?? '',
        parentId: first?.parentId,
      );
      sectionPath = '';
    }
    final progressKeeping = progressKeepingOf(zikrTitle, allTitles);
    final progressId = progressIdOf(zikrTitle, card);

    /// filter out zikr
    final List<Filter> filters = zikrFilterStorage.getAllFilters();
    azkarToSet = filters.getFilteredZikr(azkarFromDB);
    final initialCounts = {for (final zikr in azkarToSet) zikr.id: zikr.count};

    // Saved counts for azkar the filters now hide are dropped, and a count
    // is never restored above the book's.
    final progress = switch (progressKeeping) {
      ProgressKeeping.none => null,
      ProgressKeeping.forToday => readingProgressStorage.read(progressId),
      ProgressKeeping.always =>
        readingProgressStorage.read(progressId, expires: false),
    };
    final savedCounts = progress?.counts ?? const <int, int>{};
    final azkar = azkarToSet.map((zikr) {
      final saved = savedCounts[zikr.id];
      if (saved == null) return zikr;
      return zikr.copyWith(count: saved.clamp(0, zikr.count));
    }).toList();

    // A search result names the zikr to show; otherwise the reader returns
    // to the zikr they left.
    var activeZikrIndex =
        azkar.indexWhere((zikr) => zikr.order == event.zikrOrder);
    int? resumeZikrId;
    if (event.zikrOrder == null) {
      final resumeIndex =
          azkar.indexWhere((zikr) => zikr.id == progress?.zikrId);
      if (resumeIndex != -1) {
        activeZikrIndex = resumeIndex;
        resumeZikrId = azkar[resumeIndex].id;
      }
    }

    emit(
      ZikrContentViewerLoadedState(
        zikrTitle: zikrTitle,
        azkar: azkar,
        activeZikrIndex: activeZikrIndex == -1 ? 0 : activeZikrIndex,
        initialCounts: initialCounts,
        sectionPath: sectionPath,
        focusOrder: event.zikrOrder,
        resumeZikrId: resumeZikrId,
        progressKeeping: progressKeeping,
        card: card,
        firstSectionId: card == null ? null : rows.firstOrNull?.titleId,
        lastSectionId: card == null ? null : rows.lastOrNull?.titleId,
      ),
    );
  }

  /// Keeps the counts and the zikr in view, so the section reopens as it was
  /// left, for as long as its kind keeps them.
  Future<void> _saveProgress(ZikrContentViewerLoadedState state) async {
    if (state.progressKeeping == ProgressKeeping.none) return;
    await readingProgressStorage.write(
      state.progressId,
      ReadingProgress(
        counts: {
          for (final zikr in state.azkar)
            if (zikr.count != state.initialCounts[zikr.id]) zikr.id: zikr.count,
        },
        zikrId: state.activeZikr?.id,
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
    if (state.completesRepeated(event.zikr) &&
        settingsStorage.vibrateOnCountDone) {
      VibrationManager.countDone();
    } else if (countToSet == 0) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    final azkarToSet = state.azkar.map((e) {
      if (e.id != event.zikr.id) return e;
      return e.copyWith(count: countToSet);
    }).toList();

    // The zikr just counted becomes the one the keys continue.
    final stateToSet = state.copyWith(
      azkar: azkarToSet,
      activeZikrIndex:
          state.azkar.indexWhere((zikr) => zikr.id == event.zikr.id),
    );
    emit(stateToSet);
    await _saveProgress(stateToSet);
  }

  Future<void> _focus(
    ZikrContentViewerFocusEvent event,
    Emitter<ZikrContentViewerState> emit,
  ) async {
    final state = this.state;
    if (state is! ZikrContentViewerLoadedState) return;
    if (state.activeZikrIndex == event.index) return;
    final stateToSet = state.copyWith(activeZikrIndex: event.index);
    emit(stateToSet);
    await _saveProgress(stateToSet);
  }

  Future<void> _restart(
    ZikrContentViewerRestartEvent event,
    Emitter<ZikrContentViewerState> emit,
  ) async {
    final state = this.state;
    if (state is! ZikrContentViewerLoadedState || !state.canRestart) return;
    emit(
      ZikrContentViewerLoadedState(
        zikrTitle: state.zikrTitle,
        azkar: state.azkar
            .map(
              (zikr) => zikr.copyWith(
                count: state.initialCounts[zikr.id] ?? zikr.count,
              ),
            )
            .toList(),
        activeZikrIndex: 0,
        initialCounts: state.initialCounts,
        sectionPath: state.sectionPath,
        focusOrder: state.focusOrder,
        progressKeeping: state.progressKeeping,
        card: state.card,
        firstSectionId: state.firstSectionId,
        lastSectionId: state.lastSectionId,
      ),
    );
    await readingProgressStorage.clear(state.progressId);
  }

  Future<String> sharedZikrText(Zikr zikr) async {
    final Zikr zikrFromDB = await azkarDBHelper.getContentById(zikr.id);

    final activeZikr = zikrFromDB;
    final fadlTxt = activeZikr.fadl.isEmpty
        ? ""
        : "\n\n-------\nالفضل:\n${activeZikr.fadl}";
    final plainText =
        "${await activeZikr.toPlainText()}\n\n-------\nعدد مرات الذكر:  ${activeZikr.count}$fadlTxt\n\n==============\nالمصدر:\n${activeZikr.source}";
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

    final next = homeState.shownSectionFrom(state.nextFromId, 1);
    if (next == null) {
      showToast("هذا آخر الكتاب");
      return;
    }
    add(ZikrContentViewerStartEvent(next.id));
  }

  Future<void> _previousTitle(
    ZikrContentViewerPreviousTitleEvent event,
    Emitter<ZikrContentViewerState> emit,
  ) async {
    final state = this.state;
    if (state is! ZikrContentViewerLoadedState) return;

    final homeState = homeBloc.state;
    if (homeState is! HomeLoadedState) return;

    final previous = homeState.shownSectionFrom(state.previousFromId, -1);
    if (previous == null) return;
    add(ZikrContentViewerStartEvent(previous.id));
  }
}

/// The key a page keeps its counts and place under. A home card keeps the id
/// its section had before #220, as it did then. An index section that kept
/// one of those ids keeps its own apart, under the negated id, so the two
/// pages do not overwrite each other.
int progressIdOf(ZikrTitle title, HomeCard? card) {
  if (card == null && homeCardById(title.id) != null) return -title.id;
  return title.id;
}
