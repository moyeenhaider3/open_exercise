// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';

import 'package:flutter/services.dart';

import '../i18n/t.dart';
import '../models/gym_state.dart';
import '../models/state_parts.dart';
import 'exercise_def.dart';

/// Pinned CDN commit SHA from openGym package.json build:mobile script.
const String kExercisesDatasetCommit =
    '7455efae41b330c265e7cd4b78dfa848e7ce5ebd';

/// Base URL for exercise thumbnail images hosted on jsDelivr CDN.
const String kMediaImgBase =
    'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@$kExercisesDatasetCommit/images/';

/// Base URL for exercise animation videos/GIFs hosted on jsDelivr CDN.
const String kMediaGifBase =
    'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@$kExercisesDatasetCommit/videos/';

/// openGym exercise catalogue loaded from pre-generated JSON asset.
final class ExerciseCatalogue {
  ExerciseCatalogue._({
    required this._catalogue,
    required this._index,
    required this._bodyParts,
    required this._muscleName,
    required this._allEquipment,
    required this._secondaryAdditions,
  });

  final List<ExerciseDef> _catalogue;
  final Map<String, ExerciseDef> _index;
  final List<String> _bodyParts;
  final Map<String, String> _muscleName;
  final List<String> _allEquipment;
  final Map<String, List<String>> _secondaryAdditions;

  /// Loads the catalogue synchronously from bundled JSON asset.
  static Future<ExerciseCatalogue> load(AssetBundle bundle) async {
    final String raw =
        await bundle.loadString('assets/data/exercise_catalogue.json');
    final Map<String, Object?> json =
        jsonDecode(raw) as Map<String, Object?>;

    final List<Object?> rawList = json['catalogue'] as List<Object?>;
    final List<ExerciseDef> catalogue = <ExerciseDef>[];
    final Map<String, ExerciseDef> index = <String, ExerciseDef>{};

    for (final Object? item in rawList) {
      if (item is Map<String, Object?>) {
        final ExerciseDef def = ExerciseDef.fromJson(item);
        catalogue.add(def);
        index[def.id] = def;
      }
    }

    final List<String> bodyParts =
        (json['bodyParts'] as List<Object?>).cast<String>();
    final Map<String, String> muscleName =
        (json['muscleName'] as Map<String, Object?>).cast<String, String>();
    final List<String> allEquipment =
        (json['allEquipment'] as List<Object?>).cast<String>();

    final Map<String, Object?> rawAdditions =
        json['secondaryAdditions'] as Map<String, Object?>;
    final Map<String, List<String>> secondaryAdditions =
        rawAdditions.map((String k, Object? v) {
      final List<String> list = (v as List<Object?>).cast<String>();
      return MapEntry<String, List<String>>(k, list);
    });

    return ExerciseCatalogue._(
      catalogue: List<ExerciseDef>.unmodifiable(catalogue),
      index: Map<String, ExerciseDef>.unmodifiable(index),
      bodyParts: List<String>.unmodifiable(bodyParts),
      muscleName: Map<String, String>.unmodifiable(muscleName),
      allEquipment: List<String>.unmodifiable(allEquipment),
      secondaryAdditions:
          Map<String, List<String>>.unmodifiable(secondaryAdditions),
    );
  }

  /// All 1,324 built-in catalogue exercises in dataset order.
  List<ExerciseDef> get catalogue => _catalogue;

  /// Canonical list of body parts.
  List<String> get bodyParts => _bodyParts;

  /// Map of muscle identifiers to display names.
  Map<String, String> get muscleName => _muscleName;

  /// All equipment types sorted by frequency in the catalogue.
  List<String> get allEquipment => _allEquipment;

  /// Looks up a built-in catalogue exercise by id.
  ExerciseDef? byId(String id) => _index[id];

  /// Merged list of custom exercises followed by all catalogue exercises.
  List<ExerciseDef> allExercises(GymState s) {
    final List<CustomExercise> custom =
        s.customEx ?? const <CustomExercise>[];
    if (custom.isEmpty) return _catalogue;
    final List<ExerciseDef> customDefs =
        custom.map(ExerciseDef.fromCustom).toList();
    return <ExerciseDef>[...customDefs, ..._catalogue];
  }

  /// Looks up an exercise by id in custom exercises and catalogue,
  /// falling back to an 'Unknown exercise' placeholder.
  ExerciseDef lookup(GymState s, String id) {
    if (s.customEx != null) {
      for (final CustomExercise c in s.customEx!) {
        if (c.id == id) {
          return ExerciseDef.fromCustom(c);
        }
      }
    }
    final ExerciseDef? builtin = _index[id];
    if (builtin != null) return builtin;

    return ExerciseDef(
      id: id,
      n: t('Unknown exercise'),
      bp: 'other',
      eq: 'none',
      missing: true,
    );
  }

  /// Returns unique equipment options from [list] sorted by frequency descending.
  List<String> equipmentOf(List<ExerciseDef> list) {
    final Map<String, int> counts = <String, int>{};
    for (final ExerciseDef e in list) {
      if (e.eq.isNotEmpty) {
        counts[e.eq] = (counts[e.eq] ?? 0) + 1;
      }
    }
    final List<String> keys = counts.keys.toList();
    keys.sort((String a, String b) {
      final int diff = counts[b]! - counts[a]!;
      if (diff != 0) return diff;
      return a.compareTo(b);
    });
    return keys;
  }

  /// Secondary muscles for an exercise with openGym's conservative additions overlay.
  List<String> smOf(ExerciseDef ex) {
    final List<String> base = ex.sm ?? const <String>[];
    final List<String>? additions = _secondaryAdditions[ex.id];
    if (additions == null || additions.isEmpty) return base;
    final Set<String> merged = <String>{...base, ...additions};
    return merged.toList();
  }

  /// Exercise display name in English.
  String exerciseNameFor(ExerciseDef ex) => ex.n;

  /// Absolute URL for thumbnail image on jsDelivr CDN.
  String? imgSrc(ExerciseDef ex) =>
      ex.img != null ? '$kMediaImgBase${ex.img}' : null;

  /// Absolute URL for animation GIF/video on jsDelivr CDN.
  String? gifSrc(ExerciseDef ex) =>
      ex.gif != null ? '$kMediaGifBase${ex.gif}' : null;
}
