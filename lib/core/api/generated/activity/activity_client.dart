// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:retrofit/error_logger.dart';

import '../models/ok.dart';
import '../models/post_activity_request.dart';

part 'activity_client.g.dart';

@RestApi()
abstract class ActivityClient {
  factory ActivityClient(Dio dio, {String? baseUrl}) = _ActivityClient;

  /// Live-workout presence heartbeat.
  ///
  /// The client pings this every ~20 s while a workout is on screen; the admin.
  /// dashboard reads who is training right now. Purely ephemeral, in-memory, never.
  /// persisted; entries expire ~70 s after the last ping. `{"active": false}`.
  /// drops the caller's entry immediately.
  @POST('/api/activity')
  Future<Ok> postActivity({@Body() required PostActivityRequest body});
}
