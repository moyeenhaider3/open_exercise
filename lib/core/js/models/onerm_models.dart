// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import '../../models/json_passthrough.dart';
import '../js_codec.dart';

/// Best estimated 1RM result from one workout entry's completed sets.
class OnermBestSet extends Equatable implements JsonEncodable {
  const OnermBestSet({
    this.est,
    this.w,
    this.r,
    this.extra = const <String, Object?>{},
  });

  final double? est;
  final num? w;
  final num? r;
  final Map<String, Object?> extra;

  static const Set<String> _known = <String>{'est', 'w', 'r'};

  factory OnermBestSet.fromJson(Map<String, Object?> json) {
    final JsonReader reader = JsonReader(json, known: _known);
    return OnermBestSet(
      est: reader.number('est')?.toDouble(),
      w: reader.number('w'),
      r: reader.number('r'),
      extra: reader.extra,
    );
  }

  @override
  Map<String, Object?> toJson() => emit(extra, <String, Object?>{
        'est': est,
        'w': w,
        'r': r,
      });

  @override
  List<Object?> get props => <Object?>[est, w, r, extra];
}

/// One point in the chronological 1RM trend series for an exercise.
class E1rmPoint extends Equatable implements JsonEncodable {
  const E1rmPoint({
    this.t,
    this.d,
    this.y,
    this.w,
    this.r,
    this.extra = const <String, Object?>{},
  });

  final num? t;
  final String? d;
  final double? y;
  final num? w;
  final num? r;
  final Map<String, Object?> extra;

  static const Set<String> _known = <String>{'t', 'd', 'y', 'w', 'r'};

  factory E1rmPoint.fromJson(Map<String, Object?> json) {
    final JsonReader reader = JsonReader(json, known: _known);
    return E1rmPoint(
      t: reader.number('t'),
      d: reader.string('d'),
      y: reader.number('y')?.toDouble(),
      w: reader.number('w'),
      r: reader.number('r'),
      extra: reader.extra,
    );
  }

  @override
  Map<String, Object?> toJson() => emit(extra, <String, Object?>{
        't': t,
        'd': d,
        'y': y,
        'w': w,
        'r': r,
      });

  @override
  List<Object?> get props => <Object?>[t, d, y, w, r, extra];
}

/// All-time best 1RM estimate for an exercise.
class OnermBest extends Equatable implements JsonEncodable {
  const OnermBest({
    this.est,
    this.w,
    this.r,
    this.d,
    this.t,
    this.extra = const <String, Object?>{},
  });

  final double? est;
  final num? w;
  final num? r;
  final String? d;
  final num? t;
  final Map<String, Object?> extra;

  static const Set<String> _known = <String>{'est', 'w', 'r', 'd', 't'};

  factory OnermBest.fromJson(Map<String, Object?> json) {
    final JsonReader reader = JsonReader(json, known: _known);
    return OnermBest(
      est: reader.number('est')?.toDouble(),
      w: reader.number('w'),
      r: reader.number('r'),
      d: reader.string('d'),
      t: reader.number('t'),
      extra: reader.extra,
    );
  }

  @override
  Map<String, Object?> toJson() => emit(extra, <String, Object?>{
        'est': est,
        'w': w,
        'r': r,
        'd': d,
        't': t,
      });

  @override
  List<Object?> get props => <Object?>[est, w, r, d, t, extra];
}

/// 1RM record notification model when an entry sets a new personal record.
class OnermRecord extends Equatable implements JsonEncodable {
  const OnermRecord({
    this.est,
    this.w,
    this.r,
    this.prev,
    this.extra = const <String, Object?>{},
  });

  final double? est;
  final num? w;
  final num? r;
  final double? prev;
  final Map<String, Object?> extra;

  static const Set<String> _known = <String>{'est', 'w', 'r', 'prev'};

  factory OnermRecord.fromJson(Map<String, Object?> json) {
    final JsonReader reader = JsonReader(json, known: _known);
    return OnermRecord(
      est: reader.number('est')?.toDouble(),
      w: reader.number('w'),
      r: reader.number('r'),
      prev: reader.number('prev')?.toDouble(),
      extra: reader.extra,
    );
  }

  @override
  Map<String, Object?> toJson() => emit(extra, <String, Object?>{
        'est': est,
        'w': w,
        'r': r,
        'prev': prev,
      });

  @override
  List<Object?> get props => <Object?>[est, w, r, prev, extra];
}
