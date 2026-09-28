// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import '../../models/json_passthrough.dart';
import '../js_codec.dart';

/// Options passed to recovery calculations (fatigueOf, strengthOf, etc.).
class RecoveryOptions extends Equatable implements JsonEncodable {
  const RecoveryOptions({
    this.unit,
    this.extra = const <String, Object?>{},
  });

  final String? unit;
  final Map<String, Object?> extra;

  static const Set<String> _known = <String>{'unit'};

  factory RecoveryOptions.fromJson(Map<String, Object?> json) {
    final JsonReader reader = JsonReader(json, known: _known);
    return RecoveryOptions(
      unit: reader.string('unit'),
      extra: reader.extra,
    );
  }

  @override
  Map<String, Object?> toJson() => emit(extra, <String, Object?>{
        'unit': unit,
      });

  @override
  List<Object?> get props => <Object?>[unit, extra];
}
