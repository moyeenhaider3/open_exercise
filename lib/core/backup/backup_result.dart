// SPDX-License-Identifier: AGPL-3.0-or-later

sealed class BackupResult {
  const BackupResult();
}

final class BackupSuccess extends BackupResult {
  const BackupSuccess();
}

final class BackupFailure extends BackupResult {
  const BackupFailure(this.reason);
  final String reason;
}
