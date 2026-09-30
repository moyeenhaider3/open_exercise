// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/format/format.dart';
import '../../../core/i18n/t.dart';
import '../../../core/js/js_engine_service.dart';
import '../../../core/js/modules/history_js.dart';
import '../../../core/models/bodyweight_entry.dart';
import '../../../core/models/gym_state.dart';
import '../../../core/state/gym_state_cubit.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/ui_kit/buttons.dart';
import '../../../core/ui_kit/icons/app_icon.dart';
import '../../../core/ui_kit/modals.dart';
import '../../../core/ui_kit/toast.dart';
import '../../workout/view/sheets/weight_input.dart';
import '../bloc/bodyweight_bloc.dart';
import '../bloc/bodyweight_event.dart';
import '../bloc/bodyweight_state.dart';

/// Opens the standalone "Log body weight" sheet (required = false variant).
///
/// Ports `../openGym/frontend/src/sheets.jsx` BwSheet lines 200-257.
Future<void> showBwSheet(BuildContext context) {
  return showAppSheet<void>(
    context,
    (BuildContext ctx) => const _BwSheet(),
  );
}

class _BwSheet extends StatefulWidget {
  const _BwSheet();

  @override
  State<_BwSheet> createState() => _BwSheetState();
}

class _BwSheetState extends State<_BwSheet> {
  late num _value;

  @override
  void initState() {
    super.initState();
    final GymState state = context.read<GymStateCubit>().state;
    final BodyweightEntry? bw = context.read<JsEngineService>().history.lastBW(state);
    _value = bw?.w ?? 70;
  }

  void _save() {
    context.read<BodyweightBloc>().add(BodyweightLogged(_value));
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final GymState gymState = context.watch<GymStateCubit>().state;
    final String unit = gymState.unit ?? 'kg';
    final List<BodyweightEntry> recent =
        (gymState.bodyweight ?? const <BodyweightEntry>[]).reversed.take(3).toList();

    return BlocListener<BodyweightBloc, BodyweightState>(
      listener: (BuildContext context, BodyweightState state) {
        switch (state.signal) {
          case BodyweightSaved():
            Navigator.of(context).pop();
            showToast(context, t('Weight saved'));
          case BodyweightInvalid():
            showToast(context, t('Enter a valid weight'));
          case BodyweightGoalSaved():
          case BodyweightGoalCleared():
          case null:
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            t('Log body weight'),
            style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4.0),
          Text(
            '${t('Today')}, ${fmtDate(todayIso(), long: true)}',
            style: TextStyle(
              fontSize: 13.0,
              color: palette.muted,
            ),
          ),
          const SizedBox(height: 16.0),
          WeightInput(
            value: _value,
            unit: unit,
            onChanged: (num v) => setState(() => _value = v),
          ),
          const SizedBox(height: 14.0),
          AppButton(
            label: Text(t('Save')),
            variant: AppButtonVariant.primary,
            onPressed: _save,
          ),
          if (recent.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16.0),
            Text(
              t('Recent weigh-ins'),
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w600,
                color: palette.muted,
              ),
            ),
            const SizedBox(height: 8.0),
            Column(
              children: recent.map((BodyweightEntry b) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 9.0, horizontal: 2.0),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: palette.sep, width: 1.0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        fmtDate(b.d ?? '', long: true),
                        style: TextStyle(fontSize: 13.0, color: palette.muted),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            '${fmtNum(b.w ?? 0)} $unit',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 12.0),
                          IconButton(
                            icon: AppIcon('trash', size: 15.0, color: palette.red),
                            tooltip: 'delete',
                            onPressed: () {
                              if (b.d != null) {
                                context.read<BodyweightBloc>().add(BodyweightEntryDeleted(b.d!));
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
