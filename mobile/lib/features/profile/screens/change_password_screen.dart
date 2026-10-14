import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../../widgets/widgets.dart';
import '../bloc/profile_bloc.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<ProfileBloc>().add(ProfilePasswordSubmitted(
          currentPassword: _current.text,
          newPassword: _new.text,
        ));
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<ProfileBloc, ProfileState>(
        listenWhen: (prev, curr) =>
            prev.nonce != curr.nonce && curr.action == ProfileAction.password,
        listener: (context, state) {
          if (state.error == null) {
            final m = ScaffoldMessenger.of(context);
            Navigator.pop(context);
            m.showSnackBar(const SnackBar(
              content: Text('Password changed'),
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
        builder: (context, state) {
          final error = state.action == ProfileAction.password ? state.error : null;
          return Scaffold(
            appBar: AppBar(title: const Text('Change password')),
            body: Form(
              key: _form,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                AnimatedEntrance(
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const FormSectionTitle(Icons.lock_reset, 'Update your password'),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        alignment: Alignment.topCenter,
                        child: error == null
                            ? const SizedBox(width: double.infinity)
                            : FormErrorBanner(error),
                      ),
                      const FieldLabel('Current password', isRequired: true),
                      PasswordField(
                        hint: 'Current password',
                        controller: _current,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Enter your current password' : null,
                      ),
                      const FieldLabel('New password', isRequired: true),
                      PasswordField(
                        hint: 'At least 8 characters',
                        controller: _new,
                        validator: (v) =>
                            (v == null || v.length < 8) ? 'Min 8 characters' : null,
                      ),
                      const FieldLabel('Confirm new password', isRequired: true),
                      PasswordField(
                        hint: 'Repeat the new password',
                        validator: (v) => v != _new.text ? 'Passwords do not match' : null,
                      ),
                      const Text(
                        'Forgot your current password? Log out and use "Forgot password" on the login screen.',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                      child: AppButton('Cancel', outlined: true, onPressed: () => Navigator.pop(context))),
                  const SizedBox(width: 12),
                  Expanded(child: AppButton('Update', isLoading: state.isBusy, onPressed: _submit)),
                ]),
              ]),
            ),
          );
        },
      );
}
