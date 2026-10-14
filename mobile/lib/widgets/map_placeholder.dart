import 'package:flutter/material.dart';
import '../core/core.dart';

class MapPlaceholder extends StatelessWidget {
  final double height;
  const MapPlaceholder({super.key, this.height = 120});

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF223049)
              : const Color(0xFFE6EEF6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.pal.border),
        ),
        child: Stack(alignment: Alignment.center, children: [
          Icon(Icons.map_outlined, size: height * 0.8, color: Colors.white.withOpacity(.8)),
          const Icon(Icons.location_on, color: AppColors.red, size: 34),
        ]),
      );
}
