import 'package:flutter/material.dart';
import '../core/core.dart';

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

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    Widget block(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(color: pal.border, borderRadius: BorderRadius.circular(6)),
        );

    return FadeTransition(
      opacity: Tween<double>(begin: .45, end: 1).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: Column(
        children: List.generate(
          widget.count,
          (_) => Container(
            height: 78,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: pal.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: pal.border),
            ),
            child: Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: pal.border, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  block(140, 12),
                  const SizedBox(height: 8),
                  block(90, 10),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
