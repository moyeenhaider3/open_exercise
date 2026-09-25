// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:retrofit/error_logger.dart';

import '../models/admin_audit_response.dart';
import '../models/admin_invite_new_request.dart';
import '../models/admin_invite_new_response.dart';
import '../models/admin_invite_revoke_request.dart';
import '../models/admin_invites_response.dart';
import '../models/admin_user_detail.dart';
import '../models/admin_user_disable_request.dart';
import '../models/admin_user_disable_response.dart';
import '../models/admin_users_response.dart';
import '../models/cat.dart';
import '../models/ok.dart';

part 'admin_client.g.dart';

@RestApi()
abstract class AdminClient {
  factory AdminClient(Dio dio, {String? baseUrl}) = _AdminClient;

  /// Admin: list all users.
  ///
  /// One row per user with workout counts, last sync, push status and live presence. `workouts` counts only the entries the drill-down can show. Admin only.
  @GET('/api/admin/users')
  Future<AdminUsersResponse> adminUsers();

  /// Admin: one user in detail.
  ///
  /// Drill-down — full workout history (newest first) and body-weight log for one user. Admin only. Anything in `routines`, `bodyweight` or `workouts` that is not an object is left out, and a list that is not an array reads as empty: PUT /api/data drops those entries now, but a state file written before it did still has them and this route has to answer for it.
  ///
  /// [id] - The user id.
  @GET('/api/admin/user')
  Future<AdminUserDetail> adminUser({@Query('id') required String id});

  /// Admin: disable or re-enable a user.
  ///
  /// Sets the `disabled` flag. A disabled account is locked out everywhere at once.
  /// (every existing session stops resolving) and dropped from live presence.
  /// Admins cannot be disabled. Audited.
  @POST('/api/admin/user/disable')
  Future<AdminUserDisableResponse> adminUserDisable({
    @Body() required AdminUserDisableRequest body,
  });

  /// Admin: list invite codes.
  ///
  /// All invite codes, with the redeeming user's name resolved for display.
  @GET('/api/admin/invites')
  Future<AdminInvitesResponse> adminInvites();

  /// Admin: mint an invite code.
  ///
  /// Creates a fresh single-use invite code (16 hex chars = 64 bits — the code itself is the thing that isn't worth guessing; rate limiting is the reverse proxy's job). Audited.
  @POST('/api/admin/invites/new')
  Future<AdminInviteNewResponse> adminInviteNew({
    @Body() AdminInviteNewRequest? body,
  });

  /// Admin: revoke an unused invite code.
  ///
  /// Deletes an unused code. A code that was already redeemed cannot be revoked.
  @POST('/api/admin/invites/revoke')
  Future<Ok> adminInviteRevoke({
    @Body() required AdminInviteRevokeRequest body,
  });

  /// Admin: read the activity log.
  ///
  /// The audit log (sign-ins, failed attempts, admin actions), newest first, paged.
  /// by event id (`before` cursor — offset paging would repeat rows as new events.
  /// land). Retention (`AUDIT_MAX` events / `AUDIT_DAYS` days) is applied on read.
  /// as well as on the hourly compaction. When `AUDIT_LOG` is off the route still.
  /// answers, with `enabled: false` and whatever was logged before.
  ///
  /// [limit] - Page size.
  ///
  /// [before] - Only events with id < before (cursor from `nextBefore`).
  ///
  /// [cat] - Filter — `fail` keeps only failed events; any other value keeps events whose name starts with `<cat>.` (in practice `auth` or `admin`).
  @GET('/api/admin/audit')
  Future<AdminAuditResponse> adminAudit({
    @Query('before') int? before,
    @Query('cat') Cat? cat,
    @Query('limit') int? limit = 100,
  });

  /// Admin: clear the activity log.
  ///
  /// Deletes the log file. The clear is itself the first event of the fresh log, and event ids are never reset — a wipe always leaves a visible id gap.
  @POST('/api/admin/audit/clear')
  Future<Ok> adminAuditClear();
}
