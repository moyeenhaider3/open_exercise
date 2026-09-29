// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../../core/models/state_parts.dart';

/// Reorders a gym card from index [from] to index [to].
///
/// Ported from `../openGym/frontend/src/views/CheckIn.jsx`:19-27.
List<GymCard> moveGymCard(List<GymCard> cards, int from, int to) {
  final List<GymCard> next = List<GymCard>.from(cards);
  if (from < 0 || from >= next.length) return next;
  final int target = to.clamp(0, next.length - 1);
  if (target == from) return next;
  final GymCard item = next.removeAt(from);
  next.insert(target, item);
  return next;
}
