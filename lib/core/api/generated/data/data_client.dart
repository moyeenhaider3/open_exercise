// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:retrofit/error_logger.dart';

import '../models/api_data_rev_response.dart';
import '../models/get_data_response.dart';
import '../models/put_data_request.dart';
import '../models/put_data_response.dart';

part 'data_client.g.dart';

@RestApi()
abstract class DataClient {
  factory DataClient(Dio dio, {String? baseUrl}) = _DataClient;

  /// Pull the account's app state.
  ///
  /// Returns the caller's entire app state as one JSON blob, or `{"state": null}` if nothing has been synced yet, together with `rev`, the server's revision of that document (0 when there is none). A client keeps the `rev` it last read or wrote and sends it back as `baseRev` on the next push, which lets the server refuse a write over a document the client never saw (see the 409 on PUT).
  @GET('/api/data')
  Future<GetDataResponse> getData();

  /// Push the account's app state.
  ///
  /// Replaces the stored state wholesale (atomic write; there is no merge on the.
  /// server). The `active` field — an in-progress workout — is stripped before.
  /// saving: a running session belongs to the device running it. Body limit 5 MiB.
  ///
  /// With `baseRev` the write is conditional: it goes through only when `baseRev`.
  /// equals the document's current revision, and answers 409 with the current.
  /// document otherwise — the client merges the two and pushes again with the.
  /// revision it was given. Without `baseRev` the write is unconditional (clients.
  /// from before revisions, and deliberate replaces such as a backup import). The.
  /// server stamps the new revision into the document as `_rev`; a `_rev` sent by.
  /// the client is ignored.
  @PUT('/api/data')
  Future<PutDataResponse> putData({@Body() required PutDataRequest body});

  /// Current revision of the caller's profile state.
  ///
  /// The `rev` that `GET /api/data` would return, without the document. Signed-in clients poll.
  /// this while open and on every return to the foreground and fetch the document only when.
  /// the number changed.
  ///
  /// Name not received - field will be skipped.
  @GET('/api/data/rev')
  Future<ApiDataRevResponse> getApiDataRev();
}
