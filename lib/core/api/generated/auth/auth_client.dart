// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:retrofit/error_logger.dart';

import '../models/get_me_response.dart';
import '../models/login_options_response.dart';
import '../models/login_verify_request.dart';
import '../models/login_verify_response.dart';
import '../models/ok.dart';
import '../models/register_options_request.dart';
import '../models/register_options_response.dart';
import '../models/register_verify_request.dart';
import '../models/register_verify_response.dart';

part 'auth_client.g.dart';

@RestApi()
abstract class AuthClient {
  factory AuthClient(Dio dio, {String? baseUrl}) = _AuthClient;

  /// Who am I?
  ///
  /// Resolves the current session to a user.
  @GET('/api/me')
  Future<GetMeResponse> getMe();

  /// Start passkey registration (WebAuthn ceremony, step 1).
  ///
  /// Returns `PublicKeyCredentialCreationOptions` (from.
  /// `@simplewebauthn/server`'s `generateRegistrationOptions`) plus a challenge id.
  /// `cid`. The client passes `options` to.
  /// `navigator.credentials.create()` (or `@simplewebauthn/browser`'s.
  /// `startRegistration`) and sends the result to `/api/register/verify` together.
  /// with the `cid`. Challenges are one-shot and expire after 5 minutes.
  ///
  /// CSRF-exempt (the challenge is the credential). No session required.
  @POST('/api/register/options')
  Future<RegisterOptionsResponse> registerOptions({
    @Body() required RegisterOptionsRequest body,
  });

  /// Finish passkey registration (WebAuthn ceremony, step 2).
  ///
  /// Verifies the authenticator's attestation response against the stored.
  /// challenge (`verifyRegistrationResponse`), creates the user + credential, and.
  /// signs the caller in (sets the session cookie). On an invite-only instance the.
  /// invite is re-checked and burned here. CSRF-exempt.
  @POST('/api/register/verify')
  Future<RegisterVerifyResponse> registerVerify({
    @Body() required RegisterVerifyRequest body,
  });

  /// Start passkey login (WebAuthn ceremony, step 1).
  ///
  /// Returns `PublicKeyCredentialRequestOptions`.
  /// (`generateAuthenticationOptions` with an empty `allowCredentials` — discoverable.
  /// credentials / resident keys are required at registration, so the browser offers.
  /// the user their passkeys itself) plus a one-shot challenge id `cid`.
  /// CSRF-exempt. Takes no request body.
  @POST('/api/login/options')
  Future<LoginOptionsResponse> loginOptions();

  /// Finish passkey login (WebAuthn ceremony, step 2).
  ///
  /// Verifies the assertion (`verifyAuthenticationResponse`), updates the signature.
  /// counter, and signs the caller in (sets the session cookie). CSRF-exempt.
  @POST('/api/login/verify')
  Future<LoginVerifyResponse> loginVerify({
    @Body() required LoginVerifyRequest body,
  });

  /// Sign out (this device).
  ///
  /// Clears the session cookie. Always succeeds — an invalid or missing session is a no-op. The token itself stays cryptographically valid until it expires; use /api/logout/all to revoke tokens.
  @POST('/api/logout')
  Future<Ok> logout();

  /// Sign out everywhere.
  ///
  /// Bumps the account's session version, which invalidates **every** cookie and.
  /// Bearer token ever issued for it — on every device, including a copy someone.
  /// walked off with. Passkeys are untouched; signing back in works immediately.
  /// Also clears the caller's own cookie. Unredeemed pairing codes for the account.
  /// are voided too.
  @POST('/api/logout/all')
  Future<Ok> logoutAll();
}
