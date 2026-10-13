import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  final bool isLoading;
  final IconData? icon;

  const AppButton(
    this.label, {
    super.key,
    this.onPressed,
    this.outlined = false,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content = icon == null
        ? Text(label, key: const ValueKey('content'))
        : Row(key: const ValueKey('content'), mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(label),
          ]);
    final Widget child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: isLoading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: outlined ? null : Colors.white,
              ),
            )
          : content,
    );
    final VoidCallback? handler = isLoading ? () {} : onPressed;
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: outlined
          ? OutlinedButton(onPressed: handler, child: child)
          : FilledButton(onPressed: handler, child: child),
    );
  }
}
