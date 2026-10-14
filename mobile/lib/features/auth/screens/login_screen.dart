import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/routes.dart';
import '../../../core/core.dart';
import '../../../widgets/widgets.dart';
import '../bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _google() {
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(const AuthGoogleLoginRequested());
  }

  void _login() {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
          AuthLoginRequested(email: _email.text.trim(), password: _pass.text),
        );
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              state.needsRestore ? Routes.restore : Routes.home,
              (_) => false,
            );
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          final error = state is AuthFailure
              ? state.message
              : state is AuthUnauthenticated
                  ? state.message
                  : null;

          return Scaffold(
            backgroundColor: context.pal.surface,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _form,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SizedBox(height: 40),
                    const AnimatedEntrance(
                      child: Center(child: Hero(tag: 'app_logo', child: AppLogo(size: 84))),
                    ),
                    const SizedBox(height: 10),
                    const AnimatedEntrance(
                      index: 1,
                      child: Center(
                          child: Text('Field Notes',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
                    ),
                    const SizedBox(height: 32),
                    const AnimatedEntrance(
                      index: 2,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Welcome back!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                        SizedBox(height: 4),
                        Text('Sign in to continue', style: TextStyle(color: AppColors.muted)),
                      ]),
                    ),
                    const SizedBox(height: 22),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      alignment: Alignment.topCenter,
                      child: error == null
                          ? const SizedBox(width: double.infinity)
                          : FormErrorBanner(error),
                    ),
                    AnimatedEntrance(
                      index: 3,
                      child: Column(children: [
                        AppField(
                          hint: 'Email',
                          icon: Icons.mail_outline,
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                        ),
                        PasswordField(
                          hint: 'Password',
                          controller: _pass,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Enter your password' : null,
                        ),
                      ]),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pushNamed(context, Routes.forgotPassword,
                            arguments: _email.text.trim().isEmpty ? null : _email.text.trim()),
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    AnimatedEntrance(
                      index: 4,
                      child: AppButton('Login', isLoading: loading, onPressed: _login),
                    ),
                    const SizedBox(height: 16),
                    const Row(children: [
                      Expanded(child: Divider()),
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or', style: TextStyle(color: AppColors.muted))),
                      Expanded(child: Divider()),
                    ]),
                    const SizedBox(height: 16),
                    AnimatedEntrance(
                      index: 5,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                        onPressed: loading ? null : _google,
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('G ',
                              style: TextStyle(
                                  color: Color(0xFFDB4437), fontWeight: FontWeight.w800, fontSize: 18)),
                          Text('Continue with Google'),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Center(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Text("Don't have an account? ", style: TextStyle(color: AppColors.muted)),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, Routes.register),
                          child: const Text('Register',
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ),
          );
        },
      );
}
