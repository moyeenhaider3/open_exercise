// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

import '../models/state_parts.dart';

/// Exercise definition from openGym's catalogue or user-created custom exercise.
class ExerciseDef extends Equatable {
  const ExerciseDef({
    required this.id,
    required this.n,
    required this.bp,
    required this.eq,
    this.tg,
    this.mg,
    this.sm,
    this.st,
    this.img,
    this.gif,
    this.desc,
    this.primaries,
    this.secondaries,
    this.custom = false,
    this.assisted = false,
    this.missing = false,
    this.extra = const <String, Object?>{},
  });

  /// Exercise unique identifier (e.g. '0001' or 'c_...').
  final String id;

  /// English exercise name.
  final String n;

  /// Body part category ('chest', 'back', 'legs', etc.).
  final String bp;

  /// Equipment required ('barbell', 'dumbbell', 'body weight', etc.).
  final String eq;

  /// Target / primary muscle (e.g. 'pectorals').
  final String? tg;

  /// Muscle groups.
  final List<String>? mg;

  /// Secondary muscles.
  final List<String>? sm;

  /// Instruction steps.
  final List<String>? st;

  /// Thumbnail image relative filename.
  final String? img;

  /// Animation video relative filename.
  final String? gif;

  /// Description / notes.
  final String? desc;

  /// Primary muscle names.
  final List<String>? primaries;

  /// Secondary muscle names.
  final List<String>? secondaries;

  /// True if this is a user-created custom exercise.
  final bool custom;

  /// True if this is an assisted exercise (e.g. assisted pull-up).
  final bool assisted;

  /// True if this is an unknown/placeholder exercise.
  final bool missing;

  /// Passthrough for additional metadata.
  final Map<String, Object?> extra;

  static List<String>? _toStringList(Object? val) {
    if (val is List) {
      return val.map((dynamic e) => e.toString()).toList();
    }
    return null;
  }

  factory ExerciseDef.fromJson(Map<String, Object?> json) {
    final Map<String, Object?> extra = Map<String, Object?>.from(json);
    final String id = json['id']?.toString() ?? '';
    final String n = json['n']?.toString() ?? '';
    final String bp = json['bp']?.toString() ?? '';
    final String eq = json['eq']?.toString() ?? '';
    final String? tg = json['tg']?.toString();
    final String? img = json['img']?.toString();
    final String? gif = json['gif']?.toString();
    final String? desc = json['desc']?.toString();

    final List<String>? mg = _toStringList(json['mg']);
    final List<String>? sm = _toStringList(json['sm']);
    final List<String>? st = _toStringList(json['st']);
    final List<String>? primaries = _toStringList(json['primaries']);
    final List<String>? secondaries = _toStringList(json['secondaries']);

    final bool custom = json['custom'] == true;
    final bool assisted = json['assisted'] == true;
    final bool missing = json['missing'] == true;

    return ExerciseDef(
      id: id,
      n: n,
      bp: bp,
      eq: eq,
      tg: tg,
      mg: mg,
      sm: sm,
      st: st,
      img: img,
      gif: gif,
      desc: desc,
      primaries: primaries,
      secondaries: secondaries,
      custom: custom,
      assisted: assisted,
      missing: missing,
      extra: extra,
    );
  }

  factory ExerciseDef.fromCustom(CustomExercise custom) {
    final Map<String, Object?> extra = custom.extra;
    final String id = custom.id ?? '';
    final String name = (extra['n'] as String?) ?? custom.name ?? '';
    final String bp = (extra['bp'] as String?) ?? 'other';
    final String eq = (extra['eq'] as String?) ?? 'none';
    final String? tg = extra['tg'] as String?;
    final String? desc = extra['desc'] as String?;

    final List<String>? sm = _toStringList(extra['sm']);
    final List<String>? st = _toStringList(extra['st']);
    final List<String>? primaries = _toStringList(extra['primaries']);
    final List<String>? secondaries = _toStringList(extra['secondaries']);
    final List<String>? mg =
        _toStringList(extra['mg'] ?? extra['muscleGroups']);

    final bool assisted = extra['assisted'] == true;

    return ExerciseDef(
      id: id,
      n: name,
      bp: bp,
      eq: eq,
      tg: tg,
      mg: mg,
      sm: sm,
      st: st,
      desc: desc,
      primaries: primaries,
      secondaries: secondaries,
      custom: true,
      assisted: assisted,
      missing: false,
      extra: extra,
    );
  }

  Map<String, Object?> toJson() {
    final Map<String, Object?> map = <String, Object?>{
      ...extra,
      'id': id,
      'n': n,
      'bp': bp,
      'eq': eq,
    };
    if (tg != null) map['tg'] = tg;
    if (mg != null) map['mg'] = mg;
    if (sm != null) map['sm'] = sm;
    if (st != null) map['st'] = st;
    if (img != null) map['img'] = img;
    if (gif != null) map['gif'] = gif;
    if (desc != null) map['desc'] = desc;
    if (primaries != null) map['primaries'] = primaries;
    if (secondaries != null) map['secondaries'] = secondaries;
    if (custom) map['custom'] = true;
    if (assisted) map['assisted'] = true;
    if (missing) map['missing'] = true;
    return map;
  }

  ExerciseDef copyWith({
    String? id,
    String? n,
    String? bp,
    String? eq,
    String? tg,
    List<String>? mg,
    List<String>? sm,
    List<String>? st,
    String? img,
    String? gif,
    String? desc,
    List<String>? primaries,
    List<String>? secondaries,
    bool? custom,
    bool? assisted,
    bool? missing,
    Map<String, Object?>? extra,
  }) {
    return ExerciseDef(
      id: id ?? this.id,
      n: n ?? this.n,
      bp: bp ?? this.bp,
      eq: eq ?? this.eq,
      tg: tg ?? this.tg,
      mg: mg ?? this.mg,
      sm: sm ?? this.sm,
      st: st ?? this.st,
      img: img ?? this.img,
      gif: gif ?? this.gif,
      desc: desc ?? this.desc,
      primaries: primaries ?? this.primaries,
      secondaries: secondaries ?? this.secondaries,
      custom: custom ?? this.custom,
      assisted: assisted ?? this.assisted,
      missing: missing ?? this.missing,
      extra: extra ?? this.extra,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        n,
        bp,
        eq,
        tg,
        const ListEquality<String>().hash(mg),
        const ListEquality<String>().hash(sm),
        const ListEquality<String>().hash(st),
        img,
        gif,
        desc,
        const ListEquality<String>().hash(primaries),
        const ListEquality<String>().hash(secondaries),
        custom,
        assisted,
        missing,
      ];
}
