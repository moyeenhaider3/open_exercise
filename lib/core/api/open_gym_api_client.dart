// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Thin, hand-authored wrapper around the generated openGym Dio/Retrofit clients
// (see lib/core/api/generated/, produced by tool/gen_api.sh — FND-02).
//
// No server URL is hardcoded here: the server is chosen at sign-in (Phase 5).
// No auth/cookie/bearer handling happens here either (Phase 5); `dio` is exposed
// so Phase 5 can attach interceptors for cookies/bearer tokens/CSRF headers.
//
// `/api/data`'s `state` payload is deliberately kept as a raw `Map<String, Object?>`
// instead of the generated `State` class: `State` is a closed `@JsonSerializable()`
// class with one field per *declared* schema property (see
// lib/core/api/generated/models/state.dart and
// .planning/phases/01-foundation-models/01-CODEGEN-SPIKE.md, Finding 3). Decoding
// through it would silently drop any state key the real app writes that isn't in
// that declared list. `fetchState`/`pushState` below talk to `/api/data` directly
// through the same `Dio` instance instead of the generated `DataClient.getData()`/
// `putData()` methods, so the state `Map` round-trips untouched.

import 'package:dio/dio.dart';

import 'generated/activity/activity_client.dart';
import 'generated/admin/admin_client.dart';
import 'generated/auth/auth_client.dart';
import 'generated/data/data_client.dart';
import 'generated/meta/meta_client.dart';
import 'generated/pairing/pairing_client.dart';
import 'generated/push/push_client.dart';
import 'generated/rest_client.dart';

/// Builds [OpenGymApiClient] instances bound to a chosen server.
///
/// v1 is guest-only (AUTH-05, Phase 5 D-01/D-02): nothing may call [create] at runtime, so
/// no user data leaves the device. The factory and the generated client are kept, inert,
/// per D-11. tool/guest_audit.sh fails if a call site appears.
///
/// Kept separate from [OpenGymApiClient] so tests/call sites can supply a
/// custom [Dio] or [HttpClientAdapter] (e.g. a recording/mock adapter) without
/// touching the wrapper's own construction logic.
class ApiClientFactory {
  const ApiClientFactory();

  /// Creates an [OpenGymApiClient] talking to [baseUrl].
  ///
  /// Pass [dio] to reuse/reconfigure an existing [Dio] instance: its
  /// `baseUrl` is set to [baseUrl] (so a shared instance can never keep
  /// talking to a previously configured server) and its timeouts are left
  /// as-is; otherwise a new one is built with sane defaults. Pass [adapter] to swap the transport (e.g. in a recording
  /// adapter) on whichever [Dio] instance is used.
  OpenGymApiClient create({
    required String baseUrl,
    Dio? dio,
    HttpClientAdapter? adapter,
  }) {
    final resolvedDio =
        dio ??
        Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
            contentType: Headers.jsonContentType,
          ),
        );
    resolvedDio.options.baseUrl = baseUrl;
    if (adapter != null) {
      resolvedDio.httpClientAdapter = adapter;
    }
    return OpenGymApiClient._(resolvedDio);
  }
}

/// Thrown by [OpenGymApiClient.fetchState]/[OpenGymApiClient.pushState] when
/// `/api/data` answers with a body that is not the expected JSON object shape
/// (an HTML error or captive-portal page, a non-object `state`, a non-numeric
/// `rev`, ...). Kept distinct from "the server has nothing" so a sync layer
/// never pushes over, or adopts, garbage.
class UnexpectedResponseException implements Exception {
  const UnexpectedResponseException(this.message, {this.body});

  final String message;

  /// The decoded response body that failed validation, for diagnostics.
  final Object? body;

  @override
  String toString() => 'UnexpectedResponseException: $message';
}

/// A record of `/api/data`'s response: the raw state `Map` (or `null` if
/// nothing has synced yet) and the server's revision of that document.
///
/// [rev] is `null` only when the server answered without a `rev` at all: a
/// server from before revisions (`../openGym/frontend/src/store/useStore.js`
/// treats `rev == null` as "no revision to hold", not as rev 0).
typedef FetchStateResult = ({Map<String, Object?>? state, int? rev});

/// Hand-authored wrapper over the generated openGym Dio/Retrofit clients.
///
/// Every generated API group stays reachable through its own getter (named
/// after the generated client classes), so no operation in openapi.yaml is
/// hidden behind this wrapper. [fetchState]/[pushState] are the two typed
/// convenience methods this phase adds on top of the generated `data` client,
/// for the `/api/data` `state` blob (see the file-level doc comment above).
class OpenGymApiClient {
  OpenGymApiClient._(this._dio) : _rest = RestClient(_dio);

  final Dio _dio;
  final RestClient _rest;

  /// The underlying [Dio] instance. Reserved for Phase 5 to attach
  /// auth/CSRF/cookie interceptors; nothing in this phase configures auth.
  Dio get dio => _dio;

  MetaClient get meta => _rest.meta;
  AuthClient get auth => _rest.auth;
  PairingClient get pairing => _rest.pairing;
  DataClient get data => _rest.data;
  PushClient get push => _rest.push;
  ActivityClient get activity => _rest.activity;
  AdminClient get admin => _rest.admin;

  /// `GET /api/data`, read raw so unknown `state` keys are never dropped.
  ///
  /// Returns the state as a plain `Map` (or `null` when the server explicitly
  /// answers `state: null`, i.e. nothing has synced yet) alongside the
  /// server's revision (`0` when there is no document, `null` for a server
  /// from before revisions that sends no `rev`).
  ///
  /// Throws [UnexpectedResponseException] if the body is not a JSON object, if
  /// `state` is missing or neither `null` nor an object, or if `rev` is
  /// present but not a number.
  Future<FetchStateResult> fetchState() async {
    final response = await _dio.get<Object?>('/api/data');
    final body = response.data;

    if (body is! Map) {
      throw UnexpectedResponseException('GET /api/data: body is not a JSON object', body: body);
    }
    if (!body.containsKey('state')) {
      throw UnexpectedResponseException('GET /api/data: response has no state', body: body);
    }
    final rawState = body['state'];
    final Map<String, Object?>? state;
    if (rawState == null) {
      state = null;
    } else if (rawState is Map) {
      state = rawState.map((key, value) => MapEntry(key.toString(), value));
    } else {
      throw UnexpectedResponseException('GET /api/data: state is not an object', body: body);
    }

    return (state: state, rev: _revOf(body, 'GET /api/data'));
  }

  /// `PUT /api/data`, sent raw so the [state] `Map` round-trips untouched.
  ///
  /// [baseRev] makes the write conditional (see `DataClient.putData`'s doc
  /// comment on the generated method for the server's 409-on-mismatch
  /// behavior). Returns the revision the write produced, or `null` if the
  /// server sent no `rev` (a server from before revisions -- the caller should
  /// drop its stored revision, as `useStore.js` does, rather than assume the
  /// write landed at [baseRev]).
  ///
  /// Throws [UnexpectedResponseException] if the body is not a JSON object or
  /// `rev` is present but not a number.
  Future<int?> pushState({
    required Map<String, Object?> state,
    required int baseRev,
  }) async {
    final response = await _dio.put<Object?>(
      '/api/data',
      data: <String, Object?>{'state': state, 'baseRev': baseRev},
    );
    final body = response.data;

    if (body is! Map) {
      throw UnexpectedResponseException('PUT /api/data: body is not a JSON object', body: body);
    }
    return _revOf(body, 'PUT /api/data');
  }

  /// `rev` as an int; `null` if absent or null (pre-revision server); throws
  /// for any other type.
  static int? _revOf(Map<dynamic, dynamic> body, String op) {
    final rawRev = body['rev'];
    if (rawRev == null) return null;
    if (rawRev is num) return rawRev.toInt();
    throw UnexpectedResponseException('$op: rev is not a number', body: body);
  }
}
