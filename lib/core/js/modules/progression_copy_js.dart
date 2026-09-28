// SPDX-License-Identifier: AGPL-3.0-or-later

import '../js_codec.dart';
import '../js_engine_service.dart';
import '../models/progression_models.dart';

/// Facade for openGym `progression-copy.js` guidance copy.
final class ProgressionCopyJs {
  const ProgressionCopyJs(this._engine);

  final JsEngineService _engine;

  ({String policyLabel, Object? why})? progressionGuidance(Prescription? plan) {
    if (plan == null) return null;
    final Object? res = _engine.call('progressionCopy.progressionGuidance', <Object?>[plan.toJson()]);
    final Map<String, Object?>? map = jsMapOrNull(res, 'progressionCopy.progressionGuidance');
    if (map == null) return null;
    return (
      policyLabel: jsString(map['policyLabel'], 'progressionCopy.progressionGuidance.policyLabel'),
      why: map['why'],
    );
  }
}

extension ProgressionCopyJsAccess on JsEngineService {
  ProgressionCopyJs get progressionCopy => ProgressionCopyJs(this);
}
