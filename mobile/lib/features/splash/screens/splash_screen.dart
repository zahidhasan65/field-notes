import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/screens/auth_status_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _splashDuration = Duration(seconds: 2);

  late final AnimationController _progressController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: _splashDuration,
    )..forward();

    _timer = Timer(_splashDuration, _openAuth);
  }

  void _openAuth() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthStatusScreen()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FAFE),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            return ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  // =========================================================
                  // BACKGROUND
                  // =========================================================
                  const Positioned.fill(
                    child: ColoredBox(color: Color(0xFFF2FAFE)),
                  ),

                  // =========================================================
                  // EXACT CLIENT LANDSCAPE
                  // Starts around the same 47% point as reference UI.
                  // =========================================================
                  Positioned(
                    left: 0,
                    right: 0,
                    top: height * 0.473,
                    bottom: 0,
                    child: Image.asset(
                      'assets/images/splash_landscape.png',
                      width: width,
                      fit: BoxFit.fill,
                    ),
                  ),

                  // =========================================================
                  // LOGO + BRANDING
                  // =========================================================
                  Positioned(
                    top: height * 0.185,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/field_notes_app_logo_v2.png',
                          width: 72,
                          height: 82,
                          fit: BoxFit.contain,
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          'Field Notes',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            height: 1.1,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.45,
                          ),
                        ),

                        const SizedBox(height: 7),

                        const Text(
                          'Capture. Organize. Sync.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.1,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // =========================================================
                  // WHITE BOTTOM WAVE
                  // =========================================================
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: height * 0.145,
                    child: CustomPaint(painter: _BottomWavePainter()),
                  ),

                  // =========================================================
                  // FUNCTIONAL 2-SECOND PROGRESS
                  // =========================================================
                  Positioned(
                    left: width * 0.215,
                    right: width * 0.215,
                    bottom: height * 0.075,
                    child: AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) {
                        return Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD8E3EC),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _progressController.value,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.28)
      ..cubicTo(
        size.width * 0.16,
        size.height * 0.02,
        size.width * 0.34,
        size.height * 0.12,
        size.width * 0.50,
        size.height * 0.38,
      )
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.68,
        size.width * 0.84,
        size.height * 0.72,
        size.width,
        size.height * 0.22,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _BottomWavePainter oldDelegate) {
    return false;
  }
}
