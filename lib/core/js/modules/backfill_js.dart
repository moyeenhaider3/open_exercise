// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../models/gym_state.dart';
import '../../models/workout.dart';
import '../js_codec.dart';
import '../js_engine_service.dart';

/// Facade for openGym `backfill.js` helpers.
final class BackfillJs {
  const BackfillJs(this._engine);

  final JsEngineService _engine;

  /// Returns workouts on given ISO date string.
  /// Mirrors openGym `backfill.js` lines 5: `workoutsOn(S, iso)`.
  List<Workout> workoutsOn(GymState s, String iso) {
    final Object? res = _engine.call('backfill.workoutsOn', <Object?>[s.toJson(), iso]);
    final List<Object?> list = jsList(res, 'backfill.workoutsOn');
    return list.whereType<Map<String, Object?>>().map(Workout.fromJson).toList();
  }

  /// Calculates epoch ms for given ISO date at time (default '18:00').
  /// Mirrors openGym `backfill.js` lines 9-14: `backfillStart(iso, time = '18:00')`.
  int backfillStart(String iso, [String? time]) {
    final Object? res = _engine.call('backfill.backfillStart', <Object?>[
      iso,
      time ?? jsUndefined,
    ]);
    return jsInt(res, 'backfill.backfillStart');
  }

  /// Calculates end epoch ms from active workout start and backfill duration.
  /// Mirrors openGym `backfill.js` line 17: `backfillEnd(active)`.
  int backfillEnd(Workout active) {
    final Object? res = _engine.call('backfill.backfillEnd', <Object?>[active.toJson()]);
    return jsInt(res, 'backfill.backfillEnd');
  }

  /// Inserts workout into list in chronological order.
  /// Mirrors openGym `backfill.js` lines 21-30: `insertChronological(workouts, w)`.
  List<Workout> insertChronological(List<Workout> workouts, Workout w) {
    final Object? res = _engine.call('backfill.insertChronological', <Object?>[
      workouts.map((Workout x) => x.toJson()).toList(),
      w.toJson(),
    ]);
    final List<Object?> list = jsList(res, 'backfill.insertChronological');
    return list.whereType<Map<String, Object?>>().map(Workout.fromJson).toList();
  }

  /// Updates workouts list after backfilled session completion.
  /// Mirrors openGym `backfill.js` lines 34-38: `completeBackfill(workouts, active, w)`.
  List<Workout> completeBackfill(List<Workout> workouts, Workout active, Workout w) {
    final Object? res = _engine.call('backfill.completeBackfill', <Object?>[
      workouts.map((Workout x) => x.toJson()).toList(),
      active.toJson(),
      w.toJson(),
    ]);
    final List<Object?> list = jsList(res, 'backfill.completeBackfill');
    return list.whereType<Map<String, Object?>>().map(Workout.fromJson).toList();
  }
}

extension BackfillJsAccess on JsEngineService {
  BackfillJs get backfill => BackfillJs(this);
}
