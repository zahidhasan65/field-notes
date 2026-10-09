import '../../notes/screens/notes_screen.dart';
import 'package:flutter/material.dart';
import '../../notes/screens/notes_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../notes/screens/notes_screen.dart';
import '../bloc/home_bloc.dart';
import '../../notes/screens/notes_screen.dart';
import '../bloc/home_event.dart';
import '../../notes/screens/notes_screen.dart';
import '../bloc/home_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const blue = Color(0xFF2478F8);
  static const deepBlue = Color(0xFF2052BD);
  static const background = Color(0xFFF5F8FD);
  static const text = Color(0xFF17243D);
  static const muted = Color(0xFF7888A2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeInitial || state is HomeLoading) {
            return const Center(child: CircularProgressIndicator(color: blue));
          }

          if (state is HomeError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 48,
                      color: muted,
                    ),
                    const SizedBox(height: 16),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => context.read<HomeBloc>().add(
                        const HomeLoadRequested(),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is! HomeLoaded) {
            return const SizedBox.shrink();
          }

          final notes = state.fieldNotes.reversed.take(5).toList();

          return RefreshIndicator(
            color: blue,
            onRefresh: () async {
              context.read<HomeBloc>().add(const HomeLoadRequested());
              await Future<void>.delayed(const Duration(milliseconds: 500));
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _header(context)),
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -20),
                    child: _overview(
                      notes: state.fieldNotes.length,
                      customers: state.customers.length,
                      sites: state.sites.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Recent Field Notes',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: text,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _message(
                            context,
                            'Notes screen will be connected next.',
                          ),
                          child: const Text(
                            'See all',
                            style: TextStyle(
                              color: blue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (notes.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: _emptyNotes(),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final note = notes[index];
                        return _noteCard(
                          title: (note.title ?? '').trim().isEmpty
                              ? 'Untitled note'
                              : note.title!,
                          description: (note.description ?? '').trim().isEmpty
                              ? 'Field visit'
                              : note.description!,
                          status: note.status ?? 'PENDING',
                          index: index,
                        );
                      }, childCount: notes.length),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                    child: SizedBox(
                      height: 54,
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _message(
                          context,
                          'New Field Note screen will be connected next.',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: blue,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 25),
                        label: const Text(
                          'New Field Note',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _bottomNavigation(context),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        22,
        MediaQuery.of(context).padding.top + 12,
        22,
        58,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [blue, deepBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.17),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Field Notes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _headerIcon(
                icon: Icons.notifications_none_rounded,
                onTap: () =>
                    _message(context, 'Notifications will be connected next.'),
                notification: true,
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(25),
                onTap: () =>
                    _message(context, 'Profile screen will be connected next.'),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.19),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.account_circle_rounded,
                    color: Color(0xFFE7EEFF),
                    size: 42,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          const Text(
            'Good morning,',
            style: TextStyle(color: Color(0xFFDCE8FF), fontSize: 14),
          ),
          const SizedBox(height: 3),
          const Text(
            'Zahid Hasan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep your field work organised and up to date.',
            style: TextStyle(color: Color(0xFFDCE8FF), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _headerIcon({
    required IconData icon,
    required VoidCallback onTap,
    bool notification = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: SizedBox(
        width: 42,
        height: 42,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.17),
              child: Icon(icon, color: Colors.white, size: 23),
            ),
            if (notification)
              Positioned(
                right: 4,
                top: 3,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF7065),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _overview({
    required int notes,
    required int customers,
    required int sites,
  }) {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.fromLTRB(16, 19, 16, 17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF253B61).withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Overview",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: text,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${now.day} ${months[now.month - 1]} ${now.year}',
            style: const TextStyle(fontSize: 12, color: muted),
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Expanded(
                child: _overviewTile(
                  title: 'Field Notes',
                  count: notes,
                  icon: Icons.description_outlined,
                  color: const Color(0xFF2478F8),
                  tint: const Color(0xFFF0F5FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _overviewTile(
                  title: 'Customers',
                  count: customers,
                  icon: Icons.people_alt_outlined,
                  color: const Color(0xFFF09A21),
                  tint: const Color(0xFFFFF7E9),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _overviewTile(
                  title: 'Sites',
                  count: sites,
                  icon: Icons.location_on_outlined,
                  color: const Color(0xFF159A75),
                  tint: const Color(0xFFEEFAF5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _overviewTile({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Color tint,
  }) {
    return Container(
      height: 126,
      padding: const EdgeInsets.fromLTRB(10, 12, 7, 11),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const Spacer(),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: text,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: muted),
          ),
        ],
      ),
    );
  }

  Widget _emptyNotes() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 27),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EEF7)),
      ),
      child: const Column(
        children: [
          Icon(Icons.note_add_outlined, size: 43, color: Color(0xFF8EA2C0)),
          SizedBox(height: 12),
          Text(
            'No field notes yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: text,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Your site visit notes will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: muted),
          ),
        ],
      ),
    );
  }

  Widget _noteCard({
    required String title,
    required String description,
    required String status,
    required int index,
  }) {
    final normalized = status.toUpperCase();
    final Color statusColor;
    final Color statusTint;

    if (normalized == 'COMPLETED') {
      statusColor = const Color(0xFF159A75);
      statusTint = const Color(0xFFE7F8F0);
    } else if (normalized == 'IN_PROGRESS') {
      statusColor = const Color(0xFF2877E8);
      statusTint = const Color(0xFFEAF2FF);
    } else {
      statusColor = const Color(0xFFDE9A25);
      statusTint = const Color(0xFFFFF4DF);
    }

    const colors = [
      Color(0xFF2877E8),
      Color(0xFFDE9A25),
      Color(0xFF9C55BD),
      Color(0xFF159A75),
    ];
    final iconColor = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE8EEF7)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.description_outlined, color: iconColor, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: text,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: statusTint,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              normalized == 'COMPLETED'
                  ? 'Completed'
                  : normalized == 'IN_PROGRESS'
                  ? 'In Progress'
                  : 'Pending',
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomNavigation(BuildContext context) {
    const items = [
      (Icons.grid_view_rounded, 'Home'),
      (Icons.description_outlined, 'Notes'),
      (Icons.people_alt_outlined, 'Customers'),
      (Icons.settings_outlined, 'Settings'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE9EEF6))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final selected = index == 0;

              return Expanded(
                child: InkWell(
                  onTap: () {
                    if (!selected) {
                      if (item.$2 == 'Notes') {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => NotesScreen(
                  userId: context.read<HomeBloc>().userId,
                ),
              ),
            );
          } else {
            _message(
              context,
              '${item.$2} screen navigation will be connected next.',
            );
          }
                    }
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.$1, size: 21, color: selected ? blue : muted),
                      const SizedBox(height: 4),
                      Text(
                        item.$2,
                        style: TextStyle(
                          fontSize: 10,
                          color: selected ? blue : muted,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  void _message(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }
}
