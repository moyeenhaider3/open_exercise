// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/t.dart';
import '../../../core/models/gym_state.dart';
import '../../../core/router/app_router.dart';
import '../../../core/state/gym_state_cubit.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/ui_kit/buttons.dart';
import '../../../core/ui_kit/rows.dart';
import '../../../core/ui_kit/toast.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_state.dart';
import 'sections/appearance_section.dart';
import 'sections/data_section.dart';
import 'sections/equipment_section.dart';
import 'sections/general_section.dart';
import 'sections/workout_section.dart';

/// Application settings screen.
///
/// Ports `../openGym/frontend/src/views/Settings.jsx`.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return BlocListener<SettingsBloc, SettingsState>(
      listenWhen: (SettingsState prev, SettingsState cur) =>
          cur.signal != null && cur.seq != prev.seq,
      listener: (BuildContext context, SettingsState state) {
        if (state.signal is SettingsResetDone) {
          context.go(AppRoutes.home);
          showToast(context, t('All data reset'));
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: BlocBuilder<GymStateCubit, GymState>(
            builder: (BuildContext context, GymState state) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4.0, 12.0, 16.0, 0.0),
                      child: Row(
                        children: <Widget>[
                          AppIconButton(
                            'chevronLeft',
                            tooltip: t('Home'),
                            onPressed: () => context.go(AppRoutes.home),
                          ),
                        ],
                      ),
                    ),
                    ScreenHeader(
                      title: t('Settings'),
                    ),
                    SectionHeader(t('Your data')),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: AppRow(
                        icon: 'lock',
                        iconTint: palette.acc,
                        title: Text(t('All data stays on this phone')),
                        subtitle: Text(
                          t('No account, no cloud — back it up anytime with Export below.'),
                        ),
                      ),
                    ),
                    GeneralSection(state: state),
                    WorkoutSection(state: state),
                    EquipmentSection(state: state),
                    AppearanceSection(state: state),
                    const DataSection(),
                    const SizedBox(height: 32.0),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
