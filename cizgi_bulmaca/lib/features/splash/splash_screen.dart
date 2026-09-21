import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/settings_provider.dart';

/// Çizgi Bulmaca — Splash Ekranı
/// Logo animasyonu ile açılış ekranı (tek çizgi çizilerek belirir).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _lineAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.splashDuration,
    );

    _lineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward().then((_) {
      _navigateNext();
    });
  }

  void _navigateNext() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final settings = context.read<SettingsProvider>();
      if (settings.onboardingCompleted) {
        context.go('/home');
      } else {
        context.go('/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.splashGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Animasyonu — Tek çizgi çizilerek belirir
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(120, 120),
                    painter: _LogoPainter(progress: _lineAnimation.value),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Uygulama Adı
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  AppConstants.appName,
                  style: AppTextStyles.displayMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Çiz. Çöz. Kazan.',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Splash logo painter — tek çizgiyle "Ç" benzeri bir figür çizer
class _LogoPainter extends CustomPainter {
  final double progress;

  _LogoPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Basit bir path — continuous line figürü
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.4;

    // "Ç" harfi benzeri yuvarlak path
    path.moveTo(cx + r * 0.7, cy - r * 0.6);
    path.cubicTo(
      cx + r * 0.2, cy - r,
      cx - r, cy - r * 0.6,
      cx - r * 0.8, cy,
    );
    path.cubicTo(
      cx - r, cy + r * 0.6,
      cx + r * 0.2, cy + r,
      cx + r * 0.7, cy + r * 0.6,
    );
    // Ç altındaki kuyruk
    path.moveTo(cx, cy + r * 0.85);
    path.lineTo(cx + r * 0.2, cy + r * 1.15);

    // Path'i animasyonlu çiz
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      final extractPath = metric.extractPath(0, metric.length * progress);
      canvas.drawPath(extractPath, paint);
    }

    // Başlangıç noktası (dot)
    if (progress > 0) {
      final dotPaint = Paint()
        ..color = AppColors.secondary
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(cx + r * 0.7, cy - r * 0.6),
        5,
        dotPaint,
      );
    }

    // Bitiş noktası (geldiği yere kadar)
    if (progress > 0.1) {
      final endPaint = Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.fill;
      // Path üzerinde son pozisyonu bul
      for (final metric in pathMetrics) {
        final tangent = metric.getTangentForOffset(metric.length * progress);
        if (tangent != null) {
          canvas.drawCircle(tangent.position, 5, endPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) => oldDelegate.progress != progress;
}
