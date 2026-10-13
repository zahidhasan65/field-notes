import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/session_helpers.dart';
import '../../../core/core.dart';
import '../../../data/data.dart';
import '../../../widgets/widgets.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../sync/bloc/sync_bloc.dart';
import '../bloc/settings_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _radio(BuildContext context, NoteStatus current, NoteStatus s) {
    final selected = current == s;
    return InkWell(
      onTap: () => context.read<SettingsBloc>().add(DefaultNoteStatusChanged(s)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.muted),
          const SizedBox(width: 12),
          Text(s.label, style: TextStyle(fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
        ]),
      ),
    );
  }

  Widget _tile(IconData i, String title, String sub, VoidCallback onTap) => AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Icon(i, color: AppColors.muted),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(sub, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ]),
          ),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ]),
      );

  void _account(BuildContext context) {
    final user = currentUserOf(context);
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Avatar(user?.name ?? '?', size: 64),
            const SizedBox(height: 10),
            Text(user?.name ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text(user?.email ?? '', style: const TextStyle(color: AppColors.muted)),
          ]),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final sync = context.read<SyncBloc>();
    final auth = context.read<AuthBloc>();
    final choice = await confirmLogout(context, sync.state.unsyncedCount);
    if (!context.mounted) return;

    switch (choice) {
      case LogoutChoice.cancel:
        break;
      case LogoutChoice.syncFirst:
        if (!sync.state.isOnline) {
          snack(context, "You're offline. Connect to the internet to sync.");
        } else {
          sync.add(const SyncRequested());
        }
      case LogoutChoice.logoutAnyway:
        auth.add(const AuthLogoutRequested());
    }
  }

  Future<void> _clearLocalData(BuildContext context) async {
    final sync = context.read<SyncBloc>();
    final auth = context.read<AuthBloc>();
    final localData = context.read<LocalDataRepository>();
    final userId = currentUserId(context);

    if (!await confirmClearLocalData(context, sync.state.unsyncedCount)) return;

    // stop syncing first so nothing writes while the data is removed
    sync.add(const SyncStopped());
    await localData.clearUserData(userId);
    // the next login restores everything from the server
    auth.add(const AuthLogoutRequested());
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const Text('Settings', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          AnimatedEntrance(
            child: AppCard(
              padding: const EdgeInsets.all(16),
              child: BlocBuilder<SettingsBloc, SettingsState>(
                builder: (context, state) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Default Note Status',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 2),
                  const Text('Used when creating a new field note (saved locally)',
                      style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 6),
                  ...NoteStatus.values.map((s) => _radio(context, state.defaultStatus, s)),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const AnimatedEntrance(index: 1, child: _SyncCard()),
          const SizedBox(height: 12),
          AnimatedEntrance(
            index: 2,
            child: Column(children: [
              _tile(Icons.tune, 'App Preferences', 'More options coming soon',
                  () => snack(context, 'More preferences are coming soon')),
              const SizedBox(height: 10),
              _tile(Icons.sync, 'Sync & Offline Data', 'Sync status and details',
                  () => showSyncSheet(context)),
              const SizedBox(height: 10),
              _tile(Icons.delete_sweep_outlined, 'Clear Local Data', 'Then log in to restore from server',
                  () => _clearLocalData(context)),
              const SizedBox(height: 10),
              _tile(Icons.person_outline, 'Account', 'View profile', () => _account(context)),
              const SizedBox(height: 10),
              _tile(Icons.info_outline, 'About', 'Version 1.0.0', () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Field Notes',
                  applicationVersion: '1.0.0',
                  applicationLegalese: 'Capture. Organize. Sync.',
                  applicationIcon: const AppLogo(size: 40),
                );
              }),
            ]),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              foregroundColor: AppColors.red,
              backgroundColor: AppColors.red.withOpacity(.06),
              side: BorderSide(color: AppColors.red.withOpacity(.3)),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            onPressed: () => _logout(context),
          ),
          const SizedBox(height: 12),
        ]),
      );
}

/// Real sync state, last synced time, unsynced count and "Sync now".
class _SyncCard extends StatelessWidget {
  const _SyncCard();

  @override
  Widget build(BuildContext context) => BlocBuilder<SyncBloc, SyncBlocState>(
        builder: (context, state) {
          final s = state.uiStatus;
          final unsynced = state.unsyncedCount;
          return AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: s.color.withOpacity(.14), shape: BoxShape.circle),
                  child: Icon(s.icon, color: s.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(s.subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ]),
                ),
              ]),
              const Divider(height: 24),
              Row(children: [
                const Text('Last synced', style: TextStyle(color: AppColors.muted)),
                const Spacer(),
                Text(fmtTimeAgo(state.lastSyncedAt), style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                const Text('Unsynced changes', style: TextStyle(color: AppColors.muted)),
                const Spacer(),
                Text('$unsynced',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: unsynced > 0 ? AppColors.orange : AppColors.green)),
              ]),
              const SizedBox(height: 14),
              AppButton(
                'Sync now',
                icon: Icons.sync,
                isLoading: state.isSyncing,
                onPressed: () {
                  if (!state.isOnline) {
                    snack(context, "No internet connection. Changes will sync when you're back online.");
                    return;
                  }
                  context.read<SyncBloc>().add(const SyncRequested());
                },
              ),
            ]),
          );
        },
      );
}
