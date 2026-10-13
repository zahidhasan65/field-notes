import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/routes.dart';
import '../../../app/session_helpers.dart';
import '../../../core/core.dart';
import '../../../widgets/widgets.dart';
import '../bloc/customers_bloc.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Customers', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            const OfflineBanner(),
            SearchBox(
              hint: 'Search customers...',
              onChanged: (v) => context.read<CustomersBloc>().add(CustomersQueryChanged(v)),
            ),
            const SizedBox(height: 12),
            AppButton('Add Customer',
                icon: Icons.add,
                onPressed: () => Navigator.pushNamed(context, Routes.customerForm)),
            const SizedBox(height: 14),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => refreshWithSync(context),
                child: BlocBuilder<CustomersBloc, CustomersState>(
                  builder: (context, state) {
                    Widget body;
                    if (state.status == LoadStatus.loading) {
                      body = const ListSkeleton();
                    } else if (state.status == LoadStatus.failure) {
                      body = SizedBox(
                        height: 320,
                        child: ErrorState(
                          message: "We couldn't load your customers.",
                          onRetry: () => context.read<CustomersBloc>().add(const CustomersStarted()),
                        ),
                      );
                    } else if (state.customers.isEmpty) {
                      body = SizedBox(
                        height: 320,
                        child: EmptyState(
                          Icons.people_outline,
                          state.query.isEmpty ? 'No customers yet. Add your first one.' : 'No customers found',
                        ),
                      );
                    } else {
                      body = Column(
                        children: List.generate(state.customers.length, (i) {
                          final v = state.customers[i];
                          final c = v.customer;
                          return AnimatedEntrance(
                            index: i,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: AppCard(
                                onTap: () => Navigator.pushNamed(context, Routes.customerDetail,
                                    arguments: c.id),
                                child: Row(children: [
                                  Avatar(c.name),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(c.name,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                      Text(c.contactPerson ?? c.phone ?? c.email ?? '',
                                          style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                                    ]),
                                  ),
                                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                    Text('${v.siteCount} sites',
                                        style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                                    SyncBadge(syncStatus: c.syncStatus),
                                  ]),
                                  const Icon(Icons.chevron_right, color: AppColors.muted),
                                ]),
                              ),
                            ),
                          );
                        }),
                      );
                    }
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [body],
                    );
                  },
                ),
              ),
            ),
          ]),
        ),
      );
}
