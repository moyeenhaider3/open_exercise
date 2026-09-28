// SPDX-License-Identifier: AGPL-3.0-or-later

import '../models/gym_state.dart';
import 'exercise_def.dart';

/// Favourite exercises: a personal shortlist that floats to the top of the picker,
/// the Library and the muscle explorer so building a routine takes fewer scrolls.
/// Ported from ../openGym/frontend/src/lib/favourites.js

/// List of favourite exercise IDs, or empty list if none set.
List<String> favIds(GymState? s) => s?.favEx ?? const <String>[];

/// Whether the given exercise ID is marked as favourite.
bool isFav(GymState? s, String id) => favIds(s).contains(id);

/// Flip one exercise in state. Returns a tuple with the updated state and whether
/// it is a favourite afterwards.
(GymState next, bool on) toggleFav(GymState s, String id) {
  final List<String> list = favIds(s);
  final bool on = !list.contains(id);
  final List<String> nextList =
      on ? <String>[...list, id] : list.where((String x) => x != id).toList();
  return (s.copyWith(favEx: nextList), on);
}

/// Favourites first, everything else after — both halves keep their original order.
List<ExerciseDef> sortFavouritesFirst(List<ExerciseDef> list, GymState? s) {
  final List<String> fav = favIds(s);
  if (fav.isEmpty) return list;
  final Set<String> set = fav.toSet();
  return <ExerciseDef>[
    ...list.where((ExerciseDef e) => set.contains(e.id)),
    ...list.where((ExerciseDef e) => !set.contains(e.id)),
  ];
}
