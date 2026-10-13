import 'package:flutter/material.dart';

class AnimatedEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  const AnimatedEntrance({super.key, required this.child, this.index = 0});

  @override
  State<AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends State<AnimatedEntrance> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 55 * widget.index.clamp(0, 10)), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _a,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, .12), end: Offset.zero).animate(_a),
          child: widget.child,
        ),
      );
}
