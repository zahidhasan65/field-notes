import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../home/bloc/home_bloc.dart';
import '../../home/bloc/home_event.dart';
import '../../home/screens/home_screen.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import 'login_screen.dart';

class AuthStatusScreen extends StatelessWidget {
  const AuthStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading || state is AuthInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is AuthAuthenticated) {
          return BlocProvider<HomeBloc>(
            key: ValueKey(state.user.id),
            create: (_) =>
                HomeBloc(userId: state.user.id)..add(const HomeLoadRequested()),
            child: const HomeScreen(),
          );
        }

        if (state is AuthUnauthenticated || state is AuthError) {
          return const LoginScreen();
        }

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
