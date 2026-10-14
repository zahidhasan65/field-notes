import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/routes.dart';
import '../../core/core.dart';
import '../../widgets/widgets.dart';
import '../auth/bloc/auth_bloc.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));

  Animation<double> _interval(double a, double b, [Curve curve = Curves.easeOutCubic]) =>
      CurvedAnimation(parent: _c, curve: Interval(a, b, curve: curve));

  late final _land = _interval(0.0, 0.45);
  late final _logo = _interval(0.12, 0.55, Curves.easeOutBack);
  late final _title = _interval(0.40, 0.70);
  late final _tagline = _interval(0.55, 0.85);

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(_continue);
  }

  Future<void> _continue() async {
    if (!mounted) return;
    final bloc = context.read<AuthBloc>();
    final state = bloc.state is AuthInitial
        ? await bloc.stream.firstWhere((s) => s is! AuthInitial)
        : bloc.state;
    if (!mounted) return;

    final route = state is AuthAuthenticated
        ? (state.needsRestore ? Routes.restore : Routes.home)
        : Routes.login;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Stack(
      fit: StackFit.expand, // FIX: Stack puro screen jure thakbe
      children: [
        // Full screen background image
        Positioned.fill(
          child: FadeTransition(
            opacity: _land,
            child: Image.asset(
              Assets.splashLandscape,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Color(0xFFD9ECDD)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                ScaleTransition(
                  scale: Tween<double>(begin: .55, end: 1).animate(_logo),
                  child: FadeTransition(
                    opacity: CurvedAnimation(parent: _c, curve: const Interval(0.12, 0.35)),
                    child: const Hero(tag: 'app_logo', child: AppLogo(size: 120)),
                  ),
                ),
                const SizedBox(height: 18),
                FadeTransition(
                  opacity: _title,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, .4), end: Offset.zero).animate(_title),
                    child: const Text('Field Notes',
                        style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.text)),
                  ),
                ),
                const SizedBox(height: 6),
                FadeTransition(
                  opacity: _tagline,
                  child: const Text('Capture. Organize. Sync.',
                      style: TextStyle(color: AppColors.muted, fontSize: 15, letterSpacing: .4)),
                ),
                const Spacer(flex: 6),
                AnimatedBuilder(
                  animation: _c,
                  builder: (_, __) => Container(
                    width: 170,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(value: _c.value, minHeight: 5),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}