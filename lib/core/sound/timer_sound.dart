// SPDX-License-Identifier: AGPL-3.0-or-later

/// Port of openGym lib/sound.js: WebAudio oscillator beeps become pre-rendered
/// tone assets (tool/gen_timer_tones.sh).
library;

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

import '../models/gym_state.dart';
import '../state/gym_state_cubit.dart';

final class TimerSound {
  TimerSound._({
    Map<String, AudioPlayer>? players,
    this._hasVibrator = false,
  }) : _players = players ?? const {};

  final Map<String, AudioPlayer> _players;
  final bool _hasVibrator;
  final List<Timer> _activeTimers = [];

  static const List<String> _toneKeys = [
    '660_100',
    '880_150',
    '1320_400',
    '1040_120',
    '1100_150',
    '1320_300',
  ];

  static Future<TimerSound> create() async {
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            usageType: AndroidUsageType.assistanceSonification,
            contentType: AndroidContentType.sonification,
            audioFocus: AndroidAudioFocus.none,
            stayAwake: false,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: const {},
          ),
        ),
      );

      final players = <String, AudioPlayer>{};
      for (final key in _toneKeys) {
        final player = AudioPlayer();
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setSource(AssetSource('audio/tone_$key.wav'));
        players[key] = player;
      }

      bool hasVibrator = false;
      try {
        hasVibrator = await Vibration.hasVibrator();
      } catch (e) {
        debugPrint('TimerSound: hasVibrator check failed: $e');
      }

      return TimerSound._(
        players: players,
        hasVibrator: hasVibrator,
      );
    } catch (e, st) {
      debugPrint('TimerSound.create failed, falling back to silent: $e\n$st');
      return TimerSound.silent();
    }
  }

  factory TimerSound.silent() => TimerSound._();

  void beep(bool enabled, int freq, double dur, [double when = 0]) {
    if (!enabled) return;

    final durMs = (dur * 1000).round();
    final key = '${freq}_$durMs';
    final player = _players[key];
    if (player == null) {
      debugPrint('TimerSound: unknown tone pair freq=$freq, dur=$dur ($key)');
      return;
    }

    void play() {
      try {
        player.stop().then((_) {
          player.resume();
        }).catchError((e) {
          debugPrint('TimerSound play error: $e');
        });
      } catch (e) {
        debugPrint('TimerSound play exception: $e');
      }
    }

    if (when <= 0) {
      play();
    } else {
      final timer = Timer(Duration(milliseconds: (when * 1000).round()), () {
        play();
      });
      _activeTimers.add(timer);
    }
  }

  void vibrate(Object pattern) {
    if (!_hasVibrator) return;
    try {
      if (pattern is int) {
        Vibration.vibrate(duration: pattern);
      } else if (pattern is List<int>) {
        Vibration.vibrate(pattern: [0, ...pattern]);
      } else if (pattern is List) {
        final intList = pattern.whereType<int>().toList();
        if (intList.isNotEmpty) {
          Vibration.vibrate(pattern: [0, ...intList]);
        }
      }
    } catch (e) {
      debugPrint('TimerSound.vibrate failed: $e');
    }
  }

  Future<void> setPlayOnSilent(bool on) async {
    final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    if (!isIOS) return;

    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: on
              ? AudioContextIOS(
                  category: AVAudioSessionCategory.playback,
                  options: const {AVAudioSessionOptions.mixWithOthers},
                )
              : AudioContextIOS(
                  category: AVAudioSessionCategory.ambient,
                  options: const {},
                ),
        ),
      );
    } catch (e) {
      debugPrint('TimerSound.setPlayOnSilent failed: $e');
    }
  }

  StreamSubscription<GymState> bind(GymStateCubit cubit) {
    setPlayOnSilent(cubit.state.soundOnSilent == true);
    return cubit.stream.listen((state) {
      setPlayOnSilent(state.soundOnSilent == true);
    });
  }

  void dispose() {
    for (final timer in _activeTimers) {
      timer.cancel();
    }
    _activeTimers.clear();
    for (final player in _players.values) {
      player.dispose();
    }
  }
}
