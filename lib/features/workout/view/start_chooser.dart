// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/format.dart';
import '../../../core/format/glyphs.dart';
import '../../../core/i18n/t.dart';
import '../../../core/js/js_engine_service.dart';
import '../../../core/js/modules/history_js.dart';
import '../../../core/models/gym_state.dart';
import '../../../core/models/routine.dart';
import '../../../core/router/app_router.dart';
import '../../../core/state/gym_state_cubit.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/ui_kit/buttons.dart';
import '../../../core/ui_kit/icons/app_icon.dart';
import '../../../core/ui_kit/rows.dart';
import 'start_flow.dart';

/// Pre-calculated view data for the StartChooser screen.
class StartChooserData {
  const StartChooserData({
    required this.todayIds,
    required this.todayRoutines,
    required this.todayName,
    required this.todayOvr,
    required this.others,
    required this.hasAnyRoutines,
  });

  final List<String> todayIds;
  final List<Routine> todayRoutines;
  final String todayName;
  final bool todayOvr;
  final List<Routine> others;
  final bool hasAnyRoutines;
}

/// Chooser screen displayed on /workout when no session is active.
///
/// Ported from `../openGym/frontend/src/views/Workout.jsx` lines 31-60 StartChooser.
class StartChooser extends StatelessWidget {
  const StartChooser({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final HistoryJs history = context.read<JsEngineService>().history;

    // Read-only projection from GymStateCubit via HistoryJs facade is permitted for StartChooserData.
    return BlocSelector<GymStateCubit, GymState, StartChooserData>(
      selector: (GymState s) {
        final String today = todayIso();
        final List<String> todayIds = history.effectiveRoutineIds(s, today);
        final List<Routine> todayRoutines = history.effectiveRoutines(s, today);
        final String todayName =
            todayRoutines.map((Routine r) => r.name ?? '').where((String n) => n.isNotEmpty).join(' + ');
        final bool todayOvr = s.dayPlan != null && s.dayPlan!.containsKey(today);
        final Set<String> idSet = todayIds.toSet();
        final List<Routine> others = (s.routines ?? const <Routine>[])
            .where((Routine r) => !idSet.contains(r.id))
            .toList();
        final bool hasAnyRoutines = (s.routines != null && s.routines!.isNotEmpty);

        return StartChooserData(
          todayIds: todayIds,
          todayRoutines: todayRoutines,
          todayName: todayName,
          todayOvr: todayOvr,
          others: others,
          hasAnyRoutines: hasAnyRoutines,
        );
      },
      builder: (BuildContext context, StartChooserData data) {
        final int weekdayIdx = DateTime.now().weekday % 7;
        final String weekdayName = t(kDayNames[weekdayIdx]);
        final String subtitle = data.todayRoutines.isNotEmpty
            ? '$weekdayName — ${t('today is {0}', <Object?>[data.todayName])}'
            : '$weekdayName — ${t('rest day, but no one’s stopping you')}';

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Header
                  Text(
                    t('Start workout'),
                    style: const TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14.0,
                      color: palette.muted,
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Today's plan card
                  if (data.todayRoutines.isNotEmpty) ...<Widget>[
                    AppCard(
                      accentBorder: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            "${t("Today's plan")}${data.todayOvr ? ' · ${t('rescheduled')}' : ''}",
                            style: TextStyle(
                              color: palette.acc,
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      data.todayName,
                                      style: const TextStyle(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2.0),
                                    Text(
                                      exCount(data.todayRoutines.fold<int>(
                                        0,
                                        (int n, Routine r) => n + (r.ex?.length ?? 0),
                                      )),
                                      style: TextStyle(
                                        fontSize: 13.0,
                                        color: palette.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 38.0,
                                height: 38.0,
                                decoration: BoxDecoration(
                                  color: palette.surface2,
                                  borderRadius: BorderRadius.circular(9.0),
                                ),
                                child: Center(
                                  child: AppIcon(
                                    glyphOf(data.todayRoutines.first.emoji),
                                    size: 22.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12.0),
                          AppButton(
                            label: Text(t('Start {0}', <Object?>[data.todayName])),
                            icon: 'play',
                            variant: AppButtonVariant.primary,
                            onPressed: () => startFlow(context, data.todayIds),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),
                  ],

                  // Other routines list
                  if (data.others.isNotEmpty) ...<Widget>[
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                      child: Text(
                        t('Other routines'),
                        style: TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                          color: palette.muted,
                        ),
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: data.others.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Routine r = data.others[index];
                        return ListItem(
                          leading: Container(
                            width: 32.0,
                            height: 32.0,
                            decoration: BoxDecoration(
                              color: palette.surface2,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Center(
                              child: AppIcon(
                                glyphOf(r.emoji),
                                size: 18.0,
                              ),
                            ),
                          ),
                          title: Text(r.name ?? ''),
                          subtitle: Text(exCount(r.ex?.length ?? 0)),
                          trailing: AppTag(
                            label: t('Start'),
                            isAccent: true,
                          ),
                          onTap: () {
                            if (r.id != null) {
                              startFlow(context, <String>[r.id!]);
                            }
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 14.0),
                  ],

                  // Freestyle workout button
                  AppButton(
                    label: Text(t('Freestyle workout (pick as you go)')),
                    icon: 'shuffle',
                    variant: AppButtonVariant.plain,
                    onPressed: () => startFlow(context, const <String>[]),
                  ),

                  // If no routines exist in library, offer to build a plan first
                  if (!data.hasAnyRoutines) ...<Widget>[
                    const SizedBox(height: 10.0),
                    AppButton(
                      label: Text(t('Build a plan first')),
                      variant: AppButtonVariant.primary,
                      onPressed: () => context.go(AppRoutes.plan),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
