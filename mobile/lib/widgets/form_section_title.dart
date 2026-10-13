import 'package:flutter/material.dart';
import '../core/core.dart';

class FormSectionTitle extends StatelessWidget {
  final IconData icon;
  final String text;
  const FormSectionTitle(this.icon, this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
      );
}
