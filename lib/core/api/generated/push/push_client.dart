// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:retrofit/error_logger.dart';

import '../models/ok.dart';
import '../models/push_public_key_response.dart';
import '../models/push_rest_timer_cancel_request.dart';
import '../models/push_rest_timer_request.dart';
import '../models/push_status_response.dart';
import '../models/push_subscribe_request.dart';
import '../models/push_unsubscribe_request.dart';

part 'push_client.g.dart';

@RestApi()
abstract class PushClient {
  factory PushClient(Dio dio, {String? baseUrl}) = _PushClient;

  /// VAPID public key.
  ///
  /// The instance's Web-Push application server key (generated once at first boot), for `PushManager.subscribe({applicationServerKey})`. Public.
  @GET('/api/push/public-key')
  Future<PushPublicKeyResponse> pushPublicKey();

  /// Register a Web-Push subscription.
  ///
  /// Stores the browser's `PushSubscription` for this account. Only `endpoint` and.
  /// the two protocol keys are kept. The endpoint must be a public `https://` URL —.
  /// private/loopback/link-local addresses are refused (here and again at send.
  /// time, against DNS rebinding). At most 20 subscriptions per user; the oldest.
  /// are dropped first. Re-subscribing an existing endpoint replaces it and keeps.
  /// its original `created` — the client re-sends its subscription on every.
  /// signed-in boot, so a row the instance lost comes back on its own.
  @POST('/api/push/subscribe')
  Future<Ok> pushSubscribe({@Body() required PushSubscribeRequest body});

  /// Does the server hold this subscription?
  ///
  /// Whether the caller's account has a stored subscription with exactly this `endpoint`. The browser's `PushManager.getSubscription()` says nothing about the server's side — a row pruned after a dead send (404/410/403) leaves the browser subscribed to nowhere — so the client asks here before showing the notifications switch as on, and re-registers when the answer is no.
  @GET('/api/push/status')
  Future<PushStatusResponse> pushStatus({
    @Query('endpoint') required String endpoint,
  });

  /// Remove a Web-Push subscription.
  ///
  /// Removes the caller's subscription with the given endpoint. Idempotent.
  @POST('/api/push/unsubscribe')
  Future<Ok> pushUnsubscribe({@Body() required PushUnsubscribeRequest body});

  /// Send a test notification.
  ///
  /// Sends a test push to all of the caller's subscriptions (localized with the `lang` in their synced state). Returns 200 even if delivery to individual endpoints fails — dead endpoints (404/410, and 403 for a subscription made against a VAPID key the instance no longer has) are pruned as a side effect.
  @POST('/api/push/test')
  Future<Ok> pushTest();

  /// Schedule a server-side rest-timer push.
  ///
  /// Schedules one push after `seconds` (a number or numeric string ≥ 1, clamped to.
  /// 3600). One pending timer per.
  /// device — `deviceId`, the same token the subscription was registered with; a.
  /// new call from the same device replaces it, and the push goes only to that.
  /// device's subscriptions. Without a `deviceId` there is one timer per account.
  /// and the push goes to every subscription, as before. The client schedules this.
  /// on rest start/extend and cancels on skip or on-screen completion — the push.
  /// only actually fires when the tab was backgrounded/suspended and never got to.
  /// cancel it. Timers live in memory: an API restart drops them.
  @POST('/api/push/rest-timer')
  Future<Ok> pushRestTimer({@Body() required PushRestTimerRequest body});

  /// Cancel the pending rest-timer push.
  ///
  /// Cancels the caller's scheduled rest-timer push, if any. With a `deviceId` only that device's timer; without one, every pending timer of the account. Idempotent.
  @POST('/api/push/rest-timer/cancel')
  Future<Ok> pushRestTimerCancel({@Body() PushRestTimerCancelRequest? body});
}
