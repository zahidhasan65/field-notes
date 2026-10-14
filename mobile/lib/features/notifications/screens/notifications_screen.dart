import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';
import '../../../widgets/widgets.dart';
import '../bloc/notifications_bloc.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  (IconData, Color) _style(AppNotificationType t) => switch (t) {
        AppNotificationType.success => (Icons.check_circle, AppColors.green),
        AppNotificationType.error => (Icons.error, AppColors.red),
        AppNotificationType.warning => (Icons.warning_amber_rounded, AppColors.orange),
        AppNotificationType.offline => (Icons.wifi_off, AppColors.orange),
        AppNotificationType.sync => (Icons.sync, AppColors.primary),
        AppNotificationType.info => (Icons.info, AppColors.primary),
      };

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          actions: [
            BlocBuilder<NotificationsBloc, NotificationsState>(
              builder: (context, state) => PopupMenuButton<String>(
                enabled: state.items.isNotEmpty,
                onSelected: (v) {
                  final bloc = context.read<NotificationsBloc>();
                  if (v == 'read') bloc.add(const NotificationsMarkAllRead());
                  if (v == 'clear') bloc.add(const NotificationsCleared());
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'read',
                    enabled: state.unreadCount > 0,
                    child: const Text('Mark all as read'),
                  ),
                  const PopupMenuItem(value: 'clear', child: Text('Clear all')),
                ],
              ),
            ),
          ],
        ),
        body: BlocBuilder<NotificationsBloc, NotificationsState>(
          builder: (context, state) {
            if (state.items.isEmpty) {
              return const EmptyState(
                Icons.notifications_none,
                'No notifications yet.\nSync results and account alerts will show up here.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: state.items.length,
              itemBuilder: (context, i) {
                final n = state.items[i];
                final (icon, color) = _style(n.type);
                return AnimatedEntrance(
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Dismissible(
                      key: ValueKey(n.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) =>
                          context.read<NotificationsBloc>().add(NotificationDeleted(n.id)),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppColors.red.withOpacity(.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete_outline, color: AppColors.red),
                      ),
                      child: AppCard(
                        onTap: () => context.read<NotificationsBloc>().add(NotificationRead(n.id)),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                                color: color.withOpacity(.14), shape: BoxShape.circle),
                            child: Icon(icon, color: color, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(
                                  child: Text(n.title,
                                      style: TextStyle(
                                          fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800)),
                                ),
                                if (!n.isRead)
                                  Container(
                                    width: 9,
                                    height: 9,
                                    decoration: const BoxDecoration(
                                        color: AppColors.primary, shape: BoxShape.circle),
                                  ),
                              ]),
                              if (n.body.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(n.body,
                                    style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                              ],
                              const SizedBox(height: 6),
                              Text(fmtTimeAgo(n.createdAt),
                                  style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
                            ]),
                          ),
                        ]),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
}
