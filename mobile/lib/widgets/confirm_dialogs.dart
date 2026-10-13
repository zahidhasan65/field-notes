import 'package:flutter/material.dart';
import '../core/core.dart';

/// [details] is an optional warning line, e.g. "This will also delete 3 sites and 12 notes."
Future<bool> confirmDelete(BuildContext context, String what, {String? details}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Delete $what?'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (details != null)
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(details, style: const TextStyle(fontSize: 13))),
            ]),
          ),
        const Text('This action cannot be undone.'),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.red))),
      ],
    ),
  );
  return r ?? false;
}

enum LogoutChoice { cancel, syncFirst, logoutAnyway }

/// Warns about unsynced changes before logout.
Future<LogoutChoice> confirmLogout(BuildContext context, int unsynced) async {
  final r = await showDialog<LogoutChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(unsynced > 0 ? Icons.warning_amber_rounded : Icons.logout,
          color: unsynced > 0 ? AppColors.orange : AppColors.primary, size: 32),
      title: Text(unsynced > 0 ? 'Unsynced changes' : 'Log out?', textAlign: TextAlign.center),
      content: Text(
        unsynced > 0
            ? 'You have $unsynced change${unsynced == 1 ? '' : 's'} that ${unsynced == 1 ? "hasn't" : "haven't"} synced yet. '
                'If you log out now, you could lose ${unsynced == 1 ? 'it' : 'them'}.'
            : 'Are you sure you want to log out?',
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, LogoutChoice.cancel), child: const Text('Cancel')),
        if (unsynced > 0)
          TextButton(onPressed: () => Navigator.pop(ctx, LogoutChoice.syncFirst), child: const Text('Sync first')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, LogoutChoice.logoutAnyway),
          child: Text(unsynced > 0 ? 'Logout anyway' : 'Logout',
              style: TextStyle(color: unsynced > 0 ? AppColors.red : AppColors.primary)),
        ),
      ],
    ),
  );
  return r ?? LogoutChoice.cancel;
}

Future<bool> confirmClearLocalData(BuildContext context, int unsynced) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.red, size: 32),
      title: const Text('Clear local data?', textAlign: TextAlign.center),
      content: Text(
        'This removes all data stored on this device. '
        '${unsynced > 0 ? '$unsynced unsynced change${unsynced == 1 ? '' : 's'} will be lost. ' : ''}'
        'Log in again to restore your synced data from the server.',
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear data', style: TextStyle(color: AppColors.red))),
      ],
    ),
  );
  return r ?? false;
}
