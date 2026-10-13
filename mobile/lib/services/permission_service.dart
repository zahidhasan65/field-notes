import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/core.dart';
import '../widgets/permission_dialogs.dart';

enum AppPermission { camera, location }


class PermissionService {
  Permission _map(AppPermission p) => switch (p) {
        AppPermission.camera => Permission.camera,
        AppPermission.location => Permission.locationWhenInUse,
      };

  String _label(AppPermission p) => switch (p) {
        AppPermission.camera => 'Camera',
        AppPermission.location => 'Location',
      };

  IconData _icon(AppPermission p) => switch (p) {
        AppPermission.camera => Icons.photo_camera,
        AppPermission.location => Icons.location_on,
      };

  Future<bool> ensure(BuildContext context, AppPermission p) async {
    final permission = _map(p);

    var status = await permission.status;
    if (status.isGranted || status.isLimited) return true;

    if (!status.isPermanentlyDenied && !status.isRestricted) {
      status = await permission.request();
      if (status.isGranted || status.isLimited) return true;
    }

    if (!context.mounted) return false;

    if (status.isPermanentlyDenied || status.isRestricted) {
      final open = await showPermissionBlockedDialog(
        context,
        icon: _icon(p),
        title: '${_label(p)} access is blocked',
        message:
            'Allow ${_label(p).toLowerCase()} access in the app settings to use this feature.',
      );
      if (open) await openAppSettings();
    } else {
      snack(context, '${_label(p)} permission denied');
    }
    return false;
  }
}
