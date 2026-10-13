import 'package:flutter/material.dart';
import '../core/core.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyState(this.icon, this.text, {super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(.08), shape: BoxShape.circle),
              child: Icon(icon, size: 38, color: AppColors.primary.withOpacity(.6)),
            ),
            const SizedBox(height: 14),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
          ]),
        ),
      );
}
