import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/core.dart';
import 'field_label.dart';

class AppField extends StatelessWidget {
  final String label, hint;
  final IconData? icon;
  final int maxLines;
  final bool isRequired;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;
  final bool obscure;
  final List<TextInputFormatter>? inputFormatters;

  const AppField({
    super.key,
    this.label = '',
    required this.hint,
    this.icon,
    this.maxLines = 1,
    this.isRequired = false,
    this.controller,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.suffix,
    this.obscure = false,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (label.isNotEmpty) FieldLabel(label, isRequired: isRequired),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            obscureText: obscure,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            validator: validator ??
                (isRequired ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: icon == null ? null : Icon(icon, size: 20, color: AppColors.muted),
              suffixIcon: suffix,
            ),
          ),
        ]),
      );
}
