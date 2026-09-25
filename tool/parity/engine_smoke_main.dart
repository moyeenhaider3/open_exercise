// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_exercise/core/js/js_bridge_exception.dart';
import 'package:open_exercise/core/js/js_codec.dart';
import 'package:open_exercise/core/js/js_engine_service.dart';

void _log(String line) {
  // ignore: avoid_print
  print(line);
  stdout.writeln(line);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const int total = 8;
  int passed = 0;

  final String engineName = Platform.isAndroid
      ? 'QuickJS'
      : (Platform.isIOS ? 'JavaScriptCore' : Platform.operatingSystem);

  late final JsEngineService engine;
  try {
    engine = await JsEngineService.load();
  } catch (e, st) {
    _log('ENGINE_SMOKE: FAIL load $e\n$st');
    _log('ENGINE_SMOKE RESULT: FAIL 0/$total engine=$engineName');
    runApp(const _ResultApp(text: 'ENGINE_SMOKE RESULT: FAIL load'));
    await Future<void>.delayed(const Duration(seconds: 3));
    exit(1);
  }

  // Check 1: 8 namespaces and openGymVersion 1.3.8
  try {
    final bool okMeta = engine.meta.openGymVersion == '1.3.8';
    final Set<String> expectedNs = JsEngineService.namespaces;
    if (okMeta && expectedNs.length == 8) {
      passed++;
      _log('ENGINE_SMOKE: PASS check1_namespaces_meta v=${engine.meta.openGymVersion}');
    } else {
      _log('ENGINE_SMOKE: FAIL check1_namespaces_meta meta=$okMeta');
    }
  } catch (e) {
    _log('ENGINE_SMOKE: FAIL check1_namespaces_meta $e');
  }

  // Check 2: onerm.estimate1RM 100, 5 == 116.7
  try {
    final Object? res = engine.call('onerm.estimate1RM', <Object?>[100, 5]);
    if (res == 116.7) {
      passed++;
      _log('ENGINE_SMOKE: PASS check2_estimate1rm $res');
    } else {
      _log('ENGINE_SMOKE: FAIL check2_estimate1rm expected 116.7, got $res');
    }
  } catch (e) {
    _log('ENGINE_SMOKE: FAIL check2_estimate1rm $e');
  }

  // Check 3: default formula with jsUndefined == 116.7, brzycki == 112.5
  try {
    final Object? resDef = engine.call('onerm.estimate1RM', <Object?>[100, 5, jsUndefined]);
    final Object? resBrz = engine.call('onerm.estimate1RM', <Object?>[100, 5, 'brzycki']);
    if (resDef == 116.7 && resBrz == 112.5) {
      passed++;
      _log('ENGINE_SMOKE: PASS check3_undefined_and_brzycki def=$resDef brz=$resBrz');
    } else {
      _log('ENGINE_SMOKE: FAIL check3_undefined_and_brzycki def=$resDef brz=$resBrz');
    }
  } catch (e) {
    _log('ENGINE_SMOKE: FAIL check3_undefined_and_brzycki $e');
  }

  // Check 4: bar.plateSplit 100, 20 == 40
  try {
    final Object? res = engine.call('bar.plateSplit', <Object?>[100, 20]);
    if (res == 40) {
      passed++;
      _log('ENGINE_SMOKE: PASS check4_plate_split $res');
    } else {
      _log('ENGINE_SMOKE: FAIL check4_plate_split expected 40, got $res');
    }
  } catch (e) {
    _log('ENGINE_SMOKE: FAIL check4_plate_split $e');
  }

  // Check 5: history.setLabel returns String without throwing (exercises i18n-core and replaceAll)
  try {
    final Object? res = engine.call('history.setLabel', <Object?>[
      'bench',
      <String, Object?>{'w': 100, 'r': 5},
    ]);
    if (res is String && res == '100×5') {
      passed++;
      _log('ENGINE_SMOKE: PASS check5_history_set_label "$res"');
    } else {
      _log('ENGINE_SMOKE: FAIL check5_history_set_label expected "100×5", got $res');
    }
  } catch (e) {
    _log('ENGINE_SMOKE: FAIL check5_history_set_label $e');
  }

  // Check 6: injection probe with quotes, catch, throw, and U+2028
  try {
    final Object? res = engine.call('workoutModel.phaseForSet', <Object?>[
      <String, Object?>{'phase': '")}catch(e){};throw 1;//\u2028'},
    ]);
    if (res == 'work') {
      passed++;
      _log('ENGINE_SMOKE: PASS check6_injection_probe $res');
    } else {
      _log('ENGINE_SMOKE: FAIL check6_injection_probe expected "work", got $res');
    }
  } catch (e) {
    _log('ENGINE_SMOKE: FAIL check6_injection_probe $e');
  }

  // Check 7: onerm.doesNotExist throws JsBridgeException
  try {
    engine.call('onerm.doesNotExist');
    _log('ENGINE_SMOKE: FAIL check7_non_existent_function did not throw');
  } on JsBridgeException catch (e) {
    passed++;
    _log('ENGINE_SMOKE: PASS check7_non_existent_function threw ${e.kind}');
  } catch (e) {
    _log('ENGINE_SMOKE: FAIL check7_non_existent_function threw unexpected $e');
  }

  // Check 8: bad path throws ArgumentError
  try {
    engine.call('bad path;');
    _log('ENGINE_SMOKE: FAIL check8_bad_path did not throw');
  } on ArgumentError {
    passed++;
    _log('ENGINE_SMOKE: PASS check8_bad_path threw ArgumentError');
  } catch (e) {
    _log('ENGINE_SMOKE: FAIL check8_bad_path threw unexpected $e');
  }

  // Diagnostics and performance
  final Map<String, Object?> diag = engine.diagnostics();
  _log('ENGINE_SMOKE DIAG ${jsonEncode(diag)}');
  _log('ENGINE_SMOKE LOAD_MS ${engine.loadDuration.inMilliseconds}');

  final String resultLine = passed == total
      ? 'ENGINE_SMOKE RESULT: PASS $passed/$total engine=$engineName'
      : 'ENGINE_SMOKE RESULT: FAIL $passed/$total engine=$engineName';

  _log(resultLine);

  runApp(_ResultApp(text: resultLine));
  await Future<void>.delayed(const Duration(seconds: 4));
  exit(passed == total ? 0 : 1);
}

class _ResultApp extends StatelessWidget {
  const _ResultApp({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            text,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
