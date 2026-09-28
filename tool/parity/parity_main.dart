// SPDX-License-Identifier: AGPL-3.0-or-later

/// Flutter device-run parity harness entrypoint.
///
/// Executes all 167 vitest-verified openGym fixture cases through the typed Dart facades
/// against the active JS runtime (QuickJS on Android, JavaScriptCore on iOS) and verifies
/// exact parity against vitest fixture expectations without tolerances or epsilons.
///
/// This file is tool-only, is never imported from lib/, and is not a test.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_exercise/core/js/js_bridge_exception.dart';
import 'package:open_exercise/core/js/js_engine_service.dart';

import 'dispatch/bar_dispatch.dart';
import 'dispatch/history_dispatch.dart';
import 'dispatch/onerm_dispatch.dart';
import 'dispatch/progression_dispatch.dart';
import 'dispatch/recovery_dispatch.dart';
import 'dispatch/session_dispatch.dart';
import 'dispatch/workout_model_dispatch.dart';
import 'parity_compare.dart';
import 'parity_fixtures_data.dart';
import 'parity_types.dart';

void _log(String line) {
  // ignore: avoid_print
  print(line);
  stdout.writeln(line);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final String engineName = Platform.isAndroid
      ? 'QuickJS'
      : (Platform.isIOS ? 'JavaScriptCore' : Platform.operatingSystem);

  late final JsEngineService engine;
  try {
    engine = await JsEngineService.load();
  } catch (e, st) {
    _log('PARITY FAIL load $e\n$st');
    _log('PARITY RESULT: FAIL 0/0 engine=$engineName openGym=? source=?');
    runApp(const _ResultApp(text: 'PARITY RESULT: FAIL load'));
    await Future<void>.delayed(const Duration(seconds: 2));
    exit(1);
  }

  final String sha12 = engine.meta.sourceSha256.length >= 12
      ? engine.meta.sourceSha256.substring(0, 12)
      : engine.meta.sourceSha256;

  // Stale fixtures gate: bundle SHA256 must match fixture source SHA256 exactly.
  if (engine.meta.sourceSha256 != kParityFixturesSourceSha256) {
    _log(
      'PARITY FAIL stale-fixtures bundle=${engine.meta.sourceSha256} fixtures=$kParityFixturesSourceSha256',
    );
    final String resultLine =
        'PARITY RESULT: FAIL 0/0 engine=$engineName openGym=${engine.meta.openGymVersion} source=$sha12';
    _log(resultLine);
    runApp(const _ResultApp(text: 'PARITY RESULT: FAIL stale-fixtures'));
    await Future<void>.delayed(const Duration(seconds: 2));
    exit(1);
  }

  // Merge all 8 dispatch tables.
  final Map<String, ParityCall> dispatch = <String, ParityCall>{
    ...onermDispatch(engine),
    ...barDispatch(engine),
    ...workoutModelDispatch(engine),
    ...progressionDispatch(engine),
    ...recoveryDispatch(engine),
    ...historyDispatch(engine),
    ...sessionStartDispatch(engine),
    ...sessionMergeDispatch(engine),
  };

  final Set<String> inventorySet = kBridgeInventory.toSet();
  final Set<String> dispatchKeys = dispatch.keys.toSet();
  final Set<String> missingDispatch = inventorySet.difference(dispatchKeys);
  final Set<String> extraDispatch = dispatchKeys.difference(inventorySet);

  bool dispatchCoverageFailed = false;
  if (missingDispatch.isNotEmpty || extraDispatch.isNotEmpty) {
    dispatchCoverageFailed = true;
    for (final String key in missingDispatch) {
      _log('PARITY FAIL dispatch-coverage missing $key');
    }
    for (final String key in extraDispatch) {
      _log('PARITY FAIL dispatch-coverage extra $key');
    }
  }

  int totalCases = 0;
  int passedCases = 0;
  final Set<String> exercisedFns = <String>{};

  // Process fixtures in deterministic file order.
  final List<String> fixtureFiles = kParityFixturesBase64.keys.toList()..sort();

  for (final String fixtureFile in fixtureFiles) {
    final String base64Content = kParityFixturesBase64[fixtureFile]!;
    final String jsonString = utf8.decode(base64Decode(base64Content));
    final Map<String, Object?> suite =
        jsonDecode(jsonString) as Map<String, Object?>;
    final String moduleName = suite['module'] as String;
    final List<Object?> cases = suite['cases'] as List<Object?>;

    int moduleTotal = 0;
    int modulePassed = 0;

    for (final Object? caseItem in cases) {
      final Map<String, Object?> caseMap = caseItem as Map<String, Object?>;
      final String caseId = caseMap['id'] as String;
      final String fnName = caseMap['fn'] as String;
      final List<Object?> args =
          (caseMap['args'] as List<Object?>?) ?? <Object?>[];
      final Object? expected = caseMap['expected'];
      final String from = (caseMap['from'] as String?) ?? '';

      totalCases++;
      moduleTotal++;

      final bool expectsThrow = expected is Map &&
          expected.length == 1 &&
          expected[r'$throws'] == true;

      final ParityCall? call = dispatch[fnName];
      if (call == null) {
        _log(
          'PARITY FAIL $caseId $fnName at \$ expected=${jsonEncode(expected)} actual="No dispatch function registered" ulp=- from=$from',
        );
        continue;
      }

      exercisedFns.add(fnName);

      if (expectsThrow) {
        try {
          final Object? actual = call(args);
          _log(
            'PARITY FAIL $caseId $fnName at \$ expected={"\\\$throws":true} actual=${jsonEncode(actual)} ulp=- from=$from',
          );
        } on JsBridgeException {
          modulePassed++;
          passedCases++;
        } on ArgumentError {
          modulePassed++;
          passedCases++;
        } catch (e) {
          _log(
            'PARITY FAIL $caseId $fnName at \$ expected={"\\\$throws":true} actual="Unexpected exception: $e" ulp=- from=$from',
          );
        }
      } else {
        try {
          final Object? actual = call(args);
          final ParityDiff? diff = jsonDeepEqual(expected, actual);
          if (diff == null) {
            modulePassed++;
            passedCases++;
          } else {
            final String ulpStr =
                diff.ulpDistance != null ? '${diff.ulpDistance}' : '-';
            _log(
              'PARITY FAIL $caseId $fnName at ${diff.path} expected=${jsonEncode(diff.expected)} actual=${jsonEncode(diff.actual)} ulp=$ulpStr from=$from',
            );
          }
        } catch (e, st) {
          _log(
            'PARITY FAIL $caseId $fnName at \$ expected=${jsonEncode(expected)} actual="Exception: $e\\n$st" ulp=- from=$from',
          );
        }
      }
    }

    _log('PARITY $moduleName $modulePassed/$moduleTotal');
  }

  final int totalFns = kBridgeInventory.length;
  final int exercisedCount = exercisedFns.intersection(inventorySet).length;
  _log('PARITY COVERAGE $exercisedCount/$totalFns inventory functions exercised');

  final List<String> unexercised =
      inventorySet.difference(exercisedFns).toList()..sort();
  if (unexercised.isNotEmpty) {
    _log('PARITY UNEXERCISED: ${unexercised.join(', ')}');
  }

  final bool overallPass = !dispatchCoverageFailed &&
      totalCases > 0 &&
      passedCases == totalCases;
  final String status = overallPass ? 'PASS' : 'FAIL';
  final String resultLine =
      'PARITY RESULT: $status $passedCases/$totalCases engine=$engineName openGym=${engine.meta.openGymVersion} source=$sha12';

  _log(resultLine);

  runApp(_ResultApp(text: resultLine));
  await Future<void>.delayed(const Duration(seconds: 2));
  exit(overallPass ? 0 : 1);
}

class _ResultApp extends StatelessWidget {
  const _ResultApp({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
