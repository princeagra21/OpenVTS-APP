import 'dart:math' as math;

import 'package:flutter/material.dart';

class AnimatedOrbitLoginBackground extends StatefulWidget {
  const AnimatedOrbitLoginBackground({super.key});

  @override
  State<AnimatedOrbitLoginBackground> createState() =>
      _AnimatedOrbitLoginBackgroundState();
}

class _AnimatedOrbitLoginBackgroundState
    extends State<AnimatedOrbitLoginBackground>
    with TickerProviderStateMixin {
  late final AnimationController _orbitController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_orbitController, _pulseController]),
      builder: (context, _) {
        return CustomPaint(
          painter: OrbitLoginBackgroundPainter(
            orbitValue: _orbitController.value,
            pulseValue: _pulseController.value,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class OrbitLoginBackgroundPainter extends CustomPainter {
  final double orbitValue;
  final double pulseValue;

  const OrbitLoginBackgroundPainter({
    required this.orbitValue,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final rect = Offset.zero & size;

    paint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF4F6F8), Color(0xFFE9EDF2)],
    ).createShader(rect);
    canvas.drawRect(rect, paint);

    final topGlowCenter = Offset(size.width * 0.5, size.height * 0.08);
    final topGlowRadius = size.width * 0.85;
    paint.shader =
        RadialGradient(
          center: Alignment.topCenter,
          radius: 1.0,
          colors: [
            Colors.white.withOpacity(0.85),
            Colors.white.withOpacity(0.0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(
          Rect.fromCircle(center: topGlowCenter, radius: topGlowRadius),
        );
    canvas.drawCircle(topGlowCenter, topGlowRadius, paint);

    final isTablet = size.width >= 700;
    final isShort = size.height < 700;
    final globeCenter = Offset(
      size.width * 0.50,
      isShort ? size.height * 0.20 : size.height * 0.22,
    );
    final globeRadius = isTablet
        ? math.min(size.width * 0.36, 420.0)
        : size.width * (isShort ? 0.42 : 0.48);

    final shadowPaint = Paint()
      ..color = const Color(0xFFCBD5E1).withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawCircle(
      globeCenter.translate(0, globeRadius * 0.10),
      globeRadius * 1.03,
      shadowPaint,
    );

    final globeRect = Rect.fromCircle(center: globeCenter, radius: globeRadius);
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFFFFFFFF).withOpacity(0.92),
        const Color(0xFFE8EEF3).withOpacity(0.88),
        const Color(0xFFCBD5E1).withOpacity(0.72),
        const Color(0xFF94A3B8).withOpacity(0.36),
      ],
      stops: const [0.0, 0.45, 0.78, 1.0],
    ).createShader(globeRect);
    canvas.drawCircle(globeCenter, globeRadius, paint);

    paint.shader =
        RadialGradient(
          colors: [
            Colors.white.withOpacity(0.40),
            Colors.white.withOpacity(0.0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(
          Rect.fromCircle(
            center: globeCenter.translate(
              globeRadius * 0.38,
              -globeRadius * 0.24,
            ),
            radius: globeRadius * 0.66,
          ),
        );
    canvas.drawCircle(globeCenter, globeRadius, paint);

    paint.shader =
        RadialGradient(
          colors: [
            const Color(0xFF475569).withOpacity(0.16),
            Colors.transparent,
          ],
          stops: const [0.0, 1.0],
        ).createShader(
          Rect.fromCircle(
            center: globeCenter.translate(
              -globeRadius * 0.32,
              globeRadius * 0.38,
            ),
            radius: globeRadius * 0.86,
          ),
        );
    canvas.drawCircle(globeCenter, globeRadius, paint);

    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withOpacity(0.64);
    final orbitRadii = <double>[
      globeRadius * 1.04,
      globeRadius * 1.13,
      globeRadius * 1.22,
      globeRadius * 1.17,
      globeRadius * 1.09,
    ];
    final orbitScales = <double>[0.55, 0.48, 0.62, 0.40, 0.70];
    final orbitAngles = <double>[
      orbitValue * math.pi * 2,
      orbitValue * math.pi * 2 + 0.9,
      -orbitValue * math.pi * 2 + 1.7,
      orbitValue * math.pi * 2 + 2.8,
      -orbitValue * math.pi * 2 + 0.4,
    ];

    for (var i = 0; i < orbitRadii.length; i++) {
      canvas.save();
      canvas.translate(globeCenter.dx, globeCenter.dy);
      canvas.rotate(orbitAngles[i]);
      canvas.scale(1, orbitScales[i]);
      canvas.drawCircle(Offset.zero, orbitRadii[i], orbitPaint);
      canvas.restore();
    }

    final dotBaseRadius = 3.0 + (pulseValue * 2.0);
    final dotGlowSigma = 10.0 + (pulseValue * 8.0);
    final dots = <(int orbitIndex, double t)>[
      (0, orbitValue + 0.02),
      (1, orbitValue + 0.18),
      (2, orbitValue + 0.36),
      (3, orbitValue + 0.54),
      (4, orbitValue + 0.72),
      (2, orbitValue + 0.84),
    ];
    for (var i = 0; i < dots.length; i++) {
      final orbitIndex = dots[i].$1;
      final t = dots[i].$2;
      final theta = (t * math.pi * 2) % (math.pi * 2);
      final r = orbitRadii[orbitIndex];
      final yScale = orbitScales[orbitIndex];
      final rotation = orbitAngles[orbitIndex];
      final local = Offset(r * math.cos(theta), r * math.sin(theta) * yScale);
      final rotated = Offset(
        local.dx * math.cos(rotation) - local.dy * math.sin(rotation),
        local.dx * math.sin(rotation) + local.dy * math.cos(rotation),
      );
      final dotCenter = globeCenter + rotated;
      final glowPaint = Paint()
        ..color = Colors.white.withOpacity(0.52)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, dotGlowSigma);
      canvas.drawCircle(dotCenter, dotBaseRadius * 1.9, glowPaint);
      final dotPaint = Paint()..color = Colors.white.withOpacity(0.96);
      canvas.drawCircle(dotCenter, dotBaseRadius, dotPaint);
    }

    final satelliteOrbitRadius = globeRadius * 1.12;
    final satelliteAngle = -0.35 + orbitValue * (math.pi * 2);
    final satelliteCenter = Offset(
      globeCenter.dx + satelliteOrbitRadius * math.cos(satelliteAngle),
      globeCenter.dy + (satelliteOrbitRadius * 0.56) * math.sin(satelliteAngle),
    );
    final satelliteSize = (size.width * 0.12).clamp(42.0, 70.0);

    canvas.save();
    canvas.translate(satelliteCenter.dx, satelliteCenter.dy);
    canvas.rotate(satelliteAngle + math.pi / 2);
    _drawSatellite(canvas, satelliteSize);
    canvas.restore();
  }

  void _drawSatellite(Canvas canvas, double size) {
    final bodyW = size * 0.34;
    final bodyH = size * 0.24;
    final panelW = size * 0.24;
    final panelH = size * 0.14;
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: bodyW, height: bodyH),
      Radius.circular(size * 0.05),
    );
    final panelPaint = Paint()
      ..color = const Color(0xFF94A3B8).withOpacity(0.9);
    final panelLinePaint = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..strokeWidth = 0.8;
    final bodyPaint = Paint()
      ..color = const Color(0xFFE2E8F0).withOpacity(0.95);
    canvas.drawRRect(bodyRect, bodyPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-bodyW * 0.65, 0),
          width: panelW,
          height: panelH,
        ),
        Radius.circular(size * 0.02),
      ),
      panelPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(bodyW * 0.65, 0),
          width: panelW,
          height: panelH,
        ),
        Radius.circular(size * 0.02),
      ),
      panelPaint,
    );
    for (var i = -1; i <= 1; i++) {
      final x = i * panelW * 0.18;
      canvas.drawLine(
        Offset(-bodyW * 0.65 + x, -panelH * 0.45),
        Offset(-bodyW * 0.65 + x, panelH * 0.45),
        panelLinePaint,
      );
      canvas.drawLine(
        Offset(bodyW * 0.65 + x, -panelH * 0.45),
        Offset(bodyW * 0.65 + x, panelH * 0.45),
        panelLinePaint,
      );
    }
    final dishPaint = Paint()
      ..color = const Color(0xFF64748B).withOpacity(0.82);
    final dishCenter = Offset(0, -bodyH * 0.72);
    canvas.drawCircle(dishCenter, size * 0.065, dishPaint);
    canvas.drawLine(
      Offset.zero,
      dishCenter,
      Paint()
        ..color = const Color(0xFF64748B).withOpacity(0.82)
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(covariant OrbitLoginBackgroundPainter oldDelegate) {
    return oldDelegate.orbitValue != orbitValue ||
        oldDelegate.pulseValue != pulseValue;
  }
}
