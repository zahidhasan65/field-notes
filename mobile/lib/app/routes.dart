import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/data.dart';
import '../core/core.dart';
import '../features/auth/bloc/forgot_password_bloc.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/customers/bloc/customer_detail_bloc.dart';
import '../features/customers/bloc/customer_form_bloc.dart';
import '../features/customers/screens/add_customer_screen.dart';
import '../features/customers/screens/customer_detail_screen.dart';
import '../features/home/screens/main_shell.dart';
import '../features/notes/bloc/note_detail_bloc.dart';
import '../features/notes/bloc/note_form_bloc.dart';
import '../features/notes/bloc/notes_bloc.dart';
import '../features/notes/screens/add_note_screen.dart';
import '../features/notes/screens/note_detail_screen.dart';
import '../features/notes/screens/notes_screen.dart';
import '../features/restore/bloc/restore_bloc.dart';
import '../features/restore/screens/restore_data_screen.dart';
import '../features/sites/bloc/site_form_bloc.dart';
import '../features/sites/bloc/sites_bloc.dart';
import '../features/sites/screens/add_site_screen.dart';
import '../features/sites/screens/sites_screen.dart';
import '../features/splash/splash_screen.dart';
import 'page_transitions.dart';
import 'session_helpers.dart';

class Routes {
  Routes._();

  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password'; // arg: String? email
  static const restore = '/restore';
  static const home = '/home';
  static const customerForm = '/customer/form'; // arg: CustomerLocal? (edit)
  static const customerDetail = '/customer'; // arg: String customerId
  static const sites = '/sites'; // arg: CustomerLocal? (filter)
  static const siteForm = '/site/form'; // arg: SiteLocal (edit) | CustomerLocal (preselect)
  static const notes = '/notes'; // arg: SiteLocal? (filter)
  static const noteForm = '/note/form'; // arg: FieldNoteLocal (edit) | SiteLocal (preselect)
  static const noteDetail = '/note'; // arg: String noteId
}

class AppRouter {
  AppRouter._();

  static Route<dynamic> generate(RouteSettings s) {
    final a = s.arguments;

    final WidgetBuilder builder = switch (s.name) {
      Routes.splash => (_) => const SplashScreen(),
      Routes.login => (_) => const LoginScreen(),
      Routes.register => (_) => const RegisterScreen(),
      Routes.forgotPassword => (c) => BlocProvider(
            create: (c) => ForgotPasswordBloc(
              repository: c.read<AuthRepository>(),
              connectivity: c.read<ConnectivityService>(),
              initialEmail: a as String?,
            ),
            child: ForgotPasswordScreen(initialEmail: a as String?),
          ),
      Routes.restore => (c) => BlocProvider(
            create: (c) => RestoreBloc(engine: c.read<SyncEngine>())
              ..add(RestoreStarted(currentUserId(c))),
            child: const RestoreDataScreen(),
          ),
      Routes.home => (_) => const MainShell(),
      Routes.customerForm => (c) {
          final existing = a as CustomerLocal?;
          return BlocProvider(
            create: (c) => CustomerFormBloc(
              repository: c.read<CustomerRepository>(),
              userId: currentUserId(c),
              existing: existing,
            ),
            child: AddCustomerScreen(customer: existing),
          );
        },
      Routes.customerDetail => (c) => BlocProvider(
            create: (c) => CustomerDetailBloc(
              customerId: a as String,
              userId: currentUserId(c),
              customers: c.read<CustomerRepository>(),
              sitesRepository: c.read<SiteRepository>(),
            ),
            child: const CustomerDetailScreen(),
          ),
      Routes.sites => (c) {
          final customer = a as CustomerLocal?;
          return BlocProvider(
            create: (c) => SitesBloc(
              repository: c.read<SiteRepository>(),
              userId: currentUserId(c),
              customerId: customer?.id,
            ),
            child: SitesScreen(customer: customer),
          );
        },
      Routes.siteForm => (c) {
          final existing = a is SiteLocal ? a : null;
          final customer = a is CustomerLocal ? a : null;
          return BlocProvider(
            create: (c) => SiteFormBloc(
              repository: c.read<SiteRepository>(),
              userId: currentUserId(c),
              existing: existing,
            ),
            child: AddSiteScreen(site: existing, customer: customer),
          );
        },
      Routes.notes => (c) {
          final site = a as SiteLocal?;
          return BlocProvider(
            create: (c) => NotesBloc(
              notesRepository: c.read<FieldNoteRepository>(),
              sitesRepository: c.read<SiteRepository>(),
              userId: currentUserId(c),
              initialSiteId: site?.id,
            ),
            child: const NotesScreen(),
          );
        },
      Routes.noteForm => (c) {
          final existing = a is FieldNoteLocal ? a : null;
          final site = a is SiteLocal ? a : null;
          return BlocProvider(
            create: (c) => NoteFormBloc(
              repository: c.read<FieldNoteRepository>(),
              userId: currentUserId(c),
              existing: existing,
            ),
            child: AddNoteScreen(note: existing, site: site),
          );
        },
      Routes.noteDetail => (c) => BlocProvider(
            create: (c) => NoteDetailBloc(
              noteId: a as String,
              userId: currentUserId(c),
              repository: c.read<FieldNoteRepository>(),
            ),
            child: const NoteDetailScreen(),
          ),
      _ => (_) => const LoginScreen(),
    };

    return FadeSlideRoute(builder: builder, settings: s);
  }
}
