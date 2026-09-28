// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:math';

import '../models/gym_state.dart';
import '../models/state_parts.dart';
import 'exercise_def.dart';

/// Equipment profile helpers and exercise availability filtering.
/// Ported from ../openGym/frontend/src/lib/equipment.js

/// Body weight is never gated by a profile — no gym or home setup can take it away,
/// and every profile should be able to see bodyweight exercises regardless of what is checked.
const String kAlwaysAvailableEquipment = 'body weight';

/// Returns the active equipment profile if equipment filtering is enabled, null otherwise.
EquipProfile? activeProfile(GymState s) {
  if (s.equipFilterOn != true) return null;
  final List<EquipProfile> profiles = s.equipProfiles ?? const <EquipProfile>[];
  for (final EquipProfile p in profiles) {
    if (p.id == s.activeEquipId) return p;
  }
  return null;
}

/// Whether an exercise is usable under the active profile.
/// With filtering off, or no profile selected, everything is available.
bool exAvailable(GymState s, ExerciseDef ex) {
  final EquipProfile? p = activeProfile(s);
  if (p == null) return true;
  if (ex.eq.isEmpty || ex.eq == kAlwaysAvailableEquipment) return true;
  final List<String> equipment = p.equipment ?? const <String>[];
  return equipment.contains(ex.eq);
}

/// Creates a new empty equipment profile with generated ID matching openGym ID shape.
EquipProfile newProfile(String name) {
  final String nowPart = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  final String randPart = (Random().nextDouble() * 1679616).toInt().toRadixString(36).padLeft(4, '0');
  return EquipProfile(
    id: 'eq$nowPart$randPart',
    name: name,
    equipment: const <String>[],
  );
}
