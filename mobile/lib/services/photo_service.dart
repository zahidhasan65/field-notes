import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/core.dart';
import '../widgets/permission_dialogs.dart';
import 'permission_service.dart';
import 'photo_storage.dart';

/// Camera / gallery picker. Returns the path of a copy stored inside the app.
class PhotoService {
  PhotoService(this._permissions, this._storage);

  final PermissionService _permissions;
  final PhotoStorage _storage;
  final ImagePicker _picker = ImagePicker();

  Future<String?> pick(BuildContext context, ImageSource source) async {
    if (source == ImageSource.camera) {
      final ok = await _permissions.ensure(context, AppPermission.camera);
      if (!ok) return null;
    }

    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        imageQuality: 80,
      );
      if (file == null) return null;
      return await _storage.copyIn(file.path);
    } on PlatformException catch (e) {
      if (!context.mounted) return null;
      if (e.code.contains('access_denied')) {
        final open = await showPermissionBlockedDialog(
          context,
          icon: source == ImageSource.camera ? Icons.photo_camera : Icons.photo_library,
          title: 'Photo access is blocked',
          message: 'Allow access in the app settings to attach photos.',
        );
        if (open) await openAppSettings();
      } else {
        snack(context, 'Could not open the picker.');
      }
      return null;
    }
  }
}
