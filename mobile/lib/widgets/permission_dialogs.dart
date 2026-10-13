import 'package:flutter/material.dart';
import '../core/core.dart';

Future<bool> showSystemPermissionDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(icon, color: AppColors.primary, size: 32),
      title: Text(title, textAlign: TextAlign.center),
      content: Text(message, textAlign: TextAlign.center),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Don't allow")),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Allow')),
      ],
    ),
  );
  return r ?? false;
}

Future<bool> showPermissionBlockedDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(icon, color: AppColors.red, size: 32),
      title: Text(title, textAlign: TextAlign.center),
      content: Text(message, textAlign: TextAlign.center),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Open Settings')),
      ],
    ),
  );
  return r ?? false;
}
