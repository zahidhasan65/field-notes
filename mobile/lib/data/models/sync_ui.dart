import 'package:flutter/material.dart';
import '../../core/core.dart';

enum SyncUiStatus {
  online(Icons.wifi, AppColors.green, 'Online', 'All data is up to date'),
  offline(Icons.wifi_off, AppColors.orange, "You're offline",
      'Changes are saved on this device and will sync automatically.'),
  pending(Icons.schedule, AppColors.orange, 'Pending Sync', 'Waiting to sync...'),
  syncing(Icons.sync, AppColors.primary, 'Syncing...', 'Uploading data...'),
  failed(Icons.error_outline, AppColors.red, 'Sync Failed', 'Some changes could not be synced.');

  const SyncUiStatus(this.icon, this.color, this.title, this.subtitle);
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
}

enum RecordSync {
  synced(Icons.cloud_done_outlined, AppColors.green, 'Synced'),
  pending(Icons.cloud_upload_outlined, AppColors.orange, 'Pending'),
  syncing(Icons.sync, AppColors.primary, 'Syncing'),
  failed(Icons.error_outline, AppColors.red, 'Failed - tap to retry');

  const RecordSync(this.icon, this.color, this.label);
  final IconData icon;
  final Color color;
  final String label;

  static RecordSync fromStatus(String status, {required bool isSyncing}) {
    switch (status) {
      case SyncStatus.synced:
        return RecordSync.synced;
      case SyncStatus.syncFailed:
        return RecordSync.failed;
      default:
        return isSyncing ? RecordSync.syncing : RecordSync.pending;
    }
  }
}
