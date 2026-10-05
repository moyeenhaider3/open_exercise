// SPDX-License-Identifier: AGPL-3.0-or-later

/// Port of `../openGym/frontend/src/views/Settings.jsx` MobileReminderCard (542-570) plus a
/// local rest-alert row in place of PushCard's push switch (Claude's discretion per 05-CONTEXT:
/// permission prompts only from a Settings tap, openGym #239).
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/i18n/t.dart';
import '../../../../core/models/gym_state.dart';
import '../../../../core/models/state_parts.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui_kit/controls.dart';
import '../../../../core/ui_kit/rows.dart';
import '../../bloc/settings_bloc.dart';
import '../../bloc/settings_event.dart';
import '../../bloc/settings_state.dart';

/// Notifications settings section.
///
/// Contains:
///  (a) A rest-timer alerts row showing current permission state and allowing the user to grant.
///  (b) A workout-day reminder switch (MobileReminderCard from openGym Settings.jsx 542-570).
///  (c) A reminder time picker shown when reminder is on.
///
/// Permission prompts are only shown from user taps (T-05-21); background syncs are
/// non-interactive.
class NotificationsSection extends StatefulWidget {
  const NotificationsSection({super.key, required this.state});

  final GymState state;

  @override
  State<NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<NotificationsSection> {
  AppLifecycleListener? _lifecycleListener;

  @override
  void initState() {
    super.initState();
    // Request status immediately on mount and when foregrounded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SettingsBloc>().add(const SettingsNotificationStatusRequested());
      }
    });
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        if (mounted) {
          context.read<SettingsBloc>().add(const SettingsNotificationStatusRequested());
        }
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    super.dispose();
  }

  Future<void> _onReminderTimeTap(BuildContext context, String currentTime) async {
    final List<String> parts = currentTime.split(':');
    final int initialHour = parts.length == 2 ? (int.tryParse(parts[0]) ?? 8) : 8;
    final int initialMinute = parts.length == 2 ? (int.tryParse(parts[1]) ?? 0) : 0;

    final SettingsBloc bloc = context.read<SettingsBloc>();

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
    );
    if (picked == null) return;
    // Zero-padded HH:mm
    final String formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    if (!mounted) return;
    bloc.add(SettingsReminderTimeChanged(formatted));
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Reminder? reminder = widget.state.reminder;
    final bool reminderOn = reminder?.on == true;
    final String reminderTime = reminder?.time ?? '08:00';

    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (SettingsState prev, SettingsState cur) =>
          prev.notificationsAllowed != cur.notificationsAllowed ||
          prev.exactAlarmsAllowed != cur.exactAlarmsAllowed,
      builder: (BuildContext context, SettingsState settingsState) {
        final bool? notifAllowed = settingsState.notificationsAllowed;
        final bool? exactAllowed = settingsState.exactAlarmsAllowed;

        // Determine rest-alerts subtitle and tappability
        final bool restFullyAllowed =
            notifAllowed == true && (kIsWeb || !Platform.isAndroid || exactAllowed == true);
        final bool restTappable = !restFullyAllowed;

        String restSubtitle;
        if (notifAllowed == true && exactAllowed == false && !kIsWeb && Platform.isAndroid) {
          restSubtitle = t('Alerts can arrive a little late. Tap to allow exact alarms.');
        } else if (notifAllowed == true && restFullyAllowed) {
          restSubtitle = t('Rest-timer alerts, even if openGym is closed.');
        } else {
          restSubtitle = t('Tap to allow notifications.');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SectionHeader(t('Notifications')),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  // (a) Rest-timer alerts row
                  AppRow(
                    icon: 'bell',
                    title: Text(t('Rest-timer alerts')),
                    subtitle: Text(restSubtitle),
                    accessory: restTappable ? AppRowAccessory.chevron : AppRowAccessory.none,
                    value: restFullyAllowed
                        ? Icon(Icons.check, size: 18.0, color: palette.acc)
                        : null,
                    onTap: restTappable
                        ? () => context
                            .read<SettingsBloc>()
                            .add(const SettingsRestAlertsRequested())
                        : null,
                  ),
                  const Divider(height: 1.0),
                  // (b) Workout day reminder switch
                  AppRow(
                    icon: 'calendar',
                    title: Text(t('Workout day reminder')),
                    child: AppSwitch(
                      value: reminderOn,
                      onChanged: (_) {
                        context.read<SettingsBloc>().add(const SettingsReminderToggled());
                      },
                    ),
                  ),
                  // (c) Reminder time — only when reminder is on
                  if (reminderOn) ...<Widget>[
                    const Divider(height: 1.0),
                    AppRow(
                      icon: 'clock',
                      title: Text(t('Reminder time')),
                      value: Text(
                        reminderTime,
                        style: TextStyle(fontSize: 15.0, color: palette.muted),
                      ),
                      accessory: AppRowAccessory.chevron,
                      onTap: () => _onReminderTimeTap(context, reminderTime),
                    ),
                  ],
                ],
              ),
            ),
            // Footer shown when reminder is on
            if (reminderOn)
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 6.0, 16.0, 14.0),
                child: Text(
                  t('Reminds you at this time on days that have a routine planned.'),
                  style: TextStyle(fontSize: 13.0, color: palette.muted),
                ),
              ),
          ],
        );
      },
    );
  }
}
