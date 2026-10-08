import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7FF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            final logoSize = (width * 0.25).clamp(72.0, 110.0);

            return Stack(
              children: [
                // Sky background.
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFE8F7FF),
                          Color(0xFFF8FCFF),
                        ],
                      ),
                    ),
                  ),
                ),

                // Landscape.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: height * 0.54,
                  child: Image.asset(
                    'assets/images/splash_landscape.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                  ),
                ),

                // Soft white transition between content and landscape.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: height * 0.47,
                  height: height * 0.18,
                  child: CustomPaint(
                    painter: _SplashWavePainter(),
                  ),
                ),

                // Main branding.
                Positioned(
                  top: height * 0.12,
                  left: 24,
                  right: 24,
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/field_notes_app_logo_v2.png',
                        width: logoSize,
                        height: logoSize,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Field Notes',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Capture. Organize. Sync.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySecondary,
                      ),
                    ],
                  ),
                ),

                // Loading indicator.
                Positioned(
                  left: width * 0.20,
                  right: width * 0.20,
                  bottom: height * 0.055,
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SizedBox(
                          height: 6,
                          child: LinearProgressIndicator(
                            value: _progressController.value,
                            backgroundColor: const Color(0xFFD9E5EF),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SplashWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.42)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.05,
        size.width * 0.50,
        size.height * 0.40,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.75,
        size.width,
        size.height * 0.28,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      path,
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
