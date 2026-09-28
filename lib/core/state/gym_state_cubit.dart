// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/gym_state_repository.dart';
import '../models/gym_state.dart';

/// Single-writer state container for openGym user profile (D-04).
///
/// Mirrors `../openGym/frontend/src/store/useStore.js` `update` and `replaceState`:
/// updates the in-memory state, stamps `_ts = Date.now()`, emits immediately to the
/// UI, and coalesces writes to [GymStateRepository.saveState] in the background.
final class GymStateCubit extends Cubit<GymState> {
  GymStateCubit._({
    required GymStateRepository repository,
    required String uid,
    required GymState initial,
    required bool canPersist,
  })  :
        // ignore: prefer_initializing_formals
        _repository = repository,
        // ignore: prefer_initializing_formals
        _uid = uid,
        // ignore: prefer_initializing_formals
        _canPersist = canPersist,
        super(initial);

  final GymStateRepository _repository;
  final String _uid;
  final bool _canPersist;

  Completer<void>? _inFlightCompleter;
  Completer<void>? _nextCompleter;
  bool _isWriting = false;

  /// Whether mutations are persisted to the database. If [load] fails, this is
  /// false to prevent overwriting an unreadable profile (T-1-12, T-03-02).
  bool get canPersist => _canPersist;

  /// Loads the persisted state from [repository] for [uid].
  ///
  /// If [loadState] returns null, initializes with [GymState.defaults()].
  /// If [loadState] throws, starts with [GymState.defaults()], sets [canPersist] to
  /// false to protect existing data, and reports the error via [addError].
  static Future<GymStateCubit> load({
    required GymStateRepository repository,
    String uid = kLocalGuestUid,
  }) async {
    GymState? initial;
    Object? loadError;
    StackTrace? loadStackTrace;
    bool canPersist = true;

    try {
      initial = await repository.loadState(uid);
    } catch (e, st) {
      loadError = e;
      loadStackTrace = st;
      canPersist = false;
      initial = GymState.defaults();
    }

    final GymStateCubit cubit = GymStateCubit._(
      repository: repository,
      uid: uid,
      initial: initial ?? GymState.defaults(),
      canPersist: canPersist,
    );

    if (loadError != null) {
      cubit.addError(loadError, loadStackTrace);
    }

    return cubit;
  }

  /// Mirrors `useStore.update`: applies [fn], stamps `_ts = Date.now()`, emits
  /// synchronously, and queues a background save. The returned [Future] completes
  /// when this write (or a newer coalesced write) has landed in persistence.
  Future<void> mutate(GymState Function(GymState current) fn) {
    final GymState next = fn(state);
    final GymState stamped = next.copyWith(
      ts: DateTime.now().millisecondsSinceEpoch,
    );
    emit(stamped);
    return _enqueuePersist();
  }

  /// Mirrors `useStore.replaceState`: replaces the entire document, stamps `_ts`,
  /// emits synchronously, and queues a background save.
  Future<void> replaceState(GymState next) {
    final GymState stamped = next.copyWith(
      ts: DateTime.now().millisecondsSinceEpoch,
    );
    emit(stamped);
    return _enqueuePersist();
  }

  /// Awaits any in-flight write and any queued write.
  Future<void> flush() async {
    while (_isWriting || _nextCompleter != null) {
      final Future<void>? inFlight = _inFlightCompleter?.future;
      final Future<void>? next = _nextCompleter?.future;
      if (inFlight != null) {
        try {
          await inFlight;
        } catch (_) {}
      }
      if (next != null) {
        try {
          await next;
        } catch (_) {}
      }
    }
  }

  Future<void> _enqueuePersist() {
    if (!_canPersist) return Future<void>.value();
    _nextCompleter ??= Completer<void>();
    final Future<void> future = _nextCompleter!.future;
    _scheduleWrite();
    return future;
  }

  void _scheduleWrite() {
    if (_isWriting || _nextCompleter == null) return;
    _isWriting = true;
    final Completer<void> completer = _nextCompleter!;
    _nextCompleter = null;
    _inFlightCompleter = completer;

    final GymState toSave = state;
    _repository.saveState(_uid, toSave).then((_) {
      completer.complete();
    }).catchError((Object error, StackTrace stackTrace) {
      addError(error, stackTrace);
      completer.complete();
    }).whenComplete(() {
      _isWriting = false;
      _inFlightCompleter = null;
      if (_nextCompleter != null) {
        _scheduleWrite();
      }
    });
  }

  @override
  Future<void> close() async {
    await flush();
    return super.close();
  }
}
