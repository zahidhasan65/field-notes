import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../../widgets/widgets.dart';
import '../bloc/forgot_password_bloc.dart';



class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;
  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailForm = GlobalKey<FormState>();
  final _resetForm = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _otp = TextEditingController();
  final _pass = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _sendOtp() {
    if (!_emailForm.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<ForgotPasswordBloc>().add(ForgotPasswordOtpRequested(_email.text));
  }

  void _reset() {
    if (!_resetForm.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<ForgotPasswordBloc>().add(
          ForgotPasswordResetSubmitted(otp: _otp.text, newPassword: _pass.text),
        );
  }

  void _showDemoOtp(String otp) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text('Demo OTP: $otp  (valid for 10 minutes)',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        action: SnackBarAction(
          label: 'COPY',
          onPressed: () => Clipboard.setData(ClipboardData(text: otp)),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
        listenWhen: (prev, curr) =>
            prev.otpNonce != curr.otpNonce || (!prev.resetDone && curr.resetDone),
        listener: (context, state) {
          if (state.resetDone) {
            final m = ScaffoldMessenger.of(context);
            Navigator.pop(context);
            m.hideCurrentSnackBar();
            m.showSnackBar(const SnackBar(
              content: Text('Password updated. Please log in with your new password.'),
              behavior: SnackBarBehavior.floating,
            ));
            return;
          }
          if (state.devOtp != null) {
            _showDemoOtp(state.devOtp!);
          } else {
            snack(context, 'If this email is registered, an OTP has been sent.');
          }
        },
        builder: (context, state) {
          final onOtpStep = state.step == ForgotStep.otp;

          return Scaffold(
            backgroundColor: context.pal.surface,
            appBar: AppBar(backgroundColor: context.pal.surface),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const AnimatedEntrance(child: Center(child: AppLogo(size: 64))),
                  const SizedBox(height: 22),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Column(
                      key: ValueKey(onOtpStep),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(onOtpStep ? 'Enter the OTP' : 'Forgot password?',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(
                          onOtpStep
                              ? 'We sent a 6 digit code for ${state.email}. Enter it with your new password.'
                              : 'Enter your account email and we will send you a one-time code (OTP).',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withOpacity(.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.info_outline, size: 18, color: AppColors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Demo mode: no email is sent. The OTP is shown in a message at the bottom of the screen.',
                          style: TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ]),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    alignment: Alignment.topCenter,
                    child: state.error == null
                        ? const SizedBox(width: double.infinity)
                        : FormErrorBanner(state.error!),
                  ),
                  if (!onOtpStep)
                    Form(
                      key: _emailForm,
                      child: Column(children: [
                        AppField(
                          hint: 'Email',
                          icon: Icons.mail_outline,
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                        ),
                        const SizedBox(height: 4),
                        AppButton('Send OTP', isLoading: state.isLoading, onPressed: _sendOtp),
                      ]),
                    )
                  else
                    Form(
                      key: _resetForm,
                      child: Column(children: [
                        AppField(
                          hint: '6 digit OTP',
                          icon: Icons.pin_outlined,
                          controller: _otp,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          validator: (v) =>
                              (v == null || v.length != 6) ? 'Enter the 6 digit OTP' : null,
                        ),
                        PasswordField(
                          hint: 'New password (min 8 characters)',
                          controller: _pass,
                          validator: (v) =>
                              (v == null || v.length < 8) ? 'Min 8 characters' : null,
                        ),
                        PasswordField(
                          hint: 'Confirm new password',
                          validator: (v) => v != _pass.text ? 'Passwords do not match' : null,
                        ),
                        const SizedBox(height: 4),
                        AppButton('Reset password',
                            isLoading: state.isLoading, onPressed: _reset),
                        const SizedBox(height: 8),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          TextButton(
                            onPressed: state.isLoading
                                ? null
                                : () => context
                                    .read<ForgotPasswordBloc>()
                                    .add(ForgotPasswordOtpRequested(state.email)),
                            child: const Text('Resend OTP'),
                          ),
                          TextButton(
                            onPressed: state.isLoading
                                ? null
                                : () => context
                                    .read<ForgotPasswordBloc>()
                                    .add(const ForgotPasswordEmailEditRequested()),
                            child: const Text('Change email'),
                          ),
                        ]),
                      ]),
                    ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          );
        },
      );
}
