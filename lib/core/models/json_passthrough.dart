// SPDX-License-Identifier: AGPL-3.0-or-later

/// Known-fields-plus-extra JSON parsing helper shared by every hand-authored state model
/// (Workout, WorkoutEntry, SetEntry, and the models Plans 01-04/01-06 add on top of them).
///
/// openGym's `openapi.yaml` declares the State/Workout/Routine shapes "representative, not
/// enforced" with `additionalProperties: true` everywhere. Every model built on [JsonReader]
/// must therefore retain any key it doesn't explicitly know about -- and any value of an
/// unexpected type or an explicit null on a known key -- unchanged, so `toJson()` round-trips
/// to a map deep-equal to any input map, known or not.
///
/// The round-trip is deep-equal, NOT byte-for-byte: [emit] writes `extra` keys first and then
/// typed keys in declaration order (so the original key order is not preserved), and Dart's
/// `jsonEncode` writes a double such as `60.0` where JavaScript writes `60`. Never compare
/// serialized strings (hashes, backup diffs, "changed since last push" checks) -- compare decoded
/// values instead.
library;

/// Reads typed fields out of a raw JSON map, routing anything unexpected (unknown keys, nulls
/// on known keys, wrong-typed values) into [extra] instead of throwing or silently dropping it.
///
/// Rule for every typed read: key absent -> null and nothing added to [extra]; key present with
/// the expected type -> the typed value; key present with null or another type -> null returned
/// and the original value copied into [extra] under the same key.
class JsonReader {
  JsonReader(Map<String, Object?> source, {Set<String> known = const <String>{}})
      : _source = source,
        _extra = <String, Object?>{} {
    for (final MapEntry<String, Object?> entry in source.entries) {
      if (!known.contains(entry.key)) {
        _extra[entry.key] = entry.value;
      }
    }
  }

  final Map<String, Object?> _source;
  final Map<String, Object?> _extra;

  /// Every key not read as a typed field: unknown keys, plus known keys whose value was null or
  /// of an unexpected type.
  Map<String, Object?> get extra => Map<String, Object?>.unmodifiable(_extra);

  bool _has(String key) => _source.containsKey(key);

  void _demote(String key) {
    _extra[key] = _source[key];
  }

  String? string(String key) {
    if (!_has(key)) return null;
    final Object? value = _source[key];
    if (value case final String s) return s;
    _demote(key);
    return null;
  }

  /// Integers only. A double with no fractional part (e.g. `8.0`) is NOT coerced -- it stays in
  /// [extra] unchanged, because the source JSON explicitly chose a non-integer numeric literal.
  int? integer(String key) {
    if (!_has(key)) return null;
    final Object? value = _source[key];
    if (value case final int i) return i;
    _demote(key);
    return null;
  }

  num? number(String key) {
    if (!_has(key)) return null;
    final Object? value = _source[key];
    if (value case final num n) return n;
    _demote(key);
    return null;
  }

  bool? boolean(String key) {
    if (!_has(key)) return null;
    final Object? value = _source[key];
    if (value case final bool b) return b;
    _demote(key);
    return null;
  }

  Map<String, Object?>? map(String key) {
    if (!_has(key)) return null;
    final Object? value = _source[key];
    if (value case final Map<String, Object?> m) return m;
    _demote(key);
    return null;
  }

  List<Object?>? list(String key) {
    if (!_has(key)) return null;
    final Object? value = _source[key];
    if (value case final List<Object?> l) return l;
    _demote(key);
    return null;
  }

  /// Returns a typed list only if every element is a `String`; otherwise the whole value
  /// (unparsed) goes to [extra].
  List<String>? stringList(String key) {
    if (!_has(key)) return null;
    final Object? value = _source[key];
    if (value case final List<Object?> items) {
      final List<String> strings = <String>[];
      for (final Object? item in items) {
        if (item case final String s) {
          strings.add(s);
        } else {
          _demote(key);
          return null;
        }
      }
      return strings;
    }
    _demote(key);
    return null;
  }

  /// Returns a typed list only if every element is a `Map<String, Object?>`; otherwise the whole
  /// value (unparsed) goes to [extra].
  List<T>? objectList<T>(String key, T Function(Map<String, Object?>) parse) {
    if (!_has(key)) return null;
    final Object? value = _source[key];
    if (value case final List<Object?> items) {
      final List<Map<String, Object?>> maps = <Map<String, Object?>>[];
      for (final Object? item in items) {
        if (item case final Map<String, Object?> m) {
          maps.add(m);
        } else {
          _demote(key);
          return null;
        }
      }
      return maps.map(parse).toList();
    }
    _demote(key);
    return null;
  }
}

/// Merges [extra] (unknown keys plus known keys that were null/wrong-typed) with [typed] (known
/// fields as a plain map), dropping any null values from [typed] so an absent field doesn't
/// reappear as an explicit null. [extra]'s keys come first so a typed value can override them
/// when the same key legitimately round-trips through both (it never should in practice, since
/// a key is either known or not, but this keeps the merge order well-defined).
Map<String, Object?> emit(Map<String, Object?> extra, Map<String, Object?> typed) {
  final Map<String, Object?> result = <String, Object?>{...extra};
  for (final MapEntry<String, Object?> entry in typed.entries) {
    if (entry.value != null) {
      result[entry.key] = entry.value;
    }
  }
  return result;
}
