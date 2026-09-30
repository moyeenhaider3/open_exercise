// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/catalogue/exercise_catalogue.dart';
import '../../../core/catalogue/exercise_def.dart';
import '../../../core/i18n/t.dart';
import '../../../core/js/js_engine_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/state/gym_state_cubit.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/ui_kit/buttons.dart';
import '../../library/view/exercise_detail_sheet.dart';
import '../../plan/view/sheets/add_to_routine_sheet.dart';
import '../bloc/muscles_bloc.dart';
import 'muscle_explorer.dart';

/// Screen displaying the Muscle Explorer view at `/muscles`.
///
/// Ports `../openGym/frontend/src/views/Muscles.jsx`.
class MusclesScreen extends StatelessWidget {
  const MusclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return BlocProvider<MusclesBloc>(
      create: (BuildContext ctx) => MusclesBloc(
        gymState: ctx.read<GymStateCubit>(),
        catalogue: ctx.read<ExerciseCatalogue>(),
        engine: ctx.read<JsEngineService>(),
      ),
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4.0, 12.0, 16.0, 8.0),
                  child: Row(
                    children: <Widget>[
                      AppIconButton(
                        'chevronLeft',
                        tooltip: t('Exercises'),
                        onPressed: () => context.go(AppRoutes.library),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              t('Explore muscles'),
                              style: const TextStyle(
                                fontSize: 28.0,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              t('Choose a muscle to see exercises that train it.'),
                              style: TextStyle(
                                fontSize: 14.0,
                                color: palette.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: MuscleExplorer(
                    onDetail: (ExerciseDef ex) =>
                        showExerciseDetailSheet(context, ex),
                    onPlan: (ExerciseDef ex) =>
                        showAddToRoutineSheet(context, ex),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
