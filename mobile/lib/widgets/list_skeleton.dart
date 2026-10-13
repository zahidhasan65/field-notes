import 'package:flutter/material.dart';
import '../core/core.dart';

/// Pulsing placeholder cards shown while a list is loading.
class ListSkeleton extends StatefulWidget {
  final int count;
  const ListSkeleton({super.key, this.count = 4});

  @override
  State<ListSkeleton> createState() => _ListSkeletonState();
}

class _ListSkeletonState extends State<ListSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _block(double w, double h) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(color: const Color(0xFFE8EDF5), borderRadius: BorderRadius.circular(6)),
      );

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: .45, end: 1).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
        child: Column(
          children: List.generate(
            widget.count,
            (_) => Container(
              height: 78,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                Container(width: 48, height: 48, decoration: const BoxDecoration(color: Color(0xFFE8EDF5), shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _block(140, 12),
                    const SizedBox(height: 8),
                    _block(90, 10),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      );
}
