// SPDX-License-Identifier: AGPL-3.0-or-later

/// Exact JSON deep comparator with ULP distance diagnostic for the parity harness.
///
/// This file is tool-only, is never imported from lib/, and is not a test.
library;

import 'dart:typed_data';

/// Represents a structural or numeric difference between expected and actual JSON values.
class ParityDiff {
  const ParityDiff({
    required this.path,
    required this.expected,
    required this.actual,
    this.ulpDistance,
    this.message,
  });

  final String path;
  final Object? expected;
  final Object? actual;
  final int? ulpDistance;
  final String? message;

  @override
  String toString() {
    final String ulpStr = ulpDistance != null ? ' (ulp: $ulpDistance)' : '';
    final String msgStr = message != null ? ' [$message]' : '';
    return 'ParityDiff(path: $path$msgStr, expected: $expected, actual: $actual$ulpStr)';
  }
}

/// Computes the Units in the Last Place (ULP) distance between two finite doubles.
///
/// Used exclusively for diagnostic logging when two values fail exact equality.
int? computeUlpDistance(double a, double b) {
  if (!a.isFinite || !b.isFinite) {
    return null;
  }
  final ByteData bdA = ByteData(8)..setFloat64(0, a);
  final ByteData bdB = ByteData(8)..setFloat64(0, b);
  final int bitsA = bdA.getInt64(0);
  final int bitsB = bdB.getInt64(0);

  final bool signA = bitsA < 0;
  final bool signB = bitsB < 0;

  if (signA == signB) {
    final int diff = bitsA - bitsB;
    return diff < 0 ? -diff : diff;
  } else {
    final int magA = bitsA & 0x7FFFFFFFFFFFFFFF;
    final int magB = bitsB & 0x7FFFFFFFFFFFFFFF;
    return magA + magB;
  }
}

/// Performs exact deep equality between [expected] and [actual] decoded JSON values.
///
/// Returns `null` if the structures are identical, or the first [ParityDiff] encountered.
///
/// Rules:
/// - Maps: equal key sets and recursive value equality. Absent key != key with null value.
/// - Lists: equal length and element-wise recursive equality.
/// - num: exact `==` (e.g. int 5 == double 5.0). No approximation or rounding distance is accepted.
///   On inequality of two finite doubles, computes ULP distance for diagnostic output.
/// - String / bool / null: exact `==`.
/// - Type mismatch: returns a diff.
ParityDiff? jsonDeepEqual(
  Object? expected,
  Object? actual, [
  String path = r'$',
]) {
  if (identical(expected, actual)) {
    return null;
  }

  if (expected is num && actual is num) {
    if (expected == actual) {
      return null;
    }
    final double expD = expected.toDouble();
    final double actD = actual.toDouble();
    final int? ulp = computeUlpDistance(expD, actD);
    return ParityDiff(
      path: path,
      expected: expected,
      actual: actual,
      ulpDistance: ulp,
    );
  }

  if (expected is Map && actual is Map) {
    final Set<Object?> expectedKeys = expected.keys.toSet();
    final Set<Object?> actualKeys = actual.keys.toSet();
    if (expectedKeys.length != actualKeys.length ||
        !expectedKeys.containsAll(actualKeys)) {
      final Set<Object?> missing = expectedKeys.difference(actualKeys);
      final Set<Object?> extra = actualKeys.difference(expectedKeys);
      return ParityDiff(
        path: path,
        expected: expectedKeys.toList(),
        actual: actualKeys.toList(),
        message: 'Key mismatch: missing $missing, extra $extra',
      );
    }
    for (final Object? key in expectedKeys) {
      final ParityDiff? diff = jsonDeepEqual(
        expected[key],
        actual[key],
        '$path["$key"]',
      );
      if (diff != null) {
        return diff;
      }
    }
    return null;
  }

  if (expected is List && actual is List) {
    if (expected.length != actual.length) {
      return ParityDiff(
        path: path,
        expected: expected.length,
        actual: actual.length,
        message:
            'List length mismatch: expected ${expected.length}, got ${actual.length}',
      );
    }
    for (int i = 0; i < expected.length; i++) {
      final ParityDiff? diff = jsonDeepEqual(
        expected[i],
        actual[i],
        '$path[$i]',
      );
      if (diff != null) {
        return diff;
      }
    }
    return null;
  }

  if (expected is String && actual is String) {
    if (expected == actual) {
      return null;
    }
    return ParityDiff(path: path, expected: expected, actual: actual);
  }

  if (expected is bool && actual is bool) {
    if (expected == actual) {
      return null;
    }
    return ParityDiff(path: path, expected: expected, actual: actual);
  }

  if (expected == null || actual == null) {
    if (expected == actual) {
      return null;
    }
    return ParityDiff(path: path, expected: expected, actual: actual);
  }

  if (expected != actual) {
    return ParityDiff(
      path: path,
      expected: expected,
      actual: actual,
      message:
          'Type or value mismatch: ${expected.runtimeType} vs ${actual.runtimeType}',
    );
  }

  return null;
}
