// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:retrofit/error_logger.dart';

import '../models/pair_create_response.dart';
import '../models/pair_redeem_request.dart';
import '../models/pair_redeem_response.dart';

part 'pairing_client.g.dart';

@RestApi()
abstract class PairingClient {
  factory PairingClient(Dio dio, {String? baseUrl}) = _PairingClient;

  /// Mint a pairing code for the mobile app.
  ///
  /// Called from an already signed-in browser tab (Settings → "Pair the mobile.
  /// app"). Returns an 8-character code (alphabet without 0/O/1/I) the phone.
  /// redeems within 5 minutes via /api/pair/redeem. One-shot.
  @POST('/api/pair/create')
  Future<PairCreateResponse> pairCreate();

  /// Redeem a pairing code for a Bearer token.
  ///
  /// Called from the mobile app with the code shown in the browser. No session.
  /// required — the code *is* the credential (one-shot, 5-minute TTL). Returns the.
  /// same HMAC-signed session token the cookie would carry; the app sends it as.
  /// `Authorization: Bearer <token>` from then on. CSRF-exempt.
  @POST('/api/pair/redeem')
  Future<PairRedeemResponse> pairRedeem({
    @Body() required PairRedeemRequest body,
  });
}
