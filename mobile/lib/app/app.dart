import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/core.dart';
import '../data/data.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/settings/bloc/settings_bloc.dart';
import '../features/sync/bloc/sync_bloc.dart';
import '../services/location_service.dart';
import '../services/permission_service.dart';
import '../services/photo_service.dart';
import 'app_dependencies.dart';
import 'routes.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class FieldNotesApp extends StatelessWidget {
  final AppDependencies deps;
  const FieldNotesApp({super.key, required this.deps});

  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: deps.customers),
          RepositoryProvider.value(value: deps.sites),
          RepositoryProvider.value(value: deps.notes),
          RepositoryProvider.value(value: deps.settings),
          RepositoryProvider.value(value: deps.localData),
          RepositoryProvider.value(value: deps.engine),
          RepositoryProvider.value(value: deps.permissions),
          RepositoryProvider<AuthRepository>.value(value: deps.auth),
          RepositoryProvider<ConnectivityService>.value(value: deps.connectivity),
          RepositoryProvider<LocationService>.value(value: deps.location),
          RepositoryProvider<PhotoService>.value(value: deps.photoService),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => AuthBloc(
                repository: deps.auth,
                connectivity: deps.connectivity,
                google: deps.googleAuth,
              )..add(const AuthStarted()),
            ),
            BlocProvider(
              create: (_) => SyncBloc(
                engine: deps.engine,
                connectivity: deps.connectivity,
                queue: deps.queue,
                settings: deps.settings,
              ),
            ),
            BlocProvider(create: (_) => SettingsBloc(repository: deps.settings)),
          ],
          child: MultiBlocListener(
            listeners: [
              // Logged out (button, cleared data or expired session) -> back to Login.
              BlocListener<AuthBloc, AuthState>(
                listenWhen: (prev, curr) =>
                    prev is AuthAuthenticated && curr is AuthUnauthenticated,
                listener: (context, state) {
                  context.read<SyncBloc>().add(const SyncStopped());
                  navigatorKey.currentState
                      ?.pushNamedAndRemoveUntil(Routes.login, (_) => false);
                },
              ),
              // The server rejected our token while syncing.
              BlocListener<SyncBloc, SyncBlocState>(
                listenWhen: (prev, curr) => !prev.sessionExpired && curr.sessionExpired,
                listener: (context, state) =>
                    context.read<AuthBloc>().add(const AuthSessionExpired()),
              ),
            ],
            child: MaterialApp(
              title: 'Field Notes',
              navigatorKey: navigatorKey,
              debugShowCheckedModeBanner: false,
              theme: buildTheme(),
              initialRoute: Routes.splash,
              onGenerateRoute: AppRouter.generate,
            ),
          ),
        ),
      );
}
