import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/routes.dart';
import '../../../app/session_helpers.dart';
import '../../../core/core.dart';
import '../../../data/data.dart';
import '../../../widgets/widgets.dart';
import '../bloc/sites_bloc.dart';

class SitesScreen extends StatelessWidget {
  final CustomerLocal? customer;
  const SitesScreen({super.key, this.customer});

  Future<void> _delete(BuildContext context, SiteLocal s) async {
    final impact = await context.read<SiteRepository>().deleteImpact(s.id);
    if (!context.mounted) return;
    final details = impact.notes == 0
        ? null
        : 'This will also delete ${impact.notes} note${impact.notes == 1 ? '' : 's'}.';
    if (!await confirmDelete(context, 'site', details: details)) return;
    if (context.mounted) context.read<SitesBloc>().add(SiteDeleteRequested(s));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(customer == null ? 'Sites' : '${customer!.name} - Sites')),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Column(children: [
            const OfflineBanner(),
            SearchBox(
              hint: 'Search sites...',
              onChanged: (v) => context.read<SitesBloc>().add(SitesQueryChanged(v)),
            ),
            const SizedBox(height: 12),
            AppButton('Add Site',
                icon: Icons.add,
                onPressed: () =>
                    Navigator.pushNamed(context, Routes.siteForm, arguments: customer)),
            const SizedBox(height: 14),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => refreshWithSync(context),
                child: BlocBuilder<SitesBloc, SitesState>(
                  builder: (context, state) {
                    if (state.status == LoadStatus.loading) {
                      return ListView(children: const [ListSkeleton()]);
                    }
                    if (state.status == LoadStatus.failure) {
                      return ListView(children: [
                        SizedBox(
                          height: 320,
                          child: ErrorState(
                            message: "We couldn't load the sites.",
                            onRetry: () => context.read<SitesBloc>().add(const SitesStarted()),
                          ),
                        ),
                      ]);
                    }
                    if (state.sites.isEmpty) {
                      return ListView(children: const [
                        SizedBox(height: 320, child: EmptyState(Icons.location_city, 'No sites found')),
                      ]);
                    }
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: state.sites.length,
                      itemBuilder: (_, i) {
                        final v = state.sites[i];
                        final s = v.site;
                        return AnimatedEntrance(
                          index: i,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AppCard(
                              onTap: () => Navigator.pushNamed(context, Routes.notes, arguments: s),
                              padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                              child: Row(children: [
                                Avatar(s.siteName),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(s.siteName,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                    Text(v.customerName,
                                        style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                                  ]),
                                ),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Text('${v.noteCount} notes',
                                      style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                                  SyncBadge(syncStatus: s.syncStatus),
                                ]),
                                PopupMenuButton<String>(
                                  onSelected: (value) => value == 'edit'
                                      ? Navigator.pushNamed(context, Routes.siteForm, arguments: s)
                                      : _delete(context, s),
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                                  ],
                                ),
                              ]),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ]),
        ),
      );
}
