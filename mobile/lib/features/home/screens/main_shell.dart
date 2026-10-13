import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/session_helpers.dart';
import '../../../data/data.dart';
import '../../customers/bloc/customers_bloc.dart';
import '../../customers/screens/customers_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../sync/bloc/sync_bloc.dart';
import '../bloc/home_bloc.dart';
import 'home_tab.dart';

/// Bottom-navigation shell: Notes (home) | Customers | Settings.
/// Starts the background sync for the logged in user.
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
    context.read<SyncBloc>().add(SyncStarted(currentUserId(context)));
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
      ],
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            HomeTab(onGoCustomers: () => setState(() => _index = 1)),
            const CustomersScreen(),
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
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
