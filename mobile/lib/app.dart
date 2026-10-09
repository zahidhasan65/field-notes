import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/network/api_service.dart';
import 'core/storage/session_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/screens/splash_screen.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/data/remote/auth_remote_data_source.dart';
import 'features/auth/data/remote/auth_remote_data_source_impl.dart';
import 'features/auth/repositories/auth_repository.dart';

class FieldNotesApp extends StatelessWidget {
  const FieldNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<ApiService>(
      create: (_) => ApiService(),
      child: RepositoryProvider<SessionStorage>(
        create: (_) => SessionStorage(),
        child: RepositoryProvider<AuthRemoteDataSource>(
          create: (context) =>
              AuthRemoteDataSourceImpl(apiService: context.read<ApiService>()),
          child: RepositoryProvider<AuthRepository>(
            create: (context) => AuthRepositoryImpl(
              remoteDataSource: context.read<AuthRemoteDataSource>(),
              sessionStorage: context.read<SessionStorage>(),
            ),
            child: BlocProvider(
              create: (context) =>
                  AuthBloc(authRepository: context.read<AuthRepository>())
                    ..add(const AuthStarted()),
              child: MaterialApp(
                title: 'Field Notes',
                debugShowCheckedModeBanner: false,
                  theme: AppTheme.light(),
                home: const SplashScreen(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

