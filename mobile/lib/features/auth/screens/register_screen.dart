import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/routes.dart';
import '../../../core/core.dart';
import '../../../widgets/widgets.dart';
import '../bloc/auth_bloc.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _register() {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(AuthRegisterRequested(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _pass.text,
        ));
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
          final error = state is AuthFailure ? state.message : null;

          return Scaffold(
            backgroundColor: context.pal.surface,
            appBar: AppBar(backgroundColor: context.pal.surface),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _form,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const AnimatedEntrance(child: Center(child: AppLogo(size: 72))),
                    const SizedBox(height: 8),
                    const AnimatedEntrance(
                      index: 1,
                      child: Center(
                          child: Text('Field Notes',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
                    ),
                    const SizedBox(height: 26),
                    const AnimatedEntrance(
                      index: 2,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Create Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                        SizedBox(height: 4),
                        Text('Join us to start managing your field notes',
                            style: TextStyle(color: AppColors.muted)),
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
                            hint: 'Full Name',
                            icon: Icons.person_outline,
                            controller: _name,
                            isRequired: true),
                        AppField(
                          hint: 'Email',
                          icon: Icons.mail_outline,
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                        ),
                        // the backend requires at least 8 characters
                        PasswordField(
                          hint: 'Password (min 8 characters)',
                          controller: _pass,
                          validator: (v) =>
                              (v == null || v.length < 8) ? 'Min 8 characters' : null,
                        ),
                        PasswordField(
                          hint: 'Confirm Password',
                          validator: (v) => v != _pass.text ? 'Passwords do not match' : null,
                        ),
                      ]),
                    ),
                    const SizedBox(height: 4),
                    AnimatedEntrance(
                        index: 4,
                        child: AppButton('Register', isLoading: loading, onPressed: _register)),
                    const SizedBox(height: 18),
                    Center(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Text('Already have an account? ',
                            style: TextStyle(color: AppColors.muted)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text('Login',
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
