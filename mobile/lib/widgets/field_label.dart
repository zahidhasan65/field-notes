import 'package:flutter/material.dart';
import '../core/core.dart';

class FieldLabel extends StatelessWidget {
  final String text;
  final bool isRequired;
  const FieldLabel(this.text, {super.key, this.isRequired = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text.rich(TextSpan(
          text: text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text),
          children: [
            if (isRequired) const TextSpan(text: ' *', style: TextStyle(color: AppColors.red)),
          ],
        )),
      );
}
