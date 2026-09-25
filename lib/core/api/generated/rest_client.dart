// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart' hide Headers;

import 'meta/meta_client.dart';
import 'auth/auth_client.dart';
import 'pairing/pairing_client.dart';
import 'data/data_client.dart';
import 'push/push_client.dart';
import 'activity/activity_client.dart';
import 'admin/admin_client.dart';

/// openGym API `v1.3.8`.
///
/// Passkey (WebAuthn) auth + per-user state storage for openGym.
///
/// The backend of [openGym](https://opengym.duarte-santos.ch) — a free, open-source.
/// gym & body-weight tracker. One Node file, no framework, JSON-file storage,.
/// HMAC-signed session cookies.
///
/// ### Authentication.
/// Sign-in is **passkey only** (WebAuthn, via `@simplewebauthn/server`). A successful.
/// `register/verify` or `login/verify` sets the session cookie; every authenticated.
/// route then works with that cookie. The paired mobile app has no shared cookie jar,.
/// so it redeems a short pairing code (`/api/pair/redeem`) for the *same* signed token.
/// and sends it as `Authorization: Bearer <token>` instead.
///
/// ### Sessions.
/// The cookie/bearer value is `<payload>.<hmac>` where the payload is.
/// `<uid>:<expiry-ms>:<session-version>`, signed with a per-instance secret.
/// (HMAC-SHA256). Sessions last `SESSION_DAYS` (default 90). `POST /api/logout/all`.
/// bumps the user's session version, which invalidates every token ever issued for.
/// the account.
///
/// ### CSRF.
/// State-changing browser requests must come from the app's own origin. The server.
/// checks `Sec-Fetch-Site` (falling back to `Origin` vs the configured `ORIGIN`);.
/// a mismatch is refused with `403 {"error":"cross-origin request refused"}` on any.
/// non-GET route. Exempt: the WebAuthn and `pair/redeem` routes (each carries its own.
/// one-shot credential in the body) and any request authenticated with a Bearer token.
///
/// ### Environment-dependent behavior.
/// - `INVITE_ONLY=1` — registration requires a valid invite code (minted by an admin).
/// - `ALLOW_GUEST=0` — hides the client-side "continue without account" mode; the.
///   server merely reports the flag via `GET /api/config` (guest mode never talks to.
///   this API at all).
/// - `ADMIN_UIDS=<uid>,<uid>` — user ids treated as admins (a `"admin": true` flag on.
///   the user record in `db.json` works too). Admins get the `/api/admin/*` routes.
/// - `AUDIT_LOG` (default on), `AUDIT_MAX` (default 5000 events), `AUDIT_DAYS`.
///   (default 90), `AUDIT_IP` (`off` | `net` | `full`, default off) — shape the audit.
///   log served by `GET /api/admin/audit`.
///
/// ### Conventions.
/// - Every response body is JSON with `Cache-Control: no-store`.
/// - Errors are always `{"error": "<human-readable message>"}`.
/// - Unknown method+path pairs return `404 {"error":"not found"}`; an unhandled.
///   exception returns `500 {"error":"server error"}`.
/// - Request bodies are parsed as JSON regardless of Content-Type. A body that does.
///   not parse, or parses to anything but an object (`null`, a string, an array), is.
///   `400 {"error":"invalid json"}` on every route that reads one; an empty body counts.
///   as `{}`. A body over 5 MiB is `413 {"error":"body too large"}`; the rest of the.
///   upload is discarded so the answer reaches the client.
/// - CORS: the request's `Origin` is reflected in `Access-Control-Allow-Origin`.
///   **without** `Allow-Credentials` — cross-origin callers can only ever.
///   authenticate with a Bearer token, never with the cookie.
///
class RestClient {
  RestClient(Dio dio, {String? baseUrl}) : _dio = dio, _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '1.3.8';

  MetaClient? _meta;
  AuthClient? _auth;
  PairingClient? _pairing;
  DataClient? _data;
  PushClient? _push;
  ActivityClient? _activity;
  AdminClient? _admin;

  MetaClient get meta => _meta ??= MetaClient(_dio, baseUrl: _baseUrl);

  AuthClient get auth => _auth ??= AuthClient(_dio, baseUrl: _baseUrl);

  PairingClient get pairing =>
      _pairing ??= PairingClient(_dio, baseUrl: _baseUrl);

  DataClient get data => _data ??= DataClient(_dio, baseUrl: _baseUrl);

  PushClient get push => _push ??= PushClient(_dio, baseUrl: _baseUrl);

  ActivityClient get activity =>
      _activity ??= ActivityClient(_dio, baseUrl: _baseUrl);

  AdminClient get admin => _admin ??= AdminClient(_dio, baseUrl: _baseUrl);
}
