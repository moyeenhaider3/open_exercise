// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:open_exercise/core/js/js_engine_service.dart';
import 'package:open_exercise/core/js/modules/session_js.dart';
import 'package:open_exercise/core/models/gym_state.dart';
import 'package:open_exercise/core/models/routine.dart';

import '../parity_types.dart';

Map<String, ParityCall> sessionStartDispatch(JsEngineService engine) {
  final SessionStartJs sessionStart = engine.sessionStart;

  return <String, ParityCall>{
    'sessionStart.buildSessionEntries': (List<Object?> args) {
      final GymState st = GymState.fromJson(jsonMapArg(args, 0));
      final Routine? r = hasArg(args, 1) && argAt(args, 1) != null
          ? Routine.fromJson(jsonMapArg(args, 1))
          : null;
      return toPlainJson(sessionStart.buildSessionEntries(st, r));
    },
  };
}

Map<String, ParityCall> sessionMergeDispatch(JsEngineService engine) {
  final SessionMergeJs sessionMerge = engine.sessionMerge;

  return <String, ParityCall>{
    'sessionMerge.buildCombinedEntries': (List<Object?> args) {
      final GymState st = GymState.fromJson(jsonMapArg(args, 0));
      final List<Object?> rawList = jsonListArg(args, 1);
      final List<String> routineIds = rawList.map((Object? item) => item as String).toList();
      return toPlainJson(sessionMerge.buildCombinedEntries(st, routineIds));
    },
    'sessionMerge.deriveSessionName': (List<Object?> args) {
      final List<Object?> rawList = jsonListArg(args, 0);
      final List<String> names = rawList.map((Object? item) => item as String).toList();
      return toPlainJson(sessionMerge.deriveSessionName(names));
    },
  };
}
