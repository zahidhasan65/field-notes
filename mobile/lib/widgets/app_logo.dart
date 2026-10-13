import 'package:flutter/material.dart';
import '../core/core.dart';

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) => Image.asset(
        Assets.logo,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(size * 0.3),
          ),
          child: Icon(Icons.location_on, color: Colors.white, size: size * 0.6),
        ),
      );
}
