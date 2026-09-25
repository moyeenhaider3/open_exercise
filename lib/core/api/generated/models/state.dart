// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'bodyweight_entry.dart';
import 'routine.dart';
import 'state_effort_effort.dart';
import 'state_reminder.dart';
import 'state_unit_unit.dart';
import 'workout.dart';

part 'state.g.dart';

/// The whole app state as one blob. The server treats it as opaque (it only.
/// strips `active` on save and reads a few fields for reminders and the admin.
/// dashboard) — the schema below is **representative, not enforced** (except.
/// `workouts` and `routines`, which must be arrays (or null) when present), and grows.
/// with the app. Concurrent writes are caught by the server's revision (`_rev`,.
/// see PUT /api/data); the client merges the two documents and decides by `_ts`.
/// which side's settings win.
///
@JsonSerializable()
class State {
  const State({
    this.privateTs,
    this.privateRev,
    this.unit,
    this.lang,
    this.theme,
    this.accent,
    this.workouts,
    this.routines,
    this.week,
    this.dayPlan,
    this.bodyweight,
    this.customEx,
    this.exWeights,
    this.reminder,
    this.restSec,
    this.effort,
    this.equipProfiles,
    this.settings,
  });

  factory State.fromJson(Map<String, Object?> json) => _$StateFromJson(json);

  /// Client-set last-write timestamp (ms since epoch); drives sync.
  @JsonKey(name: '_ts')
  final num? privateTs;

  /// Server-set revision, incremented on every accepted PUT. Ignored when sent by a client.
  @JsonKey(name: '_rev')
  final int? privateRev;
  final StateUnitUnit? unit;

  /// UI language code ("en", "de", "pt", …) — also localizes pushes.
  final String? lang;
  final String? theme;
  final String? accent;

  /// Completed workouts, chronological.
  final List<Workout>? workouts;
  final List<Routine>? routines;

  /// Weekly plan: weekday (0=Sunday … 6) → routine id.
  final Map<String, String>? week;

  /// Per-date overrides: ISO date → routine id, or "rest". Wins over `week`.
  final Map<String, String>? dayPlan;
  final List<BodyweightEntry>? bodyweight;

  /// User-created exercises (id, name, muscles…).
  final List<dynamic>? customEx;

  /// Per-exercise last/best weight memory: exercise id → {w, d}.
  final Map<String, dynamic>? exWeights;

  /// Daily "workout planned today" push. The server reads this: at `time` (HH:MM, in `tz`) it sends one push if a routine is planned and nothing was logged yet.
  final StateReminder? reminder;

  /// Default rest-timer seconds.
  final num? restSec;
  final StateEffortEffort? effort;
  final List<dynamic>? equipProfiles;

  /// Catch-all note: the remaining top-level keys (sound, keepAwake, gifSize, targetW, autoBackup, …) are flat settings values like the ones above.
  final dynamic settings;

  Map<String, Object?> toJson() => _$StateToJson(this);
}
