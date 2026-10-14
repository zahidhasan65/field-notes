import 'package:flutter/material.dart';
import '../core/core.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: context.pal.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.pal.border),
          boxShadow: const [
            BoxShadow(color: Color(0x0D0F172A), blurRadius: 14, offset: Offset(0, 5)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      );
}
