import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/routes.dart';
import '../../../app/session_helpers.dart';
import '../../../core/core.dart';
import '../../../widgets/widgets.dart';
import '../bloc/home_bloc.dart';

class HomeTab extends StatelessWidget {
  final VoidCallback onGoCustomers;
  const HomeTab({super.key, required this.onGoCustomers});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    final user = currentUserOf(context);

    return Column(children: [
      _Header(greeting: _greeting, name: user?.name ?? ''),
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
                        AppColors.green, () => Navigator.pushNamed(context, Routes.sites)),
                  ]),
                ),
                const SizedBox(height: 14),
                SectionHeader('Recent Field Notes',
                    actionLabel: 'See all',
                    onAction: () => Navigator.pushNamed(context, Routes.notes)),
                if (state.status == LoadStatus.loading) const ListSkeleton(count: 3),
                if (state.status == LoadStatus.loaded && state.recent.isEmpty)
                  const SizedBox(
                      height: 220, child: EmptyState(Icons.note_add_outlined, 'No field notes yet')),
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
}

class _Header extends StatelessWidget {
  final String greeting, name;
  const _Header({required this.greeting, required this.name});

  Widget _circle(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: Colors.white.withOpacity(opacity), shape: BoxShape.circle),
      );

  @override
  Widget build(BuildContext context) => ClipRRect(
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
                      Text(greeting, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                  IconButton(
                    onPressed: () => snack(context, 'No new notifications'),
                    icon: const Icon(Icons.notifications_none, color: Colors.white),
                  ),
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: Colors.white24,
                    child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
