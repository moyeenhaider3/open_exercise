// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/format/format.dart';
import '../../../../core/format/glyphs.dart';
import '../../../../core/i18n/t.dart';
import '../../../../core/js/js_engine_service.dart';
import '../../../../core/js/modules/history_js.dart';
import '../../../../core/models/gym_state.dart';
import '../../../../core/models/routine.dart';
import '../../../../core/models/workout.dart';
import '../../../../core/state/gym_state_cubit.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/icons/app_icon.dart';
import '../../../../core/ui_kit/rows.dart';

/// Small workout summary row used across history, stats, and calendar views.
/// Ported 1:1 from `../openGym/frontend/src/sheets.jsx:WorkoutRow`.
class WorkoutRowTile extends StatelessWidget {
  const WorkoutRowTile({
    super.key,
    required this.workout,
    required this.onTap,
  });

  final Workout workout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final GymState gymState = context.watch<GymStateCubit>().state;
    final JsEngineService engine = context.read<JsEngineService>();

    final Routine? routine = (gymState.routines ?? <Routine>[])
        .where((Routine r) => r.id == workout.routineId)
        .firstOrNull;
    final String glyph = glyphOf(routine?.emoji);

    final String unit = gymState.unit ?? 'kg';
    final List<String> parts = <String>[];
    if (workout.d != null && workout.d!.isNotEmpty) {
      parts.add(fmtDate(workout.d!, long: true));
    }
    if (workout.end != null && workout.start != null) {
      final int durMs = (workout.end! - workout.start!).round();
      if (durMs >= 60000) {
        parts.addAll(durPart(durMs));
      }
    }
    final int doneSets = engine.history.setsDone(workout);
    parts.add(t('{0} sets', <Object>[doneSets]));
    parts.add(fmtVol(workout.vol ?? 0, unit));

    final Widget leading = Container(
      width: 34.0,
      height: 34.0,
      decoration: BoxDecoration(
        color: palette.surface2,
        borderRadius: BorderRadius.circular(8.0),
      ),
      alignment: Alignment.center,
      child: AppIcon(glyph, size: 19.0),
    );

    final List<String> prList = workout.prs ?? const <String>[];

    final Widget trailing = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (prList.isNotEmpty) ...<Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
            decoration: BoxDecoration(
              color: palette.yellow.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AppIcon('trophy', size: 13.0, color: palette.yellow),
                const SizedBox(width: 4.0),
                Text(
                  '${prList.length} PR',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                    color: palette.yellow,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8.0),
        ],
        AppIcon('chevronRight', size: 16.0, color: palette.muted),
      ],
    );

    final String titleText = (workout.name ?? '').isNotEmpty
        ? workout.name!
        : (routine?.name ?? t('Workout'));

    return ListItem(
      leading: leading,
      title: Text(
        titleText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        parts.join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
