import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/core.dart';
import '../features/sync/bloc/sync_bloc.dart';
import 'app_button.dart';

void showSyncSheet(BuildContext context) {
  final bloc = context.read<SyncBloc>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.pal.bg,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => BlocProvider.value(value: bloc, child: const _SyncSheet()),
  );
}

class _SyncSheet extends StatelessWidget {
  const _SyncSheet();

  Widget _row(String label, String value, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Text(label, style: const TextStyle(color: AppColors.muted)),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
        ]),
      );

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: BlocBuilder<SyncBloc, SyncBlocState>(
            builder: (context, state) {
              final s = state.uiStatus;
              return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Sync status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: s.color.withOpacity(.14), shape: BoxShape.circle),
                    child: Icon(s.icon, color: s.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      Text(s.subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                    ]),
                  ),
                ]),
                const Divider(height: 28),
                _row('Last synced', fmtTimeAgo(state.lastSyncedAt)),
                _row('Waiting to sync', '${state.pendingCount}',
                    color: state.pendingCount > 0 ? AppColors.orange : AppColors.green),
                _row('Failed', '${state.failedCount}',
                    color: state.failedCount > 0 ? AppColors.red : AppColors.green),
                if (state.lastError != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.red.withOpacity(.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(state.lastError!,
                        style: const TextStyle(color: AppColors.red, fontSize: 12.5)),
                  ),
                ],
                const SizedBox(height: 8),
                Text('Server: ${ApiConstants.baseUrl}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
                const SizedBox(height: 12),
                AppButton(
                  'Sync now',
                  icon: Icons.sync,
                  isLoading: state.isSyncing,
                  onPressed: () {
                    if (!state.isOnline) {
                      snack(context, "You're offline. Changes will sync when you're back online.");
                      return;
                    }
                    context.read<SyncBloc>().add(const SyncRequested());
                  },
                ),
                if (state.failedCount > 0) ...[
                  const SizedBox(height: 10),
                  AppButton(
                    'Retry failed changes',
                    outlined: true,
                    icon: Icons.refresh,
                    onPressed: () => context.read<SyncBloc>().add(const SyncRetryFailedRequested()),
                  ),
                ],
              ]);
            },
          ),
        ),
      );
}
