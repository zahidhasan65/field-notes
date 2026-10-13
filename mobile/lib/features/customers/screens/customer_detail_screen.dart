import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/routes.dart';
import '../../../core/core.dart';
import '../../../data/data.dart';
import '../../../widgets/widgets.dart';
import '../bloc/customer_detail_bloc.dart';

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({super.key});

  Future<void> _delete(BuildContext context, CustomerView v) async {
    final sites = v.siteCount;
    final notes = v.noteCount;
    final details = (sites == 0 && notes == 0)
        ? null
        : 'This will also delete $sites site${sites == 1 ? '' : 's'} and $notes note${notes == 1 ? '' : 's'}.';
    if (!await confirmDelete(context, 'customer', details: details)) return;
    if (context.mounted) {
      context.read<CustomerDetailBloc>().add(const CustomerDeleteRequested());
    }
  }

  Widget _info(IconData i, String? t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Icon(i, size: 18, color: AppColors.muted),
          const SizedBox(width: 12),
          Expanded(child: Text(t == null || t.isEmpty ? '-' : t)),
        ]),
      );

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<CustomerDetailBloc, CustomerDetailState>(
        listenWhen: (prev, curr) => !prev.deleted && curr.deleted,
        listener: (context, state) {
          final m = ScaffoldMessenger.of(context);
          Navigator.pop(context);
          m.showSnackBar(const SnackBar(
              content: Text('Customer deleted'), behavior: SnackBarBehavior.floating));
        },
        builder: (context, state) {
          final v = state.view;
          if (v == null) {
            return Scaffold(
              appBar: AppBar(),
              body: state.status == LoadStatus.failure
                  ? ErrorState(
                      message: "We couldn't load this customer.",
                      onRetry: () =>
                          context.read<CustomerDetailBloc>().add(const CustomerDetailStarted()))
                  : const Center(child: CircularProgressIndicator()),
            );
          }
          final c = v.customer;
          final sites = state.sites;

          return Scaffold(
            appBar: AppBar(actions: [
              PopupMenuButton<String>(
                onSelected: (value) => value == 'edit'
                    ? Navigator.pushNamed(context, Routes.customerForm, arguments: c)
                    : _delete(context, v),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ]),
            body: ListView(padding: const EdgeInsets.all(16), children: [
              AnimatedEntrance(
                child: Column(children: [
                  Avatar(c.name, size: 70),
                  const SizedBox(height: 10),
                  Text(c.name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                  if (c.contactPerson != null)
                    Text(c.contactPerson!, style: const TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 4),
                  SyncBadge(syncStatus: c.syncStatus, showLabel: true),
                ]),
              ),
              const SizedBox(height: 14),
              AnimatedEntrance(
                index: 1,
                child: AppCard(
                  child: Column(children: [
                    _info(Icons.phone_outlined, c.phone),
                    _info(Icons.mail_outline, c.email),
                    _info(Icons.location_on_outlined, c.address),
                    const Divider(),
                    InkWell(
                      onTap: () => Navigator.pushNamed(context, Routes.sites, arguments: c),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(children: [
                          const Icon(Icons.location_city, size: 18, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(child: Text('${v.siteCount} Sites')),
                          const Icon(Icons.chevron_right, color: AppColors.muted),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              const SectionHeader('Recent Sites'),
              const SizedBox(height: 8),
              if (sites.isEmpty)
                const SizedBox(
                    height: 160,
                    child: EmptyState(Icons.location_city, 'No sites for this customer yet')),
              ...List.generate(sites.take(3).length, (i) {
                final s = sites[i];
                return AnimatedEntrance(
                  index: i + 2,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      onTap: () => Navigator.pushNamed(context, Routes.notes, arguments: s.site),
                      child: Row(children: [
                        Avatar(s.site.siteName),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s.site.siteName, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(s.site.address ?? '',
                                style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                          ]),
                        ),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('${s.noteCount} notes',
                              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                          SyncBadge(syncStatus: s.site.syncStatus),
                        ]),
                      ]),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 6),
              AppButton('Add Site',
                  icon: Icons.add,
                  onPressed: () => Navigator.pushNamed(context, Routes.siteForm, arguments: c)),
            ]),
          );
        },
      );
}
