import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/core.dart';
import '../features/sync/bloc/sync_bloc.dart';

class SyncStatusPill extends StatelessWidget {
  final VoidCallback onTap;
  const SyncStatusPill({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) => BlocBuilder<SyncBloc, SyncBlocState>(
        builder: (context, state) {
          final s = state.uiStatus;
          final subtitle = state.isOnline && state.pendingCount > 0 && !state.isSyncing
              ? '${state.pendingCount} change${state.pendingCount == 1 ? '' : 's'} waiting'
              : s.subtitle;
          return GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                s.name == 'syncing'
                    ? SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2, color: s.color))
                    : Icon(s.icon, size: 16, color: s.color),
                const SizedBox(width: 6),
                Text(s.title,
                    style: TextStyle(color: s.color, fontWeight: FontWeight.w700, fontSize: 12.5)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
                ),
              ]),
            ),
          );
        },
      );
}
