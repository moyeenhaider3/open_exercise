// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/format.dart';
import '../../../core/format/glyphs.dart';
import '../../../core/i18n/t.dart';
import '../../../core/models/routine.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/ui_kit/buttons.dart';
import '../../../core/ui_kit/icons/app_icon.dart';
import '../../../core/ui_kit/rows.dart';
import '../../../core/ui_kit/toast.dart';
import '../bloc/plan_bloc.dart';
import '../bloc/plan_event.dart';
import '../bloc/plan_state.dart';
import 'sheets/day_add_routine_sheet.dart';
import 'sheets/day_assign_sheet.dart';
import 'sheets/starter_plan_sheet.dart';

/// Weekly workout plan and routines screen.
/// Ported from `../openGym/frontend/src/views/Plan.jsx`.
///
/// Plan 03-11: PlanBloc-driven, SliverList.builder for routines (UI-08),
/// no .mutate() calls, no direct GymStateCubit access.
class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlanBloc, PlanState>(
      listenWhen: (PlanState prev, PlanState cur) =>
          cur.signal != null && cur.seq != prev.seq,
      listener: _onSignal,
      builder: (BuildContext context, PlanState state) {
        return CustomScrollView(
          slivers: <Widget>[
            // Header: 'Plan' / 'Your weekly routine' — share tools deferred to Phase 8 (D-06, IMP-04).
            SliverToBoxAdapter(
              child: ScreenHeader(
                title: t('Plan'),
                subtitle: t('Your weekly routine'),
              ),
            ),

            // Week schedule section — bounded 7-row Column.
            SliverToBoxAdapter(
              child: SectionHeader(t('Week schedule')),
            ),
            SliverToBoxAdapter(
              child: _WeekSchedule(state: state),
            ),

            // Routines section with inline 'New' button.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14.0, 18.0, 14.0, 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      t('Routines').toUpperCase(),
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: AppPalette.of(context).muted,
                      ),
                    ),
                    AppButton(
                      label: Text(t('New')),
                      variant: AppButtonVariant.tinted,
                      icon: 'plus',
                      small: true,
                      onPressed: () =>
                          context.read<PlanBloc>().add(const PlanRoutineAdded()),
                    ),
                  ],
                ),
              ),
            ),

            // Routines list or empty state.
            if (state.routines.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  icon: 'clipboard',
                  text: '${t('No routines yet.')}\n${t('Create one or load the starter plan.')}',
                  action: AppButton(
                    label: Text(t('Load starter plan')),
                    icon: 'sparkles',
                    onPressed: () => showStarterPlanSheet(context),
                  ),
                ),
              )
            else
              SliverList.builder(
                itemCount: state.routines.length,
                itemBuilder: (BuildContext ctx, int i) {
                  return _RoutineRow(
                    routine: state.routines[i],
                    index: i,
                    total: state.routines.length,
                  );
                },
              ),

            // Bottom padding.
            const SliverToBoxAdapter(child: SizedBox(height: 32.0)),
          ],
        );
      },
    );
  }

  void _onSignal(BuildContext context, PlanState state) {
    final PlanSignal? sig = state.signal;
    if (sig == null) return;

    switch (sig) {
      case PlanNavigateToRoutineSignal(:final String routineId):
        context.go(AppRoutes.routinePath(routineId));
      case PlanToastSignal(:final String message):
        showToast(context, message);
      case PlanConfirmStarterSignal():
        // Handled inside StarterPlanChooser's BlocListener.
        break;
    }
  }
}

/// 7-day week schedule section.
class _WeekSchedule extends StatelessWidget {
  const _WeekSchedule({required this.state});

  final PlanState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: state.dayOrder.map((int day) {
        final List<Routine> dayRoutines = state.dayRoutines[day] ?? <Routine>[];
        if (dayRoutines.isEmpty) {
          // Empty day → single tappable row with "Rest" tag.
          return ListItem(
            title: Text(t(kDayNames[day])),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AppTag(label: t('Rest')),
                const SizedBox(width: 8.0),
                const AppIcon('chevronRight', size: 16.0),
              ],
            ),
            onTap: () => showDayAssignSheet(context, day),
          );
        }
        // Populated day → card with sub-rows for each routine + "Add routine" button.
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppPalette.of(context).surface,
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.fromLTRB(14.0, 10.0, 14.0, 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      t(kDayNames[day]),
                      style: const TextStyle(
                          fontSize: 15.0, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      routineCount(dayRoutines.length),
                      style: TextStyle(
                          fontSize: 12.0, color: AppPalette.of(context).muted),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                ...dayRoutines.map((Routine r) => Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 26.0,
                            height: 26.0,
                            decoration: BoxDecoration(
                              color: AppPalette.of(context).surface2,
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            child: Center(
                              child: AppIcon(glyphOf(r.emoji), size: 14.0),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  r.name ?? '',
                                  style: const TextStyle(fontSize: 14.0),
                                ),
                                Text(
                                  exCount(r.ex?.length ?? 0),
                                  style: TextStyle(
                                      fontSize: 12.0,
                                      color: AppPalette.of(context).muted),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const AppIcon('xmark', size: 16.0),
                            tooltip: t('Remove'),
                            visualDensity: VisualDensity.compact,
                            onPressed: () => context.read<PlanBloc>().add(
                                  PlanDayRoutineRemoved(day, r.id ?? ''),
                                ),
                          ),
                        ],
                      ),
                    )),
                TextButton.icon(
                  onPressed: () => showDayAddRoutineSheet(context, day),
                  icon: const AppIcon('plus', size: 14.0),
                  label: Text(t('Add routine')),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        Theme.of(context).colorScheme.onSurface,
                    textStyle: const TextStyle(fontSize: 13.0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4.0, vertical: 4.0),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Single routine row in the routines list.
class _RoutineRow extends StatelessWidget {
  const _RoutineRow({
    required this.routine,
    required this.index,
    required this.total,
  });

  final Routine routine;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    return ListItem(
      leading: Container(
        width: 36.0,
        height: 36.0,
        decoration: BoxDecoration(
          color: AppPalette.of(context).surface2,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Center(child: AppIcon(glyphOf(routine.emoji), size: 18.0)),
      ),
      title: Text(routine.name ?? ''),
      subtitle: Text(exCount(routine.ex?.length ?? 0)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Move up/down buttons shown only when there are multiple routines.
          if (total > 1) ...<Widget>[
            _MoveButton(
              icon: 'chevronUp',
              tooltip: t('Move up'),
              disabled: index == 0,
              onTap: () => context.read<PlanBloc>().add(PlanRoutineMoved(index, -1)),
            ),
            const SizedBox(width: 2.0),
            _MoveButton(
              icon: 'chevronDown',
              tooltip: t('Move down'),
              disabled: index == total - 1,
              onTap: () => context.read<PlanBloc>().add(PlanRoutineMoved(index, 1)),
            ),
            const SizedBox(width: 4.0),
          ],
          const AppIcon('chevronRight', size: 16.0),
        ],
      ),
      onTap: () => context.go(AppRoutes.routinePath(routine.id ?? '')),
    );
  }
}

class _MoveButton extends StatelessWidget {
  const _MoveButton({
    required this.icon,
    required this.tooltip,
    required this.disabled,
    required this.onTap,
  });

  final String icon;
  final String tooltip;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28.0,
      height: 24.0,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(7.0),
          child: Center(
            child: AppIcon(
              icon,
              size: 12.0,
              color: disabled ? AppPalette.of(context).muted.withValues(alpha: 0.4) : null,
            ),
          ),
        ),
      ),
    );
  }
}
