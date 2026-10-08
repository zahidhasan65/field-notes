import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';

class AuthStatusScreen extends StatelessWidget {
  const AuthStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AuthAuthenticated) {
            return const Center(
              child: Text('Authenticated', style: TextStyle(fontSize: 24)),
            );
          }

          if (state is AuthUnauthenticated) {
            return const Center(
              child: Text('Not Authenticated', style: TextStyle(fontSize: 24)),
            );
          }

          if (state is AuthError) {
            return Center(
              child: Text(state.message, style: const TextStyle(fontSize: 18)),
            );
          }

          return const Center(
            child: Text('Field Notes', style: TextStyle(fontSize: 24)),
          );
        },
      ),
    );
  }
}
