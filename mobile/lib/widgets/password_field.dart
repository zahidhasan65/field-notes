import 'package:flutter/material.dart';
import '../core/core.dart';
import 'app_field.dart';

class PasswordField extends StatefulWidget {
  final String hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  const PasswordField({super.key, required this.hint, this.controller, this.validator});

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hide = true;

  @override
  Widget build(BuildContext context) => AppField(
        hint: widget.hint,
        icon: Icons.lock_outline,
        controller: widget.controller,
        obscure: _hide,
        validator: widget.validator ??
            (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
        suffix: IconButton(
          icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 20, color: AppColors.muted),
          onPressed: () => setState(() => _hide = !_hide),
        ),
      );
}
