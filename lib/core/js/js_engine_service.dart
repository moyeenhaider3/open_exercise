// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_js/flutter_js.dart';

import 'js_bridge_exception.dart';
import 'js_codec.dart';

/// Metadata identifying the bundled openGym source and build provenance.
final class JsLibMeta {
  const JsLibMeta({
    required this.openGymVersion,
    required this.sourceSha256,
    required this.esbuild,
    required this.target,
  });

  factory JsLibMeta.fromJson(Map<String, Object?> json) {
    return JsLibMeta(
      openGymVersion: json['openGymVersion'] as String? ?? 'unknown',
      sourceSha256: json['sourceSha256'] as String? ?? 'unknown',
      esbuild: json['esbuild'] as String? ?? 'unknown',
      target: json['target'] as String? ?? 'unknown',
    );
  }

  final String openGymVersion;
  final String sourceSha256;
  final String esbuild;
  final String target;

  @override
  String toString() =>
      'JsLibMeta(openGymVersion: $openGymVersion, sourceSha256: $sourceSha256, esbuild: $esbuild, target: $target)';
}

/// Service providing typed, safe execution of openGym's original JavaScript domain logic.
///
/// **Execution Model:**
/// All [evaluate] calls are synchronous and run on the calling isolate.
///
/// **Security & Injection:**
/// Arguments are marshalled strictly through [jsonEncode] with U+2028 and U+2029 escaping.
/// Never string-interpolate arbitrary Dart values into evaluation expressions.
///
/// **Localization:**
/// Presentation-string helpers (e.g. `history.setLabel`, `exLine`, `fmtSec`) return
/// default English strings because openGym's full `i18n.js` translation state is not
/// loaded inside this calculation engine.
final class JsEngineService {
  JsEngineService._({
    required this._runtime,
    required this.meta,
    required this.loadDuration,
  });

  static const String bundleAsset = 'assets/js/opengym-lib.bundle.js';

  static const Set<String> namespaces = <String>{
    'onerm',
    'progression',
    'bar',
    'workoutModel',
    'recovery',
    'history',
    'sessionStart',
    'sessionMerge',
    'exercises',
    'muscles',
    'effort',
    'starter',
    'exerciseHistory',
    'repRange',
    'progressionCopy',
    'finish',
    'backfill',
    'units',
    'viewAgg',
    'recoveryView',
    'muscleView',
  };

  static final RegExp _pathRegex = RegExp(r'^([A-Za-z]+)\.([A-Za-z_$][A-Za-z0-9_$]*)$');

  final JavascriptRuntime _runtime;
  final JsLibMeta meta;
  final Duration loadDuration;
  bool _disposed = false;

  /// Loads and initializes the openGym JavaScript calculation engine.
  ///
  /// Evaluates [bundleAsset] once and verifies that all expected namespaces and
  /// provenance metadata are present.
  static Future<JsEngineService> load({
    AssetBundle? assetBundle,
    JavascriptRuntime Function()? runtimeFactory,
  }) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    final AssetBundle bundle = assetBundle ?? rootBundle;
    final String bundleSource;
    try {
      bundleSource = await bundle.loadString(bundleAsset);
    } catch (e, st) {
      throw JsBridgeException.load(
        message: 'Failed to load asset "$bundleAsset": $e',
        jsStack: st.toString(),
      );
    }

    // Pass xhr: false so the engine has no network fetch capability (T-02-05).
    final JavascriptRuntime runtime = (runtimeFactory != null)
        ? runtimeFactory()
        : getJavascriptRuntime(xhr: false);

    final JsEvalResult loadResult = runtime.evaluate(
      bundleSource,
      sourceUrl: 'opengym-lib.bundle.js',
    );

    if (loadResult.isError) {
      final String err = loadResult.stringResult;
      runtime.dispose();
      throw JsBridgeException.load(
        message: 'Failed to evaluate bundle: $err',
      );
    }

    const String verifyExpr = '''
(function(){
  try {
    var hasLib = typeof OpenGymLib === 'object' && OpenGymLib !== null;
    var keys = hasLib ? Object.keys(OpenGymLib) : [];
    var meta = typeof __openGymLibMeta === 'object' && __openGymLibMeta !== null ? __openGymLibMeta : null;
    return JSON.stringify({ok: true, keys: keys, meta: meta});
  } catch(e) {
    return JSON.stringify({ok: false, error: String(e && e.message || e)});
  }
})()
''';

    final JsEvalResult verifyResult = runtime.evaluate(verifyExpr);
    if (verifyResult.isError) {
      final String err = verifyResult.stringResult;
      runtime.dispose();
      throw JsBridgeException.load(
        message: 'Verification evaluation failed: $err',
      );
    }

    final Object? decoded = jsonDecode(verifyResult.stringResult);
    if (decoded is! Map<String, Object?> || decoded['ok'] != true) {
      runtime.dispose();
      throw JsBridgeException.load(
        message: 'Verification response failed: ${verifyResult.stringResult}',
      );
    }

    final List<Object?> rawKeys = (decoded['keys'] as List<Object?>?) ?? <Object?>[];
    final Set<String> loadedNamespaces = rawKeys.whereType<String>().toSet();

    for (final String ns in namespaces) {
      if (!loadedNamespaces.contains(ns)) {
        runtime.dispose();
        throw JsBridgeException.load(
          message: 'Bundle missing required namespace "$ns". Found: $loadedNamespaces',
        );
      }
    }

    final Object? rawMeta = decoded['meta'];
    if (rawMeta is! Map<String, Object?>) {
      runtime.dispose();
      throw JsBridgeException.load(
        message: 'Bundle missing valid __openGymLibMeta object',
      );
    }

    final JsLibMeta meta = JsLibMeta.fromJson(rawMeta);
    stopwatch.stop();

    return JsEngineService._(
      runtime: runtime,
      meta: meta,
      loadDuration: stopwatch.elapsed,
    );
  }

  void _checkDisposed() {
    if (_disposed) {
      throw StateError('JsEngineService disposed');
    }
  }

  /// Calls a function exported under an openGym namespace.
  ///
  /// [path] must match `<namespace>.<methodName>`, where `<namespace>` is one of
  /// [namespaces].
  ///
  /// Optional arguments omitted by the caller should be set to [jsUndefined], which
  /// ensures they reach JavaScript as `void 0` rather than `null`.
  Object? call(String path, [List<Object?> args = const <Object?>[]]) {
    _checkDisposed();

    final Match? match = _pathRegex.firstMatch(path);
    if (match == null) {
      throw ArgumentError.value(path, 'path', 'Must match <namespace>.<methodName>');
    }
    final String ns = match.group(1)!;
    final String name = match.group(2)!;
    if (!namespaces.contains(ns)) {
      throw ArgumentError.value(ns, 'path', 'Unknown namespace "$ns"');
    }

    // Trim trailing jsUndefined elements
    int lastDefined = args.length - 1;
    while (lastDefined >= 0 && identical(args[lastDefined], jsUndefined)) {
      lastDefined--;
    }

    final List<Object?> trimmedArgs = (lastDefined < 0)
        ? const <Object?>[]
        : args.sublist(0, lastDefined + 1);

    final List<int> undefinedIndices = <int>[];
    final List<Object?> cleanArgs = <Object?>[];
    for (int i = 0; i < trimmedArgs.length; i++) {
      final Object? arg = trimmedArgs[i];
      if (identical(arg, jsUndefined)) {
        undefinedIndices.add(i);
        cleanArgs.add(null);
      } else {
        cleanArgs.add(arg);
      }
    }

    String encodedArgs = jsonEncode(cleanArgs);
    // Escape U+2028 and U+2029 for safe JS evaluation
    encodedArgs = encodedArgs.replaceAll('\u2028', r'\u2028').replaceAll('\u2029', r'\u2029');

    final StringBuffer undefAssignments = StringBuffer();
    for (final int idx in undefinedIndices) {
      undefAssignments.write('a[$idx]=void 0;');
    }

    final String encodedName = jsonEncode(name);

    final String expr =
        '(function(){try{var a=$encodedArgs;$undefAssignments'
        'var f=OpenGymLib.$ns[$encodedName];'
        'if(typeof f!=="function")return JSON.stringify({e:"not a function"});'
        'var r=f.apply(null,a);'
        'if(r===undefined&&$encodedName==="cleanupSg")r=a[0];'
        'return JSON.stringify({ok:r===undefined?null:r});'
        '}catch(x){return JSON.stringify({e:String(x&&x.message||x),s:String(x&&x.stack||"")});}})()';

    final JsEvalResult result = _runtime.evaluate(expr);
    if (result.isError) {
      throw JsBridgeException.call(
        path: path,
        message: result.stringResult,
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(result.stringResult);
    } catch (e) {
      throw JsBridgeException.decode(
        path: path,
        message: 'Failed to decode JSON result: ${result.stringResult}',
      );
    }

    if (decoded is! Map<String, Object?>) {
      throw JsBridgeException.decode(
        path: path,
        message: 'Invalid envelope format: ${result.stringResult}',
      );
    }

    if (decoded.containsKey('e')) {
      final String errMsg = decoded['e']?.toString() ?? 'Unknown JS error';
      final String? jsStack = decoded['s']?.toString();
      throw JsBridgeException.call(
        path: path,
        message: errMsg,
        jsStack: jsStack,
      );
    }

    if (!decoded.containsKey('ok')) {
      throw JsBridgeException.decode(
        path: path,
        message: 'Envelope missing "ok" key: ${result.stringResult}',
      );
    }

    return decoded['ok'];
  }

  /// Reads an exported constant or value from an openGym namespace.
  Object? read(String path) {
    _checkDisposed();

    final Match? match = _pathRegex.firstMatch(path);
    if (match == null) {
      throw ArgumentError.value(path, 'path', 'Must match <namespace>.<propertyName>');
    }
    final String ns = match.group(1)!;
    final String name = match.group(2)!;
    if (!namespaces.contains(ns)) {
      throw ArgumentError.value(ns, 'path', 'Unknown namespace "$ns"');
    }

    final String encodedName = jsonEncode(name);
    final String expr =
        '(function(){try{'
        'var r=OpenGymLib.$ns[$encodedName];'
        'return JSON.stringify({ok:r===undefined?null:r});'
        '}catch(x){return JSON.stringify({e:String(x&&x.message||x),s:String(x&&x.stack||"")});}})()';

    final JsEvalResult result = _runtime.evaluate(expr);
    if (result.isError) {
      throw JsBridgeException.call(
        path: path,
        message: result.stringResult,
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(result.stringResult);
    } catch (e) {
      throw JsBridgeException.decode(
        path: path,
        message: 'Failed to decode JSON result: ${result.stringResult}',
      );
    }

    if (decoded is! Map<String, Object?>) {
      throw JsBridgeException.decode(
        path: path,
        message: 'Invalid envelope format: ${result.stringResult}',
      );
    }

    if (decoded.containsKey('e')) {
      final String errMsg = decoded['e']?.toString() ?? 'Unknown JS error';
      final String? jsStack = decoded['s']?.toString();
      throw JsBridgeException.call(
        path: path,
        message: errMsg,
        jsStack: jsStack,
      );
    }

    return decoded['ok'];
  }

  /// Returns the keys of an exported object (such as `onerm.FORMULAS`).
  List<String> keysOf(String path) {
    _checkDisposed();

    final Match? match = _pathRegex.firstMatch(path);
    if (match == null) {
      throw ArgumentError.value(path, 'path', 'Must match <namespace>.<propertyName>');
    }
    final String ns = match.group(1)!;
    final String name = match.group(2)!;
    if (!namespaces.contains(ns)) {
      throw ArgumentError.value(ns, 'path', 'Unknown namespace "$ns"');
    }

    final String encodedName = jsonEncode(name);
    final String expr =
        '(function(){try{'
        'var obj=OpenGymLib.$ns[$encodedName];'
        'if(typeof obj!=="object"||obj===null)return JSON.stringify({e:"not an object"});'
        'return JSON.stringify({ok:Object.keys(obj)});'
        '}catch(x){return JSON.stringify({e:String(x&&x.message||x),s:String(x&&x.stack||"")});}})()';

    final JsEvalResult result = _runtime.evaluate(expr);
    if (result.isError) {
      throw JsBridgeException.call(
        path: path,
        message: result.stringResult,
      );
    }

    final Object? decoded = jsonDecode(result.stringResult);
    if (decoded is! Map<String, Object?> || decoded.containsKey('e')) {
      final String errMsg = (decoded is Map ? decoded['e'] : null)?.toString() ?? 'Unknown error';
      throw JsBridgeException.call(
        path: path,
        message: errMsg,
      );
    }

    final List<Object?> rawList = jsList(decoded['ok'], path);
    return rawList.map((Object? e) => e.toString()).toList();
  }

  /// Returns runtime environment diagnostics.
  Map<String, Object?> diagnostics() {
    _checkDisposed();

    const String expr = '''
(function(){
  var opt=false;
  try{
    opt=(new Function('return ({a:1})?.a'))()===1;
  }catch(_){}
  return JSON.stringify({
    replaceAll: typeof String.prototype.replaceAll === 'function',
    normalize: typeof String.prototype.normalize === 'function',
    intl: typeof Intl !== 'undefined',
    optionalChainingNative: opt,
    engine: typeof navigator === 'undefined' ? 'no-navigator' : 'navigator'
  });
})()
''';

    final JsEvalResult result = _runtime.evaluate(expr);
    if (result.isError) {
      throw JsBridgeException.call(
        path: 'diagnostics',
        message: result.stringResult,
      );
    }

    final Object? decoded = jsonDecode(result.stringResult);
    return jsMap(decoded, 'diagnostics');
  }

  /// Disposes the underlying JavaScript runtime.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _runtime.dispose();
  }
}
