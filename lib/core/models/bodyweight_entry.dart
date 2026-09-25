// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import 'json_passthrough.dart';

/// One logged body-weight reading -- date, weight and the timestamp it was logged at, one per
/// day (`../openGym/frontend/src/sheets.jsx` line 210; `../openGym/api/openapi.yaml`
/// BodyweightEntry schema). Passthrough-safe: unknown keys and wrong-typed/null values on `d`,
/// `w` or `t` survive in [extra].
class BodyweightEntry extends Equatable {
  const BodyweightEntry({this.d, this.w, this.t, this.extra = const <String, Object?>{}});

  final String? d;
  final num? w;
  final num? t;
  final Map<String, Object?> extra;

  static const Set<String> _known = <String>{'d', 'w', 't'};

  factory BodyweightEntry.fromJson(Map<String, Object?> json) {
    final JsonReader reader = JsonReader(json, known: _known);
    return BodyweightEntry(
      d: reader.string('d'),
      w: reader.number('w'),
      t: reader.number('t'),
      extra: reader.extra,
    );
  }

  Map<String, Object?> toJson() => emit(extra, <String, Object?>{'d': d, 'w': w, 't': t});

  @override
  List<Object?> get props => <Object?>[d, w, t, extra];
}
