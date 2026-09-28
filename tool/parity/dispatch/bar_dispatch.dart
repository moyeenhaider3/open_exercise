// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:open_exercise/core/js/js_engine_service.dart';
import 'package:open_exercise/core/js/modules/bar_js.dart';
import 'package:open_exercise/core/models/gym_state.dart';

import '../parity_types.dart';

Map<String, ParityCall> barDispatch(JsEngineService engine) {
  final BarJs bar = engine.bar;

  return <String, ParityCall>{
    'bar.usesBar': (List<Object?> args) {
      final Object? exOrId = argAt(args, 0);
      return toPlainJson(bar.usesBar(exOrId));
    },
    'bar.defaultBarWeight': (List<Object?> args) {
      final String eq = argAt(args, 0) as String;
      final String unit = argAt(args, 1) as String;
      return toPlainJson(bar.defaultBarWeight(eq, unit));
    },
    'bar.isNoBar': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      final String exId = argAt(args, 1) as String;
      return toPlainJson(bar.isNoBar(s, exId));
    },
    'bar.hasBarOverride': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      final String exId = argAt(args, 1) as String;
      return toPlainJson(bar.hasBarOverride(s, exId));
    },
    'bar.barWeightFor': (List<Object?> args) {
      final GymState s = GymState.fromJson(jsonMapArg(args, 0));
      final Object? exOrId = argAt(args, 1);
      return toPlainJson(bar.barWeightFor(s, exOrId));
    },
    'bar.plateSplit': (List<Object?> args) {
      final num? total = argAt(args, 0) as num?;
      final num? barWeight = argAt(args, 1) as num?;
      return toPlainJson(bar.plateSplit(total, barWeight));
    },
  };
}
