// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_palette.dart';

class AppUpdateService {
  AppUpdateService._();

  static bool _hasChecked = false;

  static const String _versionUrl =
      'https://raw.githubusercontent.com/moyeenhaider3/open_exercise/main/docs/version.json';

  static Future<void> checkUpdate(BuildContext context) async {
    if (_hasChecked) return;
    _hasChecked = true;

    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final int currentBuild = int.tryParse(packageInfo.buildNumber) ?? 1;

      final Dio dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
          headers: <String, dynamic>{
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
          },
        ),
      );

      final Response<dynamic> response = await dio.get<dynamic>(
        '$_versionUrl?t=${DateTime.now().millisecondsSinceEpoch}',
      );

      if (response.statusCode != 200 || response.data == null) return;

      final dynamic data = response.data;
      final Map<String, dynamic> json = data is Map<String, dynamic>
          ? data
          : Map<String, dynamic>.from(data as Map);

      final int minSupportedBuild = json['min_supported_build_number'] as int? ?? 1;
      final int latestBuild = json['latest_build_number'] as int? ?? 1;
      final bool forceFlag = json['force_update'] as bool? ?? false;
      final String updateUrl = (json['update_url'] as String?)?.isNotEmpty == true
          ? json['update_url'] as String
          : 'https://play.google.com/store/apps/details?id=${packageInfo.packageName}';
      final String title = json['title'] as String? ?? 'Update Available';
      final String message = json['message'] as String? ??
          'A new version of OpenGym is available. Please update to continue.';

      final bool isCritical = currentBuild < minSupportedBuild || (forceFlag && currentBuild < latestBuild);
      final bool isOptional = currentBuild < latestBuild;

      if (!context.mounted) return;

      if (isCritical) {
        _showUpdateDialog(
          context: context,
          isForced: true,
          title: 'Update Required',
          message: message,
          updateUrl: updateUrl,
        );
      } else if (isOptional) {
        _showUpdateDialog(
          context: context,
          isForced: false,
          title: title,
          message: message,
          updateUrl: updateUrl,
        );
      }
    } catch (_) {
      // Offline or network error: never block regular app usage
    }
  }

  static void _showUpdateDialog({
    required BuildContext context,
    required bool isForced,
    required String title,
    required String message,
    required String updateUrl,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: !isForced,
      builder: (BuildContext dialogContext) {
        final AppPalette palette = AppPalette.of(dialogContext);

        final Widget dialogContent = PopScope(
          canPop: !isForced,
          child: AlertDialog(
            backgroundColor: palette.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
              side: BorderSide(color: palette.sep),
            ),
            title: Text(
              title,
              style: TextStyle(
                color: palette.label,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              message,
              style: TextStyle(
                color: palette.dim,
                fontSize: 14.0,
                height: 1.5,
              ),
            ),
            actions: <Widget>[
              if (!isForced)
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Later',
                    style: TextStyle(color: palette.dim),
                  ),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.acc,
                  foregroundColor: palette.onAcc,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: () async {
                  final Uri uri = Uri.parse(updateUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Text('Update Now'),
              ),
            ],
          ),
        );

        return dialogContent;
      },
    );
  }
}
