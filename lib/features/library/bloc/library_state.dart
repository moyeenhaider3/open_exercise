// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:equatable/equatable.dart';

import '../../../core/catalogue/exercise_def.dart';
import '../../../core/models/state_parts.dart';

/// Presentation state for the Library view.
/// Mirrors `../openGym/frontend/src/views/Library.jsx`.
class LibraryState extends Equatable {
  const LibraryState({
    this.query = '',
    this.bodyPart = '',
    this.equipment = '',
    this.showAll = false,
    this.shown = 40,
    this.results = const <ExerciseDef>[],
    this.eqOptions = const <String>[],
    this.eqOn = '',
    this.profile,
    this.bestWeights = const <String, double>{},
    this.favIds = const <String>{},
    this.total = 0,
  });

  /// Current search query string.
  final String query;

  /// Selected body part filter ('', 'chest', 'back', etc.).
  final String bodyPart;

  /// Selected equipment filter preference.
  final String equipment;

  /// Whether to ignore the active equipment profile and show all equipment.
  final bool showAll;

  /// Number of results to display (increments in steps of 40).
  final int shown;

  /// Full filtered and sorted exercise list.
  final List<ExerciseDef> results;

  /// Available equipment options derived from the current filtered exercise list.
  final List<String> eqOptions;

  /// Effective active equipment filter (fallback to '' if narrowed away).
  final String eqOn;

  /// The active equipment profile, or null if none active or filtering disabled.
  final EquipProfile? profile;

  /// Best weights achieved for the currently shown exercises.
  final Map<String, double> bestWeights;

  /// Set of favourite exercise IDs.
  final Set<String> favIds;

  /// Total count of exercises in the catalogue.
  final int total;

  LibraryState copyWith({
    String? query,
    String? bodyPart,
    String? equipment,
    bool? showAll,
    int? shown,
    List<ExerciseDef>? results,
    List<String>? eqOptions,
    String? eqOn,
    EquipProfile? Function()? profile,
    Map<String, double>? bestWeights,
    Set<String>? favIds,
    int? total,
  }) {
    return LibraryState(
      query: query ?? this.query,
      bodyPart: bodyPart ?? this.bodyPart,
      equipment: equipment ?? this.equipment,
      showAll: showAll ?? this.showAll,
      shown: shown ?? this.shown,
      results: results ?? this.results,
      eqOptions: eqOptions ?? this.eqOptions,
      eqOn: eqOn ?? this.eqOn,
      profile: profile != null ? profile() : this.profile,
      bestWeights: bestWeights ?? this.bestWeights,
      favIds: favIds ?? this.favIds,
      total: total ?? this.total,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        query,
        bodyPart,
        equipment,
        showAll,
        shown,
        results,
        eqOptions,
        eqOn,
        profile,
        bestWeights,
        favIds,
        total,
      ];
}
