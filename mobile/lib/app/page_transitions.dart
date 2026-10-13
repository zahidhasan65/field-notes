import 'package:flutter/material.dart';

class FadeSlideRoute<T> extends PageRouteBuilder<T> {
  FadeSlideRoute({required WidgetBuilder builder, super.settings})
      : super(
          pageBuilder: (context, _, __) => builder(context),
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          transitionsBuilder: (context, animation, secondary, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(curved),
                child: child,
              ),
            );
          },
        );
}
