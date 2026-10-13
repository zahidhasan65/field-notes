import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/core.dart';
import '../data/data.dart';
import '../features/sync/bloc/sync_bloc.dart';

/// Shown on the main screens when the device is offline or a sync failed.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<SyncBloc, SyncBlocState>(
        builder: (context, state) {
          final status = state.uiStatus;
          final show = status == SyncUiStatus.offline || status == SyncUiStatus.failed;
          return AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: show
                ? _Banner(state: state, status: status)
                : const SizedBox(width: double.infinity, height: 0),
          );
        },
      );
}

class _Banner extends StatelessWidget {
  final SyncBlocState state;
  final SyncUiStatus status;
  const _Banner({required this.state, required this.status});

  @override
  Widget build(BuildContext context) {
    final c = status.color;
    final failed = status == SyncUiStatus.failed;
    final n = state.unsyncedCount;
    final subtitle = failed
        ? '${state.failedCount} change${state.failedCount == 1 ? '' : 's'} could not be synced.'
        : n > 0
            ? '$n change${n == 1 ? '' : 's'} saved on this device. They sync automatically when you are back online.'
            : status.subtitle;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: c.withOpacity(.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(.35)),
      ),
      child: Row(children: [
        Icon(status.icon, color: c, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(status.title, style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 13)),
            Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ]),
        ),
        if (failed)
          TextButton(
            onPressed: () => context.read<SyncBloc>().add(const SyncRetryFailedRequested()),
            child: const Text('Retry'),
          ),
      ]),
    );
  }
}
