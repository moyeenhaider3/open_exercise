// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/catalogue/exercise_catalogue.dart';
import '../../../core/catalogue/exercise_def.dart';
import '../../../core/format/format.dart';
import '../../../core/i18n/t.dart';
import '../../../core/js/js_engine_service.dart';
import '../../../core/js/modules/muscles_js.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/ui_kit/buttons.dart';
import '../../../core/ui_kit/controls.dart';
import '../../../core/ui_kit/modals.dart';
import '../../../core/ui_kit/toast.dart';
import '../bloc/exercises_bloc.dart';
import '../bloc/exercises_event.dart';
import '../bloc/exercises_state.dart';

/// Opens the custom exercise creation or edit bottom sheet.
/// Ported from ../openGym/frontend/src/sheets.jsx:790-880 CustomExForm.
Future<void> showCustomExerciseSheet(
  BuildContext context, {
  ExerciseDef? existing,
  String? prefill,
  void Function(ExerciseDef saved)? onDone,
}) {
  return showAppSheet<void>(
    context,
    (BuildContext ctx) => _CustomExerciseSheet(
      existing: existing,
      prefill: prefill,
      onDone: onDone,
    ),
  );
}

/// Confirms and performs deletion of a custom exercise.
/// Ported from ../openGym/frontend/src/sheets.jsx:881-914 deleteCustomEx.
Future<void> confirmDeleteCustomExercise(
  BuildContext context,
  ExerciseDef ex, {
  VoidCallback? afterDelete,
}) async {
  final ExercisesBloc bloc = context.read<ExercisesBloc>();
  final int before = bloc.state.seq;

  bloc.add(CustomExerciseDeleteRequested(ex));
  final ExercisesState nextState =
      await bloc.stream.firstWhere((ExercisesState s) => s.seq > before);

  if (!context.mounted) return;
  final ExercisesSignal? sig = nextState.signal;

  if (sig is ExercisesSignalToast) {
    showToast(context, sig.message);
    return;
  }

  if (sig is ExercisesSignalConfirmDelete) {
    final bool confirmed = await showConfirmSheet(
      context,
      title: t('Delete “{0}”?', <Object?>[capWords(ex.n)]),
      message: t(
        'This will remove the custom exercise from your library and any routines.',
      ),
      confirmText: t('Delete'),
      danger: true,
    );

    if (confirmed && context.mounted) {
      bloc.add(CustomExerciseDeleted(ex));
      if (afterDelete != null) {
        afterDelete();
      }
    }
  }
}

class _CustomExerciseSheet extends StatefulWidget {
  const _CustomExerciseSheet({
    this.existing,
    this.prefill,
    this.onDone,
  });

  final ExerciseDef? existing;
  final String? prefill;
  final void Function(ExerciseDef saved)? onDone;

  @override
  State<_CustomExerciseSheet> createState() => _CustomExerciseSheetState();
}

class _CustomExerciseSheetState extends State<_CustomExerciseSheet> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late String _bodyPart;
  late String _equipment;
  late List<String> _primaries;
  late List<String> _secondaries;

  @override
  void initState() {
    super.initState();
    final ExerciseCatalogue catalogue = context.read<ExerciseCatalogue>();
    final MusclesJs muscles = context.read<JsEngineService>().muscles;

    final ExerciseDef? ex = widget.existing;
    _nameController = TextEditingController(text: ex?.n ?? widget.prefill ?? '');
    _descController = TextEditingController(text: ex?.desc ?? '');

    _bodyPart = ex?.bp ??
        (catalogue.bodyParts.isNotEmpty ? catalogue.bodyParts.first : 'chest');
    _equipment = ex?.eq ??
        (catalogue.allEquipment.isNotEmpty ? catalogue.allEquipment.first : 'barbell');

    if (ex != null) {
      final Map<String, Object?> exMap = ex.toJson();
      if (muscles.hasExplicitMuscleMetadata(exMap)) {
        _primaries = List<String>.from(
          ex.primaries ?? (ex.tg != null ? <String>[ex.tg!] : const <String>[]),
        );
        _secondaries = List<String>.from(
          ex.secondaries ?? (ex.sm ?? const <String>[]),
        );
      } else {
        _primaries = ex.tg != null ? <String>[ex.tg!] : <String>[];
        _secondaries = List<String>.from(ex.sm ?? const <String>[]);
      }
    } else {
      _primaries = <String>[];
      _secondaries = <String>[];
    }

    if (_equipment == 'cardio' || _bodyPart == 'cardio') {
      _primaries = <String>['cardiovascular system'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      showToast(context, t('Name is required'));
      return;
    }

    final JsEngineService engine = context.read<JsEngineService>();
    final List<String> normalizedGroups = engine.muscles.normalizeMuscleGroups(<String, Object?>{
      'bp': _bodyPart,
      'primaries': _primaries,
      'secondaries': _secondaries,
    });

    final ExercisesBloc bloc = context.read<ExercisesBloc>();
    final int before = bloc.state.seq;

    bloc.add(
      CustomExerciseSaved(
        existingId: widget.existing?.id,
        name: name,
        bodyPart: _bodyPart,
        desc: _descController.text.trim(),
        equipment: _equipment,
        primaries: _primaries,
        secondaries: _secondaries,
        primaryTaps: normalizedGroups,
      ),
    );

    final ExercisesState nextState =
        await bloc.stream.firstWhere((ExercisesState s) => s.seq > before);

    if (mounted) {
      Navigator.of(context).pop();
      if (nextState.signal is ExercisesSignalSaved && widget.onDone != null) {
        final ExercisesSignalSaved sig = nextState.signal as ExercisesSignalSaved;
        widget.onDone!(sig.exercise);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ExerciseCatalogue catalogue = context.read<ExerciseCatalogue>();
    final MusclesJs muscles = context.read<JsEngineService>().muscles;

    final List<String> allMuscles = muscles.muscles;
    final Map<String, String> muscleNames = muscles.muscleName;

    final List<SelectOption<String>> bpOptions = catalogue.bodyParts
        .map(
          (String bp) => SelectOption<String>(
            value: bp,
            label: capWords(bp),
          ),
        )
        .toList();

    final List<SelectOption<String>> eqOptions = catalogue.allEquipment
        .map(
          (String eq) => SelectOption<String>(
            value: eq,
            label: capWords(eq),
          ),
        )
        .toList();

    final List<SelectOption<String>> primaryOptions = allMuscles
        .map(
          (String m) => SelectOption<String>(
            value: m,
            label: capWords(muscleNames[m] ?? m),
          ),
        )
        .toList();

    // Secondaries exclude selected primaries
    final List<SelectOption<String>> secondaryOptions = allMuscles
        .where((String m) => !_primaries.contains(m))
        .map(
          (String m) => SelectOption<String>(
            value: m,
            label: capWords(muscleNames[m] ?? m),
          ),
        )
        .toList();

    final bool isCardio = _equipment == 'cardio' || _bodyPart == 'cardio';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(14.0, 8.0, 14.0, 16.0),
          child: Text(
            widget.existing != null ? t('Edit exercise') : t('Create exercise'),
            style: const TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Name
        TextField(
          controller: _nameController,
          maxLength: 80,
          decoration: InputDecoration(
            labelText: t('Name'),
            hintText: t('Exercise name'),
            filled: true,
            fillColor: palette.surface2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12.0),

        // Body Part
        SelectRow<String>(
          title: t('Body part'),
          value: _bodyPart,
          options: bpOptions,
          onChanged: (String val) {
            setState(() {
              _bodyPart = val;
              if (val == 'cardio') {
                _primaries = <String>['cardiovascular system'];
                _secondaries.clear();
              }
            });
          },
        ),
        const SizedBox(height: 8.0),

        // Equipment
        SelectRow<String>(
          title: t('Equipment'),
          value: _equipment,
          options: eqOptions,
          onChanged: (String val) {
            setState(() {
              _equipment = val;
              if (val == 'cardio') {
                _primaries = <String>['cardiovascular system'];
                _secondaries.clear();
              }
            });
          },
        ),
        const SizedBox(height: 8.0),

        // Primary muscles (disabled/hidden if cardio)
        if (!isCardio) ...<Widget>[
          MultiSelectRow<String>(
            title: t('Primary muscles'),
            values: _primaries,
            options: primaryOptions,
            noneLabel: t('None'),
            doneLabel: t('Done'),
            onToggle: (String m) {
              setState(() {
                if (_primaries.contains(m)) {
                  _primaries.remove(m);
                } else {
                  _primaries.add(m);
                  _secondaries.remove(m);
                }
              });
            },
          ),
          const SizedBox(height: 8.0),

          // Secondary muscles
          MultiSelectRow<String>(
            title: t('Secondary muscles'),
            values: _secondaries,
            options: secondaryOptions,
            noneLabel: t('None'),
            doneLabel: t('Done'),
            onToggle: (String m) {
              setState(() {
                if (_secondaries.contains(m)) {
                  _secondaries.remove(m);
                } else {
                  _secondaries.add(m);
                }
              });
            },
          ),
          const SizedBox(height: 8.0),
        ],

        // Description
        TextField(
          controller: _descController,
          maxLength: 300,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: t('Description'),
            hintText: t('Optional exercise notes or form cues'),
            filled: true,
            fillColor: palette.surface2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20.0),

        // Save button
        SizedBox(
          width: double.infinity,
          child: AppButton(
            label: Text(t('Save')),
            variant: AppButtonVariant.primary,
            onPressed: _handleSave,
          ),
        ),
      ],
    );
  }
}
