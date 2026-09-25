// SPDX-License-Identifier: AGPL-3.0-or-later

/// `DEF` ported 1:1 from `../openGym/frontend/src/store/useStore.js` lines 23-85, plus `wc`
/// expanded from `WC_DEFAULT` (`../openGym/frontend/src/lib/workout-controls.js`). Every key and
/// default value here must match the JS source exactly -- this is what a brand-new profile (or
/// any profile missing a key added after it was created) resolves to, byte-for-byte.
///
/// Kept as a plain `const Map` (not a `GymState`) so [overlayOnDefaults] can reproduce openGym's
/// own `loadState()`: `Object.assign(clone(DEF), loaded)` -- a shallow top-level overlay, not a
/// recursive merge. A loaded `reminder` (or any other object-valued key) replaces the default
/// wholesale; it is never merged field-by-field with DEF's version.
const Map<String, Object?> kDefaultState = <String, Object?>{
  // useStore.js line 24: unit, restSec, restPauseSec, sound, soundOnSilent, timerFlash,
  // keepAwake, lang.
  'unit': 'kg',
  'restSec': 90,
  'restPauseSec': 15,
  'sound': true,
  'soundOnSilent': false,
  'timerFlash': false,
  'keepAwake': true,
  'lang': 'en',
  // useStore.js line 25: theme ('dark'|'light'|'system'), accent, body, targetW (null until set).
  'theme': 'dark',
  'accent': 'lime',
  'body': 'male',
  'targetW': null,
  // useStore.js lines 26-27: bodyweight log, saved routines, weekly plan, per-date overrides.
  'bodyweight': <Object?>[],
  'routines': <Object?>[],
  'week': <String, Object?>{},
  'dayPlan': <String, Object?>{},
  // useStore.js lines 28-29: per-exercise weight memory, completed workouts, the in-progress
  // workout (null when none running), user-created exercises, media size preference.
  'exWeights': <String, Object?>{},
  'workouts': <Object?>[],
  'active': null,
  'customEx': <Object?>[],
  'gifSize': 'full',
  // useStore.js lines 30-36: how the active-workout screen is laid out. Purely presentational --
  // a profile saved before this setting existed overlays onto DEF and keeps 'cards'.
  'workoutView': 'cards',
  // useStore.js line 42: which optional control groups the workout screen shows besides the
  // sets themselves (workout-controls.js WC_DEFAULT, expanded key by key).
  'wc': <String, Object?>{
    'steppers': true,
    'setShortcuts': false,
    'pairButtons': false,
    'exerciseButtons': false,
  },
  // useStore.js lines 43-47: daily reminder (tz null until the user picks one -- kept as an
  // explicit null, never dropped), effort scale (null, not 'none', so an unset profile still
  // falls back to the legacy showRir boolean it replaced), auto-backup toggle.
  'reminder': <String, Object?>{'on': false, 'time': '08:00', 'tz': null},
  'effort': null,
  'autoBackup': false,
  // useStore.js lines 48-51: equipment profiles (filter Library/picker/routines by what you own).
  'equipProfiles': <Object?>[],
  'activeEquipId': null,
  'equipFilterOn': false,
  // useStore.js lines 52-55: standing per-exercise notes, keyed by exercise id.
  'exNotes': <String, Object?>{},
  // useStore.js lines 56-58: favourite exercise ids, sorted to the top of the picker/Library.
  'favEx': <Object?>[],
  // useStore.js lines 59-62: first day of the week as a getDay() index (1 = Monday).
  'weekStart': 1,
  // useStore.js lines 63-65: decimals on displayed weights (display only).
  'wdec': 1,
  // useStore.js lines 66-69: per-exercise bar weight overrides, keyed by exercise id.
  'barWeights': <String, Object?>{},
  // useStore.js lines 70-77: gym check-in cards ([{ id, label, value, fmt }]).
  'gymCards': <Object?>[],
  // useStore.js lines 78-81: the check-in card last settled on (null before any card exists).
  'lastGymCardId': null,
  // useStore.js lines 82-84: check-in feature on/off. Defaults on; an older profile without the
  // key reads as on (`!== false`).
  'checkIn': true,
  // useStore.js lines 85-87: whether Start opens the quick weigh-in first. Defaults on; an older
  // profile without the key reads as on (`!== false`).
  'weighIn': true,
};

Object? _deepClone(Object? value) {
  if (value case final Map<String, Object?> map) {
    return _deepCloneMap(map);
  }
  if (value case final List<Object?> list) {
    return list.map(_deepClone).toList();
  }
  return value;
}

Map<String, Object?> _deepCloneMap(Map<String, Object?> map) =>
    <String, Object?>{for (final MapEntry<String, Object?> e in map.entries) e.key: _deepClone(e.value)};

/// `Object.assign(clone(DEF), loaded)` (`useStore.js` `loadState`): a deep copy of
/// [kDefaultState] with every one of `loaded`'s top-level keys assigned over it. This is a
/// shallow overlay -- a key present in `loaded` replaces the default value wholesale (arrays and
/// objects included); it is never merged field-by-field with the default.
Map<String, Object?> overlayOnDefaults(Map<String, Object?> loaded) {
  final Map<String, Object?> result = _deepCloneMap(kDefaultState);
  for (final MapEntry<String, Object?> entry in loaded.entries) {
    result[entry.key] = entry.value;
  }
  return result;
}
