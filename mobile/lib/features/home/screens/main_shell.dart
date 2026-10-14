import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/session_helpers.dart';
import '../../../data/data.dart';
import '../../customers/bloc/customers_bloc.dart';
import '../../customers/screens/customers_screen.dart';
import '../../notifications/bloc/notifications_bloc.dart';
import '../../profile/bloc/profile_bloc.dart';
import '../../settings/screens/settings_screen.dart';
import '../../sites/bloc/sites_bloc.dart';
import '../../sites/screens/sites_screen.dart';
import '../../sync/bloc/sync_bloc.dart';
import '../bloc/home_bloc.dart';
import 'home_tab.dart';


class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    final userId = currentUserId(context);
    context.read<SyncBloc>().add(SyncStarted(userId));
    context.read<NotificationsBloc>().add(NotificationsStarted(userId));
    context.read<ProfileBloc>().add(ProfileStarted(userId));
  }

  @override
  Widget build(BuildContext context) {
    final userId = currentUserId(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (c) => HomeBloc(
            userId: userId,
            customers: c.read<CustomerRepository>(),
            sites: c.read<SiteRepository>(),
            notes: c.read<FieldNoteRepository>(),
          ),
        ),
        BlocProvider(
          create: (c) => CustomersBloc(
            repository: c.read<CustomerRepository>(),
            userId: userId,
          ),
        ),
        BlocProvider(
          create: (c) => SitesBloc(
            repository: c.read<SiteRepository>(),
            userId: userId,
          ),
        ),
      ],
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            HomeTab(
              onGoCustomers: () => setState(() => _index = 1),
              onGoSites: () => setState(() => _index = 2),
            ),
            const CustomersScreen(),
            const SitesScreen(embedded: true),
            const SettingsScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.description_outlined),
                selectedIcon: Icon(Icons.description),
                label: 'Notes'),
            NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: 'Customers'),
            NavigationDestination(
                icon: Icon(Icons.location_city_outlined),
                selectedIcon: Icon(Icons.location_city),
                label: 'Sites'),
            NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
