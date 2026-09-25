// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:retrofit/error_logger.dart';

import '../models/get_config_response.dart';
import '../models/get_health_response.dart';

part 'meta_client.g.dart';

@RestApi()
abstract class MetaClient {
  factory MetaClient(Dio dio, {String? baseUrl}) = _MetaClient;

  /// Health check.
  ///
  /// Always public. Also reports how many user accounts exist.
  @GET('/api/health')
  Future<GetHealthResponse> getHealth();

  /// Public instance configuration.
  ///
  /// The flags the login screen needs before anyone is signed in. Both reflect.
  /// environment variables on the server (`INVITE_ONLY`, `ALLOW_GUEST`).
  @GET('/api/config')
  Future<GetConfigResponse> getConfig();
}
