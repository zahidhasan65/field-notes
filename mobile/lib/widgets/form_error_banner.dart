import 'package:flutter/material.dart';
import '../core/core.dart';

class FormErrorBanner extends StatelessWidget {
  final String message;
  const FormErrorBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.red.withOpacity(.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.red.withOpacity(.3)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.error_outline, color: AppColors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: AppColors.red, fontSize: 13))),
        ]),
      );
}
