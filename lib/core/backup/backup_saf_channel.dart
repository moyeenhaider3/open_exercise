// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/services.dart';

final class SafPickResult {
  const SafPickResult({
    required this.uri,
    required this.name,
  });

  final String uri;
  final String name;
}

final class BackupSafChannel {
  const BackupSafChannel([
    this._channel = const MethodChannel('com.openexercise/backup_saf'),
  ]);

  final MethodChannel _channel;

  Future<SafPickResult?> pickFolder() async {
    try {
      final Map<dynamic, dynamic>? res =
          await _channel.invokeMapMethod<dynamic, dynamic>('pickFolder');
      if (res == null) return null;
      final String? uri = res['uri'] as String?;
      final String? name = res['name'] as String?;
      if (uri == null || name == null) return null;
      return SafPickResult(uri: uri, name: name);
    } catch (_) {
      return null;
    }
  }

  Future<bool> writeFile({
    required String uri,
    required String fileName,
    required String content,
  }) async {
    try {
      final bool? success = await _channel.invokeMethod<bool>(
        'writeFile',
        <String, dynamic>{
          'uri': uri,
          'fileName': fileName,
          'content': content,
        },
      );
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isFolderAccessible(String uri) async {
    try {
      final bool? accessible = await _channel.invokeMethod<bool>(
        'isFolderAccessible',
        <String, dynamic>{'uri': uri},
      );
      return accessible ?? false;
    } catch (_) {
      return false;
    }
  }
}
