// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/catalogue/exercise_def.dart';
import '../../../../core/format/format.dart';
import '../../../../core/i18n/t.dart';
import '../../../../core/js/js_engine_service.dart';
import '../../../../core/js/modules/bar_js.dart';
import '../../../../core/js/modules/exercises_js.dart';
import '../../../../core/js/modules/history_js.dart';
import '../../../../core/js/modules/progression_js.dart';
import '../../../../core/js/modules/rep_range_js.dart';
import '../../../../core/models/gym_state.dart';
import '../../../../core/models/model_extras.dart';
import '../../../../core/models/routine.dart';
import '../../../../core/state/gym_state_cubit.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/buttons.dart';
import '../../../../core/ui_kit/controls.dart';
import '../../../../core/ui_kit/modals.dart';
import '../../../../core/ui_kit/rows.dart';
import '../../../library/view/bar_weight_editor.dart';
import 'progression_fields.dart';

/// Opens the exercise configuration bottom sheet.
/// Ported from ../openGym/frontend/src/sheets.jsx:1175-1426 ExConfig.
Future<void> showExConfigSheet(
  BuildContext context, {
  required ExerciseDef ex,
  RoutineExercise? existing,
  required void Function(RoutineExercise cfg) onSave,
  VoidCallback? onDelete,
  Routine? routine,
  RoutineExercise? initial,
}) {
  return showAppSheet<void>(
    context,
    (BuildContext ctx) => _ExConfigSheet(
      ex: ex,
      existing: existing,
      initial: initial,
      routine: routine,
      onSave: onSave,
      onDelete: onDelete,
    ),
  );
}

class _ExConfigSheet extends StatefulWidget {
  const _ExConfigSheet({
    required this.ex,
    this.existing,
    this.initial,
    this.routine,
    required this.onSave,
    this.onDelete,
  });

  final ExerciseDef ex;
  final RoutineExercise? existing;
  final RoutineExercise? initial;
  final Routine? routine;
  final void Function(RoutineExercise cfg) onSave;
  final VoidCallback? onDelete;

  @override
  State<_ExConfigSheet> createState() => _ExConfigSheetState();
}

class _ExConfigSheetState extends State<_ExConfigSheet> {
  late RoutineExercise _draft;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final JsEngineService engine = context.read<JsEngineService>();
    // Ported from ../openGym/frontend/src/sheets.jsx:1182 initial config seeding.
    _draft = widget.existing ??
        widget.initial ??
        engine.history.defaultConfig(widget.ex.id);

    final String mode = engine.history.modeOf(_draft);
    final String policy = engine.progression.policyFor(_draft, widget.routine, mode);
    if (policy == 'double') {
      final range = engine.repRange.normalizeRepRange(_draft.reps, _draft.repsMin);
      _draft = _draft.copyWith(reps: range.reps).withExtraFields(<String, Object?>{
        'repsMin': range.repsMin,
      });
    }

    _noteController = TextEditingController(text: _draft.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final JsEngineService engine = context.read<JsEngineService>();
    final GymState s = context.watch<GymStateCubit>().state;
    final String unit = s.unit ?? 'kg';

    // Derived values recomputed via bridge facades per JS-04.
    final bool isCardio = engine.exercises.isCardio(widget.ex.id);
    final String mode = engine.history.modeOf(_draft);
    final bool isBw = engine.history.isBw(_draft);
    final bool isPerSide = engine.history.isPerSide(_draft);
    final String policy = engine.progression.policyFor(_draft, widget.routine, mode);
    final bool usesBar = engine.bar.usesBar(widget.ex.id);
    final num weightInc = engine.progression.weightIncrement(_draft, unit);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    capWords(widget.ex.n),
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    '${capWords(widget.ex.eq)} · ${capWords(widget.ex.tg ?? widget.ex.bp)}',
                    style: TextStyle(fontSize: 13.0, color: palette.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),

        // Reps / Time mode switcher (for non-cardio exercises)
        // Ported from ../openGym/frontend/src/sheets.jsx:1210-1225.
        if (!isCardio) ...<Widget>[
          AppSegmented<String>(
            options: <SegmentOption<String>>[
              SegmentOption<String>(value: 'reps', label: t('Reps')),
              SegmentOption<String>(value: 'time', label: t('Time')),
            ],
            value: mode == 'time' ? 'time' : 'reps',
            onChanged: (String nextMode) {
              setState(() {
                _draft = _draft.withExtraFields(<String, Object?>{
                  'mode': nextMode,
                });
              });
            },
          ),
          const SizedBox(height: 16.0),
        ],

        // Sets count
        AppStepper(
          label: t('Sets'),
          value: _draft.sets ?? 3,
          step: 1,
          decimal: false,
          onChanged: (num? nextSets) {
            if (nextSets != null && nextSets >= 1) {
              setState(() {
                _draft = _draft.copyWith(sets: nextSets);
              });
            }
          },
        ),
        const SizedBox(height: 8.0),

        // Mode-specific steppers
        if (mode == 'time') ...<Widget>[
          AppStepper(
            label: t('Duration (sec)'),
            value: _draft.sec ?? 30,
            step: 5,
            decimal: false,
            onChanged: (num? nextSec) {
              if (nextSec != null && nextSec >= 1) {
                setState(() {
                  _draft = _draft.withExtraFields(<String, Object?>{'sec': nextSec});
                });
              }
            },
          ),
          const SizedBox(height: 8.0),
        ] else if (isCardio) ...<Widget>[
          AppStepper(
            label: t('Duration (min)'),
            value: _draft.min ?? 20,
            step: 5,
            decimal: false,
            onChanged: (num? nextMin) {
              if (nextMin != null && nextMin >= 1) {
                setState(() {
                  _draft = _draft.withExtraFields(<String, Object?>{'min': nextMin});
                });
              }
            },
          ),
          const SizedBox(height: 8.0),
          AppStepper(
            label: t('Speed'),
            value: _draft.speed,
            step: 0.5,
            onChanged: (num? nextSpeed) {
              setState(() {
                _draft = _draft.withExtraFields(<String, Object?>{'speed': nextSpeed});
              });
            },
          ),
          const SizedBox(height: 8.0),
        ] else ...<Widget>[
          // Reps mode: single reps target or double progression range
          if (policy == 'double') ...<Widget>[
            AppStepper(
              label: t('Min reps'),
              value: _draft.repsMin ?? 8,
              step: 1,
              decimal: false,
              onChanged: (num? nextMin) {
                if (nextMin != null && nextMin >= 1) {
                  final range = engine.repRange.normalizeRepRange(
                    _draft.reps,
                    nextMin,
                  );
                  setState(() {
                    _draft = _draft.copyWith(reps: range.reps).withExtraFields(<String, Object?>{
                      'repsMin': range.repsMin,
                    });
                  });
                }
              },
            ),
            const SizedBox(height: 8.0),
            AppStepper(
              label: t('Target reps'),
              value: _draft.reps ?? 12,
              step: 1,
              decimal: false,
              onChanged: (num? nextTarget) {
                if (nextTarget != null && nextTarget >= 1) {
                  final range = engine.repRange.normalizeRepRange(
                    nextTarget,
                    _draft.repsMin,
                  );
                  setState(() {
                    _draft = _draft.copyWith(reps: range.reps).withExtraFields(<String, Object?>{
                      'repsMin': range.repsMin,
                    });
                  });
                }
              },
            ),
            const SizedBox(height: 8.0),
          ] else ...<Widget>[
            AppStepper(
              label: t('Reps'),
              value: _draft.reps ?? 10,
              step: engine.history.repStep(_draft),
              decimal: false,
              onChanged: (num? nextReps) {
                if (nextReps != null && nextReps >= 1) {
                  setState(() {
                    _draft = _draft.copyWith(reps: nextReps);
                  });
                }
              },
            ),
            const SizedBox(height: 8.0),
          ],

          // Weight / Extra weight
          if (!isBw) ...<Widget>[
            AppStepper(
              label: t('Weight ({0})', <Object?>[unit]),
              value: _draft.weight ?? 0,
              step: weightInc > 0 ? weightInc : 2.5,
              onChanged: (num? nextWeight) {
                setState(() {
                  _draft = _draft.copyWith(weight: nextWeight ?? 0);
                });
              },
            ),
            const SizedBox(height: 8.0),
          ] else ...<Widget>[
            AppStepper(
              label: t('Extra weight ({0})', <Object?>[unit]),
              value: _draft.bw ?? 0,
              step: weightInc > 0 ? weightInc : 2.5,
              onChanged: (num? nextBw) {
                setState(() {
                  _draft = _draft.withExtraFields(<String, Object?>{'bw': nextBw ?? 0});
                });
              },
            ),
            const SizedBox(height: 8.0),
          ],
        ],

        // Switches: Bodyweight & Per-side
        AppRow(
          title: Text(t('Bodyweight')),
          child: AppSwitch(
            value: isBw,
            onChanged: (bool on) {
              setState(() {
                if (on) {
                  _draft = _draft.withExtraFields(<String, Object?>{'bw': 0});
                } else {
                  _draft = _draft.withExtraFields(
                    const <String, Object?>{},
                    remove: const <String>['bw'],
                  );
                }
              });
            },
          ),
        ),
        AppRow(
          title: Text(t('Per-side')),
          child: AppSwitch(
            value: isPerSide,
            onChanged: (bool on) {
              setState(() {
                _draft = _draft.withExtraFields(<String, Object?>{'perSide': on});
              });
            },
          ),
        ),
        const SizedBox(height: 8.0),

        // Warm-ups
        AppStepper(
          label: t('Warm-up sets'),
          value: _draft.warmups ?? 0,
          step: 1,
          decimal: false,
          onChanged: (num? nextWarmups) {
            final int maxWarmups = engine.history.maxPlannedWarmups;
            final int clamped = (nextWarmups?.toInt() ?? 0).clamp(0, maxWarmups);
            setState(() {
              _draft = _draft.withExtraFields(<String, Object?>{'warmups': clamped});
            });
          },
        ),
        const SizedBox(height: 8.0),

        // Rest timer setting
        AppStepper(
          label: t('Rest (sec)'),
          value: _draft.restSec ?? 90,
          step: 15,
          decimal: false,
          onChanged: (num? nextRest) {
            if (nextRest != null && nextRest >= 0) {
              setState(() {
                _draft = _draft.withExtraFields(<String, Object?>{'restSec': nextRest});
              });
            }
          },
        ),
        const SizedBox(height: 8.0),

        // Notes field
        TextField(
          controller: _noteController,
          maxLength: engine.history.noteMax,
          decoration: InputDecoration(
            labelText: t('Note'),
            hintText: t('Add note...'),
            filled: true,
            fillColor: palette.surface2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (String text) {
            _draft = _draft.copyWith(note: text.trim().isEmpty ? null : text.trim());
          },
        ),
        const SizedBox(height: 8.0),

        // Progression sub-form
        ProgressionFields(
          cfg: _draft,
          ex: widget.ex,
          routine: widget.routine,
          onChanged: (RoutineExercise updated) {
            setState(() {
              _draft = updated;
            });
          },
        ),
        const SizedBox(height: 12.0),

        // Bar weight editor (if exercise uses a bar)
        if (usesBar) ...<Widget>[
          const SectionHeader('Bar weight'),
          BarWeightEditor(ex: widget.ex),
          const SizedBox(height: 16.0),
        ],

        // Action Buttons: Save & Delete
        const SizedBox(height: 8.0),
        Row(
          children: <Widget>[
            if (widget.onDelete != null) ...<Widget>[
              Expanded(
                child: AppButton(
                  label: Text(t('Delete')),
                  variant: AppButtonVariant.danger,
                  onPressed: () async {
                    final bool confirmed = await showConfirmSheet(
                      context,
                      title: t('Remove exercise'),
                      message: t('Are you sure you want to remove this exercise?'),
                      confirmText: t('Delete'),
                      danger: true,
                    );
                    if (confirmed && context.mounted) {
                      widget.onDelete!();
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12.0),
            ],
            Expanded(
              child: AppButton(
                label: Text(t('Save')),
                variant: AppButtonVariant.primary,
                onPressed: () {
                  final String noteText = _noteController.text.trim();
                  final RoutineExercise finalCfg = _draft.copyWith(
                    note: noteText.isEmpty ? null : noteText,
                  );
                  widget.onSave(finalCfg);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
