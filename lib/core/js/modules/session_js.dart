// SPDX-License-Identifier: AGPL-3.0-or-later

/// Typed Dart facade for openGym's `session-start.js` and `session-merge.js` modules.
///
/// Builds active session workout entries from single or combined routines.
library;

import '../../models/gym_state.dart';
import '../../models/routine.dart';
import '../../models/workout.dart';
import '../js_codec.dart';
import '../js_engine_service.dart';
import '../models/history_models.dart';

final class SessionStartJs {
  const SessionStartJs(this._engine);

  final JsEngineService _engine;

  /// Builds active session entries from a routine.
  List<WorkoutEntry> buildSessionEntries(GymState st, Routine? r) {
    final Object? result = _engine.call(
      'sessionStart.buildSessionEntries',
      <Object?>[st.toJson(), r?.toJson() ?? jsUndefined],
    );
    return jsListOf<WorkoutEntry>(result, 'sessionStart.buildSessionEntries', WorkoutEntry.fromJson);
  }
}

final class SessionMergeJs {
  const SessionMergeJs(this._engine);

  final JsEngineService _engine;

  /// Builds combined session entries from multiple routines in merge order.
  CombinedSession buildCombinedEntries(GymState st, List<String> routineIds) {
    final Object? result = _engine.call(
      'sessionMerge.buildCombinedEntries',
      <Object?>[st.toJson(), routineIds],
    );
    return CombinedSession.fromJson(jsMap(result, 'sessionMerge.buildCombinedEntries'));
  }

  /// Derives the display title for a combined workout session.
  String? deriveSessionName(List<String> names) {
    final Object? result = _engine.call(
      'sessionMerge.deriveSessionName',
      <Object?>[names],
    );
    return jsStringOrNull(result, 'sessionMerge.deriveSessionName');
  }
}

extension SessionStartJsAccess on JsEngineService {
  SessionStartJs get sessionStart => SessionStartJs(this);
}

extension SessionMergeJsAccess on JsEngineService {
  SessionMergeJs get sessionMerge => SessionMergeJs(this);
}
