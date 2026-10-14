import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/routes.dart';
import '../../../app/session_helpers.dart';
import '../../../core/core.dart';
import '../../../widgets/widgets.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../notifications/bloc/notifications_bloc.dart';
import '../../profile/bloc/profile_bloc.dart';
import '../bloc/home_bloc.dart';

class HomeTab extends StatelessWidget {
  final VoidCallback onGoCustomers;
  final VoidCallback onGoSites;
  const HomeTab({super.key, required this.onGoCustomers, required this.onGoSites});

  @override
  Widget build(BuildContext context) => Column(children: [
        const _Header(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => refreshWithSync(context),
            child: BlocBuilder<HomeBloc, HomeState>(
              builder: (context, state) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  const OfflineBanner(),
                  const SectionHeader("Today's Overview"),
                  const SizedBox(height: 6),
                  AnimatedEntrance(
                    child: Row(children: [
                      _StatCard(Icons.description, '${state.noteCount}', 'Field Notes',
                          AppColors.primary, () => Navigator.pushNamed(context, Routes.notes)),
                      const SizedBox(width: 10),
                      _StatCard(Icons.people, '${state.customerCount}', 'Customers',
                          AppColors.orange, onGoCustomers),
                      const SizedBox(width: 10),
                      _StatCard(Icons.location_city, '${state.siteCount}', 'Sites',
                          AppColors.green, onGoSites),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  SectionHeader('Recent Field Notes',
                      actionLabel: 'See all',
                      onAction: () => Navigator.pushNamed(context, Routes.notes)),
                  if (state.status == LoadStatus.loading) const ListSkeleton(count: 3),
                  if (state.status == LoadStatus.loaded && state.recent.isEmpty)
                    const SizedBox(
                        height: 220,
                        child: EmptyState(Icons.note_add_outlined, 'No field notes yet')),
                  ...List.generate(
                    state.recent.length,
                    (i) => AnimatedEntrance(
                      index: i + 1,
                      child: NoteCard(
                        view: state.recent[i],
                        onTap: () => Navigator.pushNamed(context, Routes.noteDetail,
                            arguments: state.recent[i].note.id),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppButton('New Field Note',
                      icon: Icons.add,
                      onPressed: () => Navigator.pushNamed(context, Routes.noteForm)),
                ],
              ),
            ),
          ),
        ),
      ]);
}


class _Header extends StatefulWidget {
  const _Header();

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  late String _greeting = greetingFor(DateTime.now());
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // re-check every 30 s so "Good morning" turns into "Good afternoon" on its own
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      final g = greetingFor(DateTime.now());
      if (g != _greeting && mounted) setState(() => _greeting = g);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _circle(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: Colors.white.withOpacity(opacity), shape: BoxShape.circle),
      );

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final name = auth is AuthAuthenticated ? auth.user.name : '';

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: Stack(children: [
          Positioned(right: -40, top: -50, child: _circle(170, .07)),
          Positioned(left: -30, bottom: -60, child: _circle(130, .06)),
          Padding(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_greeting, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                  ]),
                ),
                // ---- bell with unread badge ----
                BlocBuilder<NotificationsBloc, NotificationsState>(
                  builder: (context, n) => Stack(clipBehavior: Clip.none, children: [
                    IconButton(
                      onPressed: () => Navigator.pushNamed(context, Routes.notifications),
                      icon: const Icon(Icons.notifications_none, color: Colors.white),
                    ),
                    if (n.unreadCount > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          constraints: const BoxConstraints(minWidth: 17),
                          decoration: BoxDecoration(
                            color: AppColors.red,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Text(
                            n.unreadCount > 9 ? '9+' : '${n.unreadCount}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                  ]),
                ),
                // ---- profile picture ----
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, Routes.profile),
                  child: BlocBuilder<ProfileBloc, ProfileState>(
                    buildWhen: (a, b) => a.photoPath != b.photoPath,
                    builder: (context, p) =>
                        UserAvatar(name: name, photoPath: p.photoPath, size: 40, onDark: true),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              SyncStatusPill(onTap: () => showSyncSheet(context)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  final VoidCallback onTap;
  const _StatCard(this.icon, this.value, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => Expanded(
        child: AppCard(
          onTap: onTap,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(.22), color.withOpacity(.10)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ]),
        ),
      );
}
