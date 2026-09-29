// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

import '../../../core/catalogue/exercise_catalogue.dart';
import '../../../core/catalogue/exercise_def.dart';
import '../../../core/format/format.dart';
import '../../../core/format/set_label.dart';
import '../../../core/i18n/t.dart';
import '../../../core/js/js_engine_service.dart';
import '../../../core/js/models/history_models.dart';
import '../../../core/js/models/progression_models.dart';
import '../../../core/js/modules/bar_js.dart';
import '../../../core/js/modules/effort_js.dart';
import '../../../core/js/modules/exercises_js.dart';
import '../../../core/js/modules/history_js.dart';
import '../../../core/js/modules/progression_copy_js.dart';
import '../../../core/js/modules/progression_js.dart';
import '../../../core/js/modules/workout_model_js.dart';
import '../../../core/models/gym_state.dart';
import '../../../core/models/model_extras.dart';
import '../../../core/models/routine.dart';
import '../../../core/models/set_entry.dart';
import '../../../core/models/workout.dart';

/// Presentation column specification for set rows in an exercise block.
/// Ported from `../openGym/frontend/src/views/Workout.jsx` lines 145-165.
class SetColumn extends Equatable {
  const SetColumn({
    required this.field,
    required this.step,
    required this.decimal,
    required this.header,
    this.effortKind,
    this.optional = false,
  });

  final String field; // 'w', 'r', 'min', 'sec', 'speed', 'rir', 'rpe'
  final num step;
  final bool decimal;
  final String header;
  final String? effortKind;
  final bool optional;

  @override
  List<Object?> get props => <Object?>[
        field,
        step,
        decimal,
        header,
        effortKind,
        optional,
      ];
}

/// Barbell and plate loading guidance for barbell exercises.
/// Ported from `../openGym/frontend/src/views/Workout.jsx` lines 205-216.
class BarInfo extends Equatable {
  const BarInfo({
    required this.bar,
    required this.text,
  });

  final double bar;
  final String text;

  @override
  List<Object?> get props => <Object?>[bar, text];
}

/// Presentation guidance for automatic progression policy and explanation.
/// Ported from `../openGym/frontend/src/views/Workout.jsx` lines 135-140.
class ProgressionGuidance extends Equatable {
  const ProgressionGuidance({
    required this.policyLabel,
    this.why,
    this.kind,
  });

  final String policyLabel;
  final Object? why;
  final String? kind;

  @override
  List<Object?> get props => <Object?>[policyLabel, why, kind];
}

/// Pre-calculated view model for a single exercise block in the active workout session.
///
/// All domain logic, history queries, progression guidance, and presentation derivations
/// are projected through JS bridge facades into this class, leaving the view widgets
/// completely logic-free.
///
/// Ported from `../openGym/frontend/src/views/Workout.jsx` lines 125-235, 236-252, 253-360.
class WorkoutEntryView extends Equatable {
  const WorkoutEntryView({
    required this.ex,
    required this.mode,
    required this.cardio,
    required this.timed,
    required this.bw,
    required this.perSide,
    required this.added,
    required this.col1,
    this.col2,
    this.col3,
    required this.best,
    this.last,
    this.lastLabel,
    this.standingNote,
    this.pinnedNote,
    this.guidance,
    this.barInfo,
    required this.effortColors,
    required this.setMenuTitles,
    required this.setLabels,
    required this.isWarmup,
    required this.isDrop,
    required this.isRestPause,
    required this.isSide,
  });

  final ExerciseDef ex;
  final String mode;
  final bool cardio;
  final bool timed;
  final bool bw;
  final bool perSide;
  final bool added;
  final SetColumn col1;
  final SetColumn? col2;
  final SetColumn? col3;
  final double best;
  final WorkoutEntry? last;
  final String? lastLabel;
  final String? standingNote;
  final PinnedNote? pinnedNote;
  final ProgressionGuidance? guidance;
  final BarInfo? barInfo;
  final List<String?> effortColors;
  final List<String> setMenuTitles;
  final List<String> setLabels;
  final List<bool> isWarmup;
  final List<bool> isDrop;
  final List<bool> isRestPause;
  final List<bool> isSide;

  /// Builds a [WorkoutEntryView] projecting openGym's ExerciseBlock derivations.
  static WorkoutEntryView build({
    required WorkoutEntry entry,
    required GymState s,
    required JsEngineService engine,
    required ExerciseCatalogue catalogue,
  }) {
    final String entryId = entry.id ?? '';
    final ExerciseDef ex = catalogue.lookup(s, entryId);
    final RoutineExercise cfg = (entry.target != null && entry.target!.id != null)
        ? entry.target!
        : (entry.target?.copyWith(id: entryId) ?? RoutineExercise(id: entryId));

    final String mode = engine.history.modeOf(cfg);
    final bool cardio = mode == 'cardio';
    final bool timed = mode == 'time';
    final WorkoutEntry? last = entryId.isNotEmpty ? engine.history.lastEntryFor(s, entryId) : null;
    final String? standingNote = entryId.isNotEmpty ? engine.history.exNoteFor(s, entryId) : null;

    final List<SetEntry> sets = entry.sets ?? const <SetEntry>[];
    final bool hasUndone = sets.any((SetEntry st) => st.done != true);
    final PinnedNote? pinnedNote = (hasUndone && entryId.isNotEmpty)
        ? engine.history.pinnedNoteFor(s, entryId)
        : null;

    final double bestHist = entryId.isNotEmpty ? engine.history.bestWeightFor(s, entryId) : 0;
    final num bestKept = (s.exWeights?[entryId]?.w) ?? 0;
    final double best = cardio
        ? 0
        : (bestHist > 0 && bestKept > 0
            ? engine.exercises.betterWeight(entryId, bestHist, bestKept)
            : (bestHist > bestKept ? bestHist : bestKept.toDouble()));

    final Prescription? plan = entry.plan != null ? Prescription.fromJson(entry.plan!) : null;
    final ({String policyLabel, Object? why})? rawGuidance =
        engine.progressionCopy.progressionGuidance(plan);
    final ProgressionGuidance? guidance = rawGuidance != null
        ? ProgressionGuidance(policyLabel: rawGuidance.policyLabel, why: rawGuidance.why, kind: plan?.kind)
        : null;

    final bool bw = !cardio && engine.history.isBw(cfg);
    final bool perSide = mode == 'reps' && engine.history.isPerSide(cfg);
    final bool added = bw && sets.any((SetEntry st) => (st.w ?? 0) > 0);

    final String unit = s.unit ?? 'kg';
    final num loadStep = mode == 'reps' ? engine.progression.weightIncrement(cfg, unit) : 2.5;
    final SetColumn loadCol = SetColumn(
      field: 'w',
      step: loadStep,
      decimal: true,
      header: bw ? t('Added ({0})', <Object?>[unit]) : t('Weight ({0})', <Object?>[unit]),
    );
    final SetColumn repCol = SetColumn(
      field: 'r',
      step: engine.history.repStep(cfg),
      decimal: false,
      header: t('Reps'),
    );

    final SetColumn col1 = cardio
        ? SetColumn(field: 'min', step: 1, decimal: false, header: t('Duration (min)'))
        : (timed
            ? SetColumn(field: 'sec', step: 5, decimal: false, header: t('Seconds'))
            : ((bw && !added) ? repCol : loadCol));

    final SetColumn? col2 = cardio
        ? SetColumn(field: 'speed', step: 0.5, decimal: true, header: t('Speed (km/h)'))
        : (timed
            ? ((bw && !added) ? null : loadCol)
            : ((bw && !added) ? null : repCol));

    final String kind = engine.history.effortOf(s);
    final EffortScale? eff = engine.history.effort[kind];
    final SetColumn? col3 = (mode == 'reps' && eff != null && eff.f != null && eff.hd != null)
        ? SetColumn(
            field: eff.f!,
            step: 1,
            decimal: false,
            header: t(eff.hd!),
            effortKind: kind,
            optional: true,
          )
        : null;

    BarInfo? barInfo;
    if (!cardio && !(bw && !added) && engine.bar.usesBar(ex.id)) {
      final double? bar = engine.bar.barWeightFor(s, entryId);
      if (bar != null && bar >= 0) {
        final SetEntry? nextUndone = sets.firstWhereOrNull((SetEntry st) => st.done != true);
        final num nextW = nextUndone?.w ?? 0;
        final num refW;
        if (nextW > 0) {
          refW = nextW;
        } else {
          num maxW = 0;
          for (final SetEntry st in sets) {
            final num w = st.w ?? 0;
            if (w > maxW) maxW = w;
          }
          refW = maxW;
        }
        final double? split = engine.bar.plateSplit(refW, bar);
        final String? perSideText =
            split != null ? t('{0} per side', <Object?>['${fmtNum(split)} $unit']) : null;
        if (bar == 0) {
          if (perSideText != null) {
            barInfo = BarInfo(bar: 0, text: perSideText);
          }
        } else {
          final String barPart = t('Bar {0}', <Object?>['${fmtNum(bar)} $unit']);
          final String text = perSideText != null ? '$barPart · $perSideText' : barPart;
          barInfo = BarInfo(bar: bar, text: text);
        }
      }
    }

    final String? lastLabel = (last != null && last.sets != null && last.sets!.isNotEmpty)
        ? last.sets!.map((SetEntry st) => setLabel(engine, entryId, st, last.target)).join(', ')
        : null;

    final List<String?> effortColors = <String?>[];
    final List<String> setMenuTitles = <String>[];
    final List<String> setLabels = <String>[];
    final List<bool> isWarmup = <bool>[];
    final List<bool> isDrop = <bool>[];
    final List<bool> isRestPause = <bool>[];
    final List<bool> isSide = <bool>[];

    for (int i = 0; i < sets.length; i++) {
      final SetEntry st = sets[i];
      final bool warm = engine.workoutModel.isWarmupRow(st);
      final int phaseNum =
          sets.sublist(0, i + 1).where((SetEntry x) => engine.workoutModel.isWarmupRow(x) == warm).length;
      final String title = warm ? t('Warm-up') : t('Set {0}', <Object?>[phaseNum]);
      final String label = setLabel(engine, entryId, st, entry.target);
      final double? rir = engine.effort.rirOf(st);
      final String? color = engine.effort.effortColor(rir);

      effortColors.add(color);
      setMenuTitles.add(title);
      setLabels.add(label);
      isWarmup.add(warm);
      isDrop.add(engine.workoutModel.isDropSet(st));
      isRestPause.add(engine.workoutModel.isRestPauseSet(st));
      isSide.add(engine.workoutModel.isSideSet(st));
    }

    return WorkoutEntryView(
      ex: ex,
      mode: mode,
      cardio: cardio,
      timed: timed,
      bw: bw,
      perSide: perSide,
      added: added,
      col1: col1,
      col2: col2,
      col3: col3,
      best: best,
      last: last,
      lastLabel: lastLabel,
      standingNote: standingNote,
      pinnedNote: pinnedNote,
      guidance: guidance,
      barInfo: barInfo,
      effortColors: List<String?>.unmodifiable(effortColors),
      setMenuTitles: List<String>.unmodifiable(setMenuTitles),
      setLabels: List<String>.unmodifiable(setLabels),
      isWarmup: List<bool>.unmodifiable(isWarmup),
      isDrop: List<bool>.unmodifiable(isDrop),
      isRestPause: List<bool>.unmodifiable(isRestPause),
      isSide: List<bool>.unmodifiable(isSide),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        ex,
        mode,
        cardio,
        timed,
        bw,
        perSide,
        added,
        col1,
        col2,
        col3,
        best,
        last,
        lastLabel,
        standingNote,
        pinnedNote,
        guidance,
        barInfo,
        effortColors,
        setMenuTitles,
        setLabels,
        isWarmup,
        isDrop,
        isRestPause,
        isSide,
      ];
}
