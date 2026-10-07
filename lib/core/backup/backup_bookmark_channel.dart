// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/services.dart';

final class ResolveBookmarkResult {
  const ResolveBookmarkResult({
    this.path,
    this.isStale = false,
    this.error,
  });

  final String? path;
  final bool isStale;
  final String? error;

  bool get isSuccess => path != null && !isStale && error == null;
}

final class BackupBookmarkChannel {
  const BackupBookmarkChannel([
    this._channel = const MethodChannel('com.openexercise/backup_bookmark'),
  ]);

  final MethodChannel _channel;

  Future<String> createBookmark(String path) async {
    final String? bookmark = await _channel.invokeMethod<String>(
      'createBookmark',
      <String, dynamic>{'path': path},
    );
    if (bookmark == null) {
      throw StateError('createBookmark returned null');
    }
    return bookmark;
  }

  Future<ResolveBookmarkResult> resolveBookmark(String bookmarkData) async {
    final Map<dynamic, dynamic>? res =
        await _channel.invokeMapMethod<dynamic, dynamic>(
      'resolveBookmark',
      <String, dynamic>{'data': bookmarkData},
    );
    if (res == null) {
      return const ResolveBookmarkResult(
        error: 'No response from native bookmark channel',
      );
    }
    final String? err = res['error'] as String?;
    final String? path = res['path'] as String?;
    if (err == 'stale') {
      return const ResolveBookmarkResult(isStale: true, error: 'stale');
    }
    return ResolveBookmarkResult(path: path, error: err);
  }

  Future<void> stopAccessing() async {
    await _channel.invokeMethod<void>('stopAccessing');
  }
}
