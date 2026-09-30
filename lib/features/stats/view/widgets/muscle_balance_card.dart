// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/body_map/body_map.dart';
import '../../../../core/format/format.dart';
import '../../../../core/i18n/t.dart';
import '../../../../core/js/js_engine_service.dart';
import '../../../../core/js/models/muscle_models.dart';
import '../../../../core/state/gym_state_cubit.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/buttons.dart';
import '../../../../core/ui_kit/controls.dart';
import '../../../../core/ui_kit/rows.dart';
import '../../../library/view/exercise_history_sheet.dart';
import '../../bloc/muscle_balance_bloc.dart';
import '../../bloc/muscle_balance_event.dart';
import '../../bloc/muscle_balance_state.dart';

/// Card showing muscle balance, fatigue, and strength body maps.
/// Ports `../openGym/frontend/src/views/Stats.jsx` lines 80-232 (MuscleBalance).
class MuscleBalanceCard extends StatelessWidget {
  const MuscleBalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MuscleBalanceBloc>(
      create: (BuildContext ctx) => MuscleBalanceBloc(
        gymState: ctx.read<GymStateCubit>(),
        engine: ctx.read<JsEngineService>(),
      ),
      child: const _MuscleBalanceCardContent(),
    );
  }
}

class _MuscleBalanceCardContent extends StatelessWidget {
  const _MuscleBalanceCardContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MuscleBalanceBloc, MuscleBalanceState>(
      builder: (BuildContext context, MuscleBalanceState state) {
        if (state is! MuscleBalanceReady) {
          return const SizedBox.shrink();
        }

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppSegmented<String>(
                value: state.view,
                onChanged: (String v) => context
                    .read<MuscleBalanceBloc>()
                    .add(MuscleBalanceViewChanged(v)),
                options: <SegmentOption<String>>[
                  SegmentOption<String>(value: 'balance', label: t('Muscle balance')),
                  SegmentOption<String>(value: 'fatigue', label: t('Fatigue')),
                  SegmentOption<String>(value: 'strength', label: t('Strength')),
                ],
              ),
              const SizedBox(height: 14.0),
              switch (state.view) {
                'fatigue' => _FatigueSection(state: state),
                'strength' => _StrengthSection(state: state),
                _ => _BalanceSection(state: state),
              },
            ],
          ),
        );
      },
    );
  }
}

class _BalanceSection extends StatelessWidget {
  const _BalanceSection({required this.state});

  final MuscleBalanceReady state;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final MuscleBalanceView balance = state.balance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Flexible(
              child: Row(
                children: <Widget>[
                  Text(
                    t('Muscle balance'),
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.015,
                    ),
                  ),
                  Text(
                    ' · ',
                    style: TextStyle(
                      fontSize: 13.0,
                      color: palette.dim,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      balance.on ? t('by hard sets') : t('by sets worked'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.0,
                        color: palette.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (balance.rated)
              Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                        onSurface: state.hard ? palette.yellow : null,
                      ),
                ),
                child: AppButton(
                  small: true,
                  icon: 'flame',
                  label: Text(
                    state.hard ? t('Hard') : t('All'),
                    style: TextStyle(
                      color: state.hard ? palette.yellow : null,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => context
                      .read<MuscleBalanceBloc>()
                      .add(const MuscleBalanceHardToggled()),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12.0),
        AppSegmented<int>(
          value: state.win,
          onChanged: (int v) => context
              .read<MuscleBalanceBloc>()
              .add(MuscleBalanceWindowChanged(v)),
          options: <SegmentOption<int>>[
            SegmentOption<int>(value: 7, label: t('Week')),
            const SegmentOption<int>(value: 30, label: '30d'),
            const SegmentOption<int>(value: 90, label: '90d'),
            SegmentOption<int>(value: 0, label: t('All')),
          ],
        ),
        const SizedBox(height: 14.0),
        if (balance.inWinCount > 0) ...<Widget>[
          BodyMap(
            body: state.body,
            levels: balance.levels,
            selected: state.selected,
            onMuscle: (String slug) => context
                .read<MuscleBalanceBloc>()
                .add(MuscleBalanceMuscleToggled(slug)),
          ),
          const BodyMapLegend(variant: BodyMapVariant.balance),
          if (state.selected != null)
            _MRow(
              name: state.muscleNames[state.selected] ?? state.selected!,
              bold: true,
              borderTop: true,
              valueText: t('{0} sets', <Object>[
                fmtNum(balance.sets[state.selected] ?? 0),
              ]),
            )
          else
            for (final MuscleTopRow row in balance.top)
              _MRow(
                name: state.muscleNames[row.slug] ?? row.slug,
                pct: row.pct,
                barColor: balance.on ? palette.yellow : palette.acc,
                valueText: t('{0} sets', <Object>[
                  fmtNum(balance.sets[row.slug] ?? 0),
                ]),
              ),
          if (balance.missed.isNotEmpty) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                balance.on
                    ? t('No hard sets in this period')
                    : t('Not trained in this period'),
                style: const TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _MChips(
              children: <Widget>[
                for (final String slug in balance.missed)
                  _MChip(
                    label: state.muscleNames[slug] ?? slug,
                    miss: true,
                  ),
              ],
            ),
          ] else if (balance.worked.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Text(
                balance.on
                    ? t('Every muscle group got at least one hard set in this period.')
                    : t('Every muscle group got some work in this period.'),
                style: TextStyle(
                  fontSize: 12.0,
                  color: palette.muted,
                ),
              ),
            ),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Text(
              t('No workouts in this period yet.'),
              style: TextStyle(
                fontSize: 12.0,
                color: palette.muted,
              ),
            ),
          ),
      ],
    );
  }
}

class _FatigueSection extends StatelessWidget {
  const _FatigueSection({required this.state});

  final MuscleBalanceReady state;

  String _fatigueLabel(String? s) {
    if (s == 'ready') return t('Ready');
    if (s == 'recovering') return t('Recovering');
    return t('Fatigued');
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final FatigueView fatigue = state.fatigue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          t('Fatigue'),
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.015,
          ),
        ),
        const SizedBox(height: 14.0),
        BodyMap(
          body: state.body,
          variant: BodyMapVariant.fatigue,
          levels: fatigue.levels,
          selected: state.selected,
          onMuscle: (String slug) => context
              .read<MuscleBalanceBloc>()
              .add(MuscleBalanceMuscleToggled(slug)),
        ),
        const BodyMapLegend(variant: BodyMapVariant.fatigue),
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Text(
            t('Fatigue shows how recently each muscle was trained. High means rest.'),
            style: TextStyle(
              fontSize: 12.0,
              color: palette.muted,
            ),
          ),
        ),
        if (state.selected != null)
          _MRow(
            name: state.muscleNames[state.selected] ?? state.selected!,
            bold: true,
            borderTop: true,
            valueText: _fatigueLabel(fatigue.states[state.selected]),
          ),
      ],
    );
  }
}

class _StrengthSection extends StatelessWidget {
  const _StrengthSection({required this.state});

  final MuscleBalanceReady state;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final StrengthView strength = state.strength;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          t('Strength'),
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.015,
          ),
        ),
        const SizedBox(height: 14.0),
        BodyMap(
          body: state.body,
          variant: BodyMapVariant.strength,
          levels: strength.levels,
          selected: state.selected,
          onMuscle: (String slug) => context
              .read<MuscleBalanceBloc>()
              .add(MuscleBalanceMuscleToggled(slug)),
        ),
        BodyMapLegend(
          variant: BodyMapVariant.strength,
          strengthFloor: strength.strengthFloor,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Text(
            t('Strength shows retained muscle strength. Train again to reset it.'),
            style: TextStyle(
              fontSize: 12.0,
              color: palette.muted,
            ),
          ),
        ),
        if (state.selected != null) ...<Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 14.0, bottom: 6.0),
            child: Row(
              children: <Widget>[
                Text(
                  t('Exercises'),
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: palette.muted,
                  ),
                ),
                Text(
                  ' · ',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: palette.dim,
                  ),
                ),
                Text(
                  state.muscleNames[state.selected] ?? state.selected!,
                  style: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (strength.exercises.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                t('No exercises with an estimated 1RM yet.'),
                style: TextStyle(
                  fontSize: 13.0,
                  color: palette.muted,
                ),
              ),
            )
          else
            for (final StrengthExerciseRow ex in strength.exercises)
              _StrengthExerciseItem(
                row: ex,
                sel: state.selected!,
                unit: state.unit,
              ),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Text(
              t('Tap a muscle to see its exercises.'),
              style: TextStyle(
                fontSize: 13.0,
                color: palette.muted,
              ),
            ),
          ),
        for (final DetrainedRow row in strength.detrained)
          _MRow(
            name: state.muscleNames[row.slug] ?? row.slug,
            pct: row.pct,
            valueWidget: row.sets90 != 0
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        t('{0} sets', <Object>[fmtNum(row.sets90)]),
                        style: TextStyle(
                          fontSize: 12.0,
                          color: palette.muted,
                        ),
                      ),
                      Text(
                        row.weeks == null
                            ? t('not trained')
                            : t('Weeks since training: {0}', <Object>[row.weeks!]),
                        style: TextStyle(
                          fontSize: 10.0,
                          color: palette.dim,
                        ),
                      ),
                    ],
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 52.0),
                    child: Text(
                      row.weeks == null
                          ? t('not trained')
                          : t('Weeks since training: {0}', <Object>[row.weeks!]),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12.0,
                        color: palette.muted,
                      ),
                    ),
                  ),
          ),
      ],
    );
  }
}

class _StrengthExerciseItem extends StatelessWidget {
  const _StrengthExerciseItem({
    required this.row,
    required this.sel,
    required this.unit,
  });

  final StrengthExerciseRow row;
  final String sel;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return InkWell(
      onTap: () => showExerciseHistorySheet(context, row.id),
      borderRadius: BorderRadius.circular(8.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            row.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6.0),
                        Text(
                          row.primary == sel ? t('primary') : t('secondary'),
                          style: TextStyle(
                            fontSize: 11.0,
                            color: palette.dim,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      '${t('Est. 1RM')}: ${fmtNum(row.est)} $unit · ${fmtDate(row.estDate, long: true)}',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: palette.dim,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 9.0),
              Container(
                width: 74.0,
                height: 5.0,
                decoration: BoxDecoration(
                  color: palette.surface2,
                  borderRadius: BorderRadius.circular(3.0),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: (row.decayPct / 100.0).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: palette.acc,
                        borderRadius: BorderRadius.circular(3.0),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9.0),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 52.0),
                child: Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: '${fmtNum(row.current)} $unit',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: palette.muted,
                        ),
                      ),
                      TextSpan(
                        text: ' · ${row.decayPct}%',
                        style: TextStyle(
                          fontSize: 11.0,
                          color: palette.dim,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MRow extends StatelessWidget {
  const _MRow({
    required this.name,
    this.bold = false,
    this.pct,
    this.barColor,
    this.valueText,
    this.valueWidget,
    this.borderTop = false,
  });

  final String name;
  final bool bold;
  final int? pct;
  final Color? barColor;
  final String? valueText;
  final Widget? valueWidget;
  final bool borderTop;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Widget val = valueWidget ??
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 52.0),
          child: Text(
            valueText ?? '',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 12.0, color: palette.muted),
          ),
        );

    final Widget row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (pct != null) ...<Widget>[
            const SizedBox(width: 9.0),
            Container(
              width: 74.0,
              height: 5.0,
              decoration: BoxDecoration(
                color: palette.surface2,
                borderRadius: BorderRadius.circular(3.0),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: (pct! / 100.0).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: barColor ?? palette.acc,
                      borderRadius: BorderRadius.circular(3.0),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(width: 9.0),
          val,
        ],
      ),
    );

    if (borderTop) {
      return Container(
        margin: const EdgeInsets.only(top: 4.0),
        padding: const EdgeInsets.only(top: 10.0),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: palette.sep, width: 0.5),
          ),
        ),
        child: row,
      );
    }
    return row;
  }
}

class _MChips extends StatelessWidget {
  const _MChips({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Wrap(
        spacing: 6.0,
        runSpacing: 6.0,
        children: children,
      ),
    );
  }
}

class _MChip extends StatelessWidget {
  const _MChip({required this.label, this.miss = false});

  final String label;
  final bool miss;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Color bg = miss
        ? Color.lerp(Colors.transparent, palette.orange, 0.16)!
        : palette.surface2;
    final Color fg = miss ? palette.orange : palette.muted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.0,
          color: fg,
        ),
      ),
    );
  }
}
