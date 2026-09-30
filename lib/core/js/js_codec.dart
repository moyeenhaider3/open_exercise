// SPDX-License-Identifier: AGPL-3.0-or-later

import 'js_bridge_exception.dart';

final class _JsUndefined {
  const _JsUndefined();

  @override
  String toString() => 'jsUndefined';
}

/// Sentinel object representing a JS `undefined` argument.
///
/// When passed to [JsEngineService.call], the corresponding parameter is omitted
/// or assigned `void 0` in JS so that default parameter expressions apply.
const Object jsUndefined = _JsUndefined();

/// Interface implemented by typed models that serialize to JSON.
abstract interface class JsonEncodable {
  Map<String, Object?> toJson();
}

/// Coerces a nullable value to a Dart [double], accepting any [num].
double? jsDoubleOrNull(Object? v, String path) {
  if (v == null) {
    return null;
  }
  if (v is num) {
    return v.toDouble();
  }
  throw JsBridgeException.type(
    path: path,
    message: 'Expected num or null, found ${v.runtimeType}: $v',
  );
}

/// Coerces a non-nullable value to a Dart [double], accepting any [num].
double jsDouble(Object? v, String path) {
  final double? res = jsDoubleOrNull(v, path);
  if (res == null) {
    throw JsBridgeException.type(
      path: path,
      message: 'Expected non-null double, found null',
    );
  }
  return res;
}

/// Coerces a nullable value to a Dart [int], accepting an [int] or an integral [num].
int? jsIntOrNull(Object? v, String path) {
  if (v == null) {
    return null;
  }
  if (v is int) {
    return v;
  }
  if (v is num) {
    if (v.truncateToDouble() == v.toDouble()) {
      return v.toInt();
    }
  }
  throw JsBridgeException.type(
    path: path,
    message: 'Expected integral num or null, found ${v.runtimeType}: $v',
  );
}

/// Coerces a non-nullable value to a Dart [int].
int jsInt(Object? v, String path) {
  final int? res = jsIntOrNull(v, path);
  if (res == null) {
    throw JsBridgeException.type(
      path: path,
      message: 'Expected non-null int, found null',
    );
  }
  return res;
}

/// Coerces a nullable value to a Dart [bool].
bool? jsBoolOrNull(Object? v, String path) {
  if (v == null) {
    return null;
  }
  if (v is bool) {
    return v;
  }
  throw JsBridgeException.type(
    path: path,
    message: 'Expected bool or null, found ${v.runtimeType}: $v',
  );
}

/// Coerces a non-nullable value to a Dart [bool].
bool jsBool(Object? v, String path) {
  final bool? res = jsBoolOrNull(v, path);
  if (res == null) {
    throw JsBridgeException.type(
      path: path,
      message: 'Expected non-null bool, found null',
    );
  }
  return res;
}

/// Coerces a nullable value to a Dart [String].
String? jsStringOrNull(Object? v, String path) {
  if (v == null) {
    return null;
  }
  if (v is String) {
    return v;
  }
  throw JsBridgeException.type(
    path: path,
    message: 'Expected String or null, found ${v.runtimeType}: $v',
  );
}

/// Coerces a non-nullable value to a Dart [String].
String jsString(Object? v, String path) {
  final String? res = jsStringOrNull(v, path);
  if (res == null) {
    throw JsBridgeException.type(
      path: path,
      message: 'Expected non-null String, found null',
    );
  }
  return res;
}

/// Coerces a nullable value to a Dart [Map<String, Object?>].
Map<String, Object?>? jsMapOrNull(Object? v, String path) {
  if (v == null) {
    return null;
  }
  if (v is Map) {
    final Map<String, Object?> result = <String, Object?>{};
    for (final MapEntry<Object?, Object?> entry in v.entries) {
      if (entry.key is! String) {
        throw JsBridgeException.type(
          path: path,
          message: 'Expected map key to be String, found ${entry.key.runtimeType}: ${entry.key}',
        );
      }
      result[entry.key as String] = entry.value;
    }
    return result;
  }
  throw JsBridgeException.type(
    path: path,
    message: 'Expected Map or null, found ${v.runtimeType}: $v',
  );
}

/// Coerces a non-nullable value to a Dart [Map<String, Object?>].
Map<String, Object?> jsMap(Object? v, String path) {
  final Map<String, Object?>? res = jsMapOrNull(v, path);
  if (res == null) {
    throw JsBridgeException.type(
      path: path,
      message: 'Expected non-null Map, found null',
    );
  }
  return res;
}

/// Coerces a non-nullable value to a Dart [List<Object?>].
List<Object?> jsList(Object? v, String path) {
  if (v is List) {
    return List<Object?>.from(v);
  }
  throw JsBridgeException.type(
    path: path,
    message: 'Expected List, found ${v?.runtimeType}: $v',
  );
}

/// Coerces a list of objects into typed elements using a deserializer.
List<T> jsListOf<T>(
  Object? v,
  String path,
  T Function(Map<String, Object?>) fromJson,
) {
  final List<Object?> rawList = jsList(v, path);
  final List<T> result = <T>[];
  for (int i = 0; i < rawList.length; i++) {
    final Object? item = rawList[i];
    final Map<String, Object?> map = jsMap(item, '$path[$i]');
    result.add(fromJson(map));
  }
  return result;
}

/// Coerces a list of strings strictly.
List<String> jsStringList(Object? v, String path) {
  final List<Object?> rawList = jsList(v, path);
  final List<String> result = <String>[];
  for (int i = 0; i < rawList.length; i++) {
    final Object? item = rawList[i];
    if (item is String) {
      result.add(item);
    } else {
      throw JsBridgeException.type(
        path: '$path[$i]',
        message: 'Expected String element in list, found ${item.runtimeType}: $item',
      );
    }
  }
  return result;
}

/// Coerces a map with double values strictly.
Map<String, double> jsDoubleMap(Object? v, String path) {
  final Map<String, Object?> rawMap = jsMap(v, path);
  final Map<String, double> result = <String, double>{};
  for (final MapEntry<String, Object?> entry in rawMap.entries) {
    final Object? val = entry.value;
    if (val is num) {
      result[entry.key] = val.toDouble();
    } else {
      throw JsBridgeException.type(
        path: '$path["${entry.key}"]',
        message: 'Expected num value in double map, found ${val.runtimeType}: $val',
      );
    }
  }
  return result;
}

/// Coerces a map with int values strictly.
Map<String, int> jsIntMap(Object? v, String path) {
  final Map<String, Object?> rawMap = jsMap(v, path);
  final Map<String, int> result = <String, int>{};
  for (final MapEntry<String, Object?> entry in rawMap.entries) {
    final Object? val = entry.value;
    if (val is num && val == val.truncateToDouble()) {
      result[entry.key] = val.toInt();
    } else {
      throw JsBridgeException.type(
        path: '$path["${entry.key}"]',
        message: 'Expected integral num value in int map, found ${val.runtimeType}: $val',
      );
    }
  }
  return result;
}

/// Coerces a map with string values strictly.
Map<String, String> jsStringMap(Object? v, String path) {
  final Map<String, Object?> rawMap = jsMap(v, path);
  final Map<String, String> result = <String, String>{};
  for (final MapEntry<String, Object?> entry in rawMap.entries) {
    final Object? val = entry.value;
    if (val is String) {
      result[entry.key] = val;
    } else {
      throw JsBridgeException.type(
        path: '$path["${entry.key}"]',
        message: 'Expected String value in string map, found ${val.runtimeType}: $val',
      );
    }
  }
  return result;
}

