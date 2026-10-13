import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/data.dart';
import '../features/sync/bloc/sync_bloc.dart';


class SyncBadge extends StatelessWidget {
  final String syncStatus;
  final bool showLabel;
  const SyncBadge({super.key, required this.syncStatus, this.showLabel = false});

  @override
  Widget build(BuildContext context) {
    final isSyncing = context.select((SyncBloc b) => b.state.isSyncing);
    final s = RecordSync.fromStatus(syncStatus, isSyncing: isSyncing);

    final Widget icon = s == RecordSync.syncing
        ? SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: s.color))
        : Icon(s.icon, size: 16, color: s.color);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: s == RecordSync.failed
          ? () => context.read<SyncBloc>().add(const SyncRetryFailedRequested())
          : null,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: showLabel
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                icon,
                const SizedBox(width: 5),
                Text(s.label,
                    style: TextStyle(color: s.color, fontSize: 12, fontWeight: FontWeight.w600)),
              ])
            : icon,
      ),
    );
  }
}
