// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/format/format.dart';
import '../../../../core/i18n/t.dart';
import '../../../../core/js/js_engine_service.dart';
import '../../../../core/js/modules/backfill_js.dart';
import '../../../../core/models/gym_state.dart';
import '../../../../core/models/routine.dart';
import '../../../../core/models/workout.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/state/gym_state_cubit.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/buttons.dart';
import '../../../../core/ui_kit/controls.dart';
import '../../../../core/ui_kit/modals.dart';
import '../../../../core/ui_kit/rows.dart';
import '../../../../core/ui_kit/toast.dart';
import '../../../workout/bloc/workout_bloc.dart';
import '../../../workout/bloc/workout_event.dart';

/// Opens the "Log a past workout" sheet.
///
/// Ports openGym `sheets.jsx` LogPastWorkout, SameDayChoice, and logPastWorkoutSheet
/// (lines 1834-1907).
Future<void> showLogPastWorkoutSheet(BuildContext context) async {
  final GymState state = context.read<GymStateCubit>().state;
  if (state.active != null) {
    showToast(context, t('Finish the current workout first.'));
    return;
  }

  return showAppSheet<void>(
    context,
    (BuildContext ctx) => const _LogPastWorkoutSheet(),
  );
}

class _LogPastWorkoutSheet extends StatefulWidget {
  const _LogPastWorkoutSheet();

  @override
  State<_LogPastWorkoutSheet> createState() => _LogPastWorkoutSheetState();
}

class _LogPastWorkoutSheetState extends State<_LogPastWorkoutSheet> {
  late String _date;
  String _time = '18:00';
  int _durationMin = 45;
  String _routineId = '';

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _date = isoOf(DateTime(now.year, now.month, now.day - 1));
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime initial =
        DateTime.tryParse(_date) ?? DateTime(now.year, now.month, now.day - 1);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked != null) {
      setState(() {
        _date = isoOf(picked);
      });
    }
  }

  Future<void> _pickTime() async {
    final List<String> parts = _time.split(':');
    final int h = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 18 : 18;
    final int m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: h, minute: m),
    );
    if (picked != null) {
      final String hour = picked.hour.toString().padLeft(2, '0');
      final String min = picked.minute.toString().padLeft(2, '0');
      setState(() {
        _time = '$hour:$min';
      });
    }
  }

  Future<void> _submit() async {
    if (_date.isEmpty || _date.compareTo(todayIso()) > 0) {
      showToast(context, t('Pick a day up to today'));
      return;
    }

    final GymState state = context.read<GymStateCubit>().state;
    final JsEngineService engine = context.read<JsEngineService>();
    final List<Workout> existing = engine.backfill.workoutsOn(state, _date);

    if (existing.isEmpty) {
      _startBackfill(null);
    } else {
      await _showSameDayChoice(existing);
    }
  }

  Future<void> _showSameDayChoice(List<Workout> existing) async {
    final AppPalette palette = AppPalette.of(context);
    final String? choice = await showCenterDialog<String?>(
      context,
      (BuildContext ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              fmtDate(_date, long: true),
              style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            Text(
              t('There is already a workout on that day.'),
              style: TextStyle(fontSize: 14.0, color: palette.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20.0),
            for (final Workout w in existing) ...<Widget>[
              AppButton(
                label: Text(
                  existing.length > 1
                      ? '${t('Replace')} · ${w.name ?? t('Workout')}'
                      : t('Replace'),
                ),
                variant: AppButtonVariant.danger,
                onPressed: () => Navigator.of(ctx).pop(w.id),
              ),
              const SizedBox(height: 8.0),
            ],
            AppButton(
              label: Text(t('Add as second workout')),
              variant: AppButtonVariant.primary,
              onPressed: () => Navigator.of(ctx).pop('__add_second__'),
            ),
            const SizedBox(height: 8.0),
            AppButton(
              label: Text(t('Cancel')),
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.of(ctx).pop(null),
            ),
          ],
        );
      },
    );

    if (choice == null) return;
    final String? replaceId = choice == '__add_second__' ? null : choice;
    if (mounted) {
      _startBackfill(replaceId);
    }
  }

  void _startBackfill(String? replaceId) {
    context.read<WorkoutBloc>().add(
      WorkoutBackfillStarted(
        iso: _date,
        time: _time,
        durationMin: _durationMin,
        routineId: _routineId.isEmpty ? null : _routineId,
        replaceId: replaceId,
      ),
    );
    Navigator.of(context).pop();
    context.go(AppRoutes.workout);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final GymState state = context.watch<GymStateCubit>().state;
    final List<Routine> routines = state.routines ?? const <Routine>[];

    final List<SelectOption<String>> routineOptions = <SelectOption<String>>[
      SelectOption<String>(value: '', label: t('Freestyle')),
      ...routines.map(
        (Routine r) => SelectOption<String>(
          value: r.id ?? '',
          label: r.name ?? t('Routine'),
        ),
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          t('Log a past workout'),
          style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4.0),
        Text(
          t('Logged on the usual workout screen, without timers.'),
          style: TextStyle(fontSize: 14.0, color: palette.muted),
        ),
        const SizedBox(height: 16.0),
        AppRow(
          icon: 'calendar',
          title: Text(t('Date')),
          value: Text(fmtDate(_date, long: true)),
          accessory: AppRowAccessory.chevron,
          onTap: _pickDate,
        ),
        AppRow(
          icon: 'clock',
          title: Text(t('Start time')),
          value: Text(_time),
          accessory: AppRowAccessory.chevron,
          onTap: _pickTime,
        ),
        AppRow(
          icon: 'stopwatch',
          title: Text(t('Duration')),
          child: AppStepper(
            value: _durationMin,
            step: 5,
            unit: 'min',
            decimal: false,
            onChanged: (num? v) {
              final int n = (v ?? 1).round();
              setState(() => _durationMin = math.max(1, n));
            },
          ),
        ),
        SelectRow<String>(
          title: t('Routine'),
          value: _routineId,
          options: routineOptions,
          onChanged: (String val) => setState(() => _routineId = val),
        ),
        const SizedBox(height: 20.0),
        AppButton(
          label: Text(t('Continue')),
          variant: AppButtonVariant.primary,
          onPressed: _submit,
        ),
      ],
    );
  }
}
