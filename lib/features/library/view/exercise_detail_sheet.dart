// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/catalogue/exercise_catalogue.dart';
import '../../../../core/catalogue/exercise_def.dart';
import '../../../../core/catalogue/favourites.dart';
import '../../../../core/format/format.dart';
import '../../../../core/format/set_label.dart';
import '../../../../core/i18n/t.dart';
import '../../../../core/js/js_engine_service.dart';
import '../../../../core/js/models/onerm_models.dart';
import '../../../../core/js/modules/bar_js.dart';
import '../../../../core/js/modules/exercises_js.dart';
import '../../../../core/js/modules/history_js.dart';
import '../../../../core/js/modules/onerm_js.dart';
import '../../../../core/models/gym_state.dart';
import '../../../../core/models/set_entry.dart';
import '../../../../core/models/workout.dart';
import '../../../../core/state/gym_state_cubit.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/buttons.dart';
import '../../../../core/ui_kit/controls.dart';
import '../../../../core/ui_kit/icons/app_icon.dart';
import '../../../../core/ui_kit/modals.dart';
import '../../../../core/ui_kit/rows.dart';
import '../../../../core/ui_kit/toast.dart';
import '../../plan/view/sheets/add_to_routine_sheet.dart';
import '../bloc/exercises_bloc.dart';
import '../bloc/exercises_event.dart';
import '../bloc/exercises_state.dart';
import 'bar_weight_editor.dart';
import 'custom_exercise_sheet.dart';
import 'exercise_history_sheet.dart';
import 'exercise_media.dart';

/// Opens the exercise detail bottom sheet.
///
/// Ports `../openGym/frontend/src/sheets.jsx` ExerciseDetail lines 660-702.
Future<void> showExerciseDetailSheet(BuildContext context, ExerciseDef ex) {
  return showAppSheet<void>(
    context,
    (BuildContext ctx) => _ExerciseDetailSheet(ex: ex),
  );
}

class _ExerciseDetailSheet extends StatelessWidget {
  const _ExerciseDetailSheet({required this.ex});

  final ExerciseDef ex;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ExerciseCatalogue catalogue = context.read<ExerciseCatalogue>();
    final JsEngineService engine = context.read<JsEngineService>();

    return BlocListener<ExercisesBloc, ExercisesState>(
      listenWhen: (ExercisesState prev, ExercisesState curr) =>
          curr.signal != null && curr.signal != prev.signal,
      listener: (BuildContext ctx, ExercisesState state) {
        if (state.signal is ExercisesSignalToast) {
          showToast(ctx, (state.signal as ExercisesSignalToast).message);
        }
      },
      child: BlocBuilder<GymStateCubit, GymState>(
        builder: (BuildContext ctx, GymState gymState) {
          final String unit = gymState.unit ?? 'kg';
          final bool fav = isFav(gymState, ex.id);
          final String exName = catalogue.exerciseNameFor(ex);

          final WorkoutEntry? last = engine.history.lastEntryFor(gymState, ex.id);
          final double best = engine.history.bestWeightFor(gymState, ex.id);

          final List<String> primaries = (ex.primaries != null && ex.primaries!.isNotEmpty)
              ? ex.primaries!
              : (ex.tg != null && ex.tg!.isNotEmpty ? <String>[ex.tg!] : <String>[]);
          final List<String> secondaries = (ex.secondaries != null && ex.secondaries!.isNotEmpty)
              ? ex.secondaries!
              : catalogue.smOf(ex);

          String lastInfo = '';
          if (last != null) {
            final String? lastD = last.extra['d'] as String?;
            final String dateStr = lastD != null ? fmtDate(lastD) : '';
            final String setsStr = (last.sets ?? const <SetEntry>[])
                .map((SetEntry s) => setLabel(engine, ex.id, s, null))
                .join(', ');
            lastInfo = ' · ${t('last')} $dateStr: $setsStr';
          }

          final bool isCardio = engine.exercises.isCardio(ex.toJson());
          final bool isAssisted = engine.exercises.isAssisted(ex.toJson());
          final bool usesBar = engine.bar.usesBar(ex.toJson());

          final List<String> steps = ex.st ?? const <String>[];

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Header row with Name and Favourite Star
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _capitalize(exName),
                      style: const TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: AppIcon(
                      fav ? 'starFill' : 'star',
                      size: 22.0,
                      color: fav ? palette.yellow : palette.muted,
                    ),
                    tooltip: fav
                        ? t('Remove from favourites')
                        : t('Add to favourites'),
                    onPressed: () {
                      context
                          .read<ExercisesBloc>()
                          .add(ExerciseFavouriteToggled(ex.id));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              // Media Player
              ExerciseMedia(ex: ex),
              const SizedBox(height: 10.0),
              // Tags Row
              Wrap(
                spacing: 6.0,
                runSpacing: 6.0,
                children: <Widget>[
                  AppTag(label: t(ex.bp), isAccent: true),
                  if (ex.bp == 'cardio')
                    AppTag(
                      label: t(catalogue.muscleName['cardiovascular system'] ??
                          'cardiovascular system'),
                      icon: 'target',
                    )
                  else
                    ...primaries.map(
                      (String s) => AppTag(
                        label: t(catalogue.muscleName[s] ?? s),
                        icon: 'target',
                      ),
                    ),
                  AppTag(label: t(ex.eq), icon: 'dumbbell'),
                  ...secondaries.take(3).map(
                        (String s) => AppTag(
                          label: t(catalogue.muscleName[s] ?? s),
                        ),
                      ),
                ],
              ),
              if (ex.desc != null && ex.desc!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10.0),
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: palette.surface2,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    ex.desc!,
                    style: TextStyle(fontSize: 13.0, color: palette.muted),
                  ),
                ),
              ],
              if (best > 0) ...<Widget>[
                const SizedBox(height: 8.0),
                Row(
                  children: <Widget>[
                    AppIcon('trophy', size: 14.0, color: palette.yellow),
                    const SizedBox(width: 5.0),
                    Text(
                      '${t('Best:')} ',
                      style: const TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${fmtNum(best)} $unit',
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w700,
                        color: palette.acc,
                      ),
                    ),
                    if (lastInfo.isNotEmpty)
                      Expanded(
                        child: Text(
                          lastInfo,
                          style: TextStyle(
                            fontSize: 13.0,
                            color: palette.dim,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 10.0),
              AppButton(
                label: Text(t('Add to my plan')),
                variant: AppButtonVariant.primary,
                icon: 'plus',
                onPressed: () => showAddToRoutineSheet(context, ex),
              ),
              if (last != null) ...<Widget>[
                const SizedBox(height: 6.0),
                AppButton(
                  label: Text(t('History')),
                  icon: 'history',
                  onPressed: () => showExerciseHistorySheet(context, ex.id),
                ),
              ],
              if (ex.custom) ...<Widget>[
                const SizedBox(height: 8.0),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: AppButton(
                        label: Text(t('Edit')),
                        icon: 'pencil',
                        onPressed: () {
                          Navigator.of(context).pop();
                          showCustomExerciseSheet(context, existing: ex);
                        },
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: AppButton(
                        label: Text(t('Delete')),
                        variant: AppButtonVariant.danger,
                        icon: 'trash',
                        onPressed: () {
                          confirmDeleteCustomExercise(
                            context,
                            ex,
                            afterDelete: () => Navigator.of(context).pop(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
              if (usesBar) ...<Widget>[
                const SizedBox(height: 14.0),
                Text(
                  t('Bar weight'),
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: palette.muted,
                  ),
                ),
                const SizedBox(height: 6.0),
                BarWeightEditor(
                  ex: ex,
                  extra: Text(
                    t('You still log the total weight — the bar only feeds the per-side plate math.'),
                    style: TextStyle(fontSize: 12.0, color: palette.muted),
                  ),
                ),
              ],
              if (!isCardio && !isAssisted) ...<Widget>[
                const SizedBox(height: 14.0),
                _OneRMSection(ex: ex),
              ],
              if (steps.isNotEmpty) ...<Widget>[
                const SizedBox(height: 14.0),
                Text(
                  t('How to'),
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: palette.muted,
                  ),
                ),
                const SizedBox(height: 6.0),
                ...List<Widget>.generate(steps.length, (int i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${i + 1}. ',
                          style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                            color: palette.acc,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            steps[i],
                            style: const TextStyle(fontSize: 13.0),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _OneRMSection extends StatefulWidget {
  const _OneRMSection({required this.ex});

  final ExerciseDef ex;

  @override
  State<_OneRMSection> createState() => _OneRMSectionState();
}

class _OneRMSectionState extends State<_OneRMSection> {
  num? _w;
  num? _r;

  @override
  void initState() {
    super.initState();
    final GymState gymState = context.read<GymStateCubit>().state;
    final JsEngineService engine = context.read<JsEngineService>();
    final OnermBest? best = engine.onerm.best1RM(gymState, widget.ex.id);

    _w = best != null
        ? best.w
        : ((gymState.exWeights?[widget.ex.id]?.w) ?? 20.0);
    _r = best != null ? best.r : 5;
  }

  @override
  Widget build(BuildContext context) {
    final GymState gymState = context.watch<GymStateCubit>().state;
    final JsEngineService engine = context.read<JsEngineService>();
    final AppPalette palette = AppPalette.of(context);
    final String unit = gymState.unit ?? 'kg';

    final OnermBest? best = engine.onerm.best1RM(gymState, widget.ex.id);
    final double? est = engine.onerm.estimate1RM(_w ?? 0, _r ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          t('Estimated 1RM'),
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            color: palette.muted,
          ),
        ),
        if (best != null) ...<Widget>[
          const SizedBox(height: 6.0),
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 13.0, color: Theme.of(context).colorScheme.onSurface),
              children: <InlineSpan>[
                TextSpan(text: '${t('From your log:')} '),
                TextSpan(
                  text: '${fmtNum(best.est ?? 0)} $unit',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: palette.acc,
                  ),
                ),
                TextSpan(
                  text: ' · ${t('{0} × {1} on {2}', <Object?>['${fmtNum(best.w ?? 0)} $unit', best.r ?? 0, best.d != null ? fmtDate(best.d!, long: true) : ''])}',
                  style: TextStyle(color: palette.dim),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10.0),
        Row(
          children: <Widget>[
            Expanded(
              child: AppStepper(
                label: t('Weight ({0})', <Object?>[unit]),
                value: _w,
                step: 2.5,
                decimal: true,
                onChanged: (num? next) => setState(() => _w = next ?? 0),
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: AppStepper(
                label: t('Reps'),
                value: _r,
                step: 1,
                decimal: false,
                onChanged: (num? next) => setState(() => _r = next ?? 0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              t('Estimate'),
              style: TextStyle(fontSize: 13.0, color: palette.muted),
            ),
            Text(
              est == null ? '—' : '${fmtNum(est)} $unit',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.w700,
                color: palette.acc,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4.0),
        Text(
          est == null
              ? t(
                  'Enter a weight and 1–{0} reps — beyond that an estimate is guesswork.',
                  <Object?>[engine.onerm.repCap],
                )
              : t('Epley formula — a calculation from one set, not a tested max.'),
          style: TextStyle(fontSize: 12.0, color: palette.dim),
        ),
      ],
    );
  }
}

String _capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}
