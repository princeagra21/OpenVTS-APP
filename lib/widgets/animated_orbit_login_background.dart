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
          radius: 1,
          colors: [Colors.white.withOpacity(0.85), Colors.white.withOpacity(0)],
          stops: const [0, 1],
        ).createShader(
          Rect.fromCircle(center: topGlowCenter, radius: topGlowRadius),
        );
    canvas.drawCircle(topGlowCenter, topGlowRadius, paint);

    final isTablet = size.width >= 700;
    final isShort = size.height < 700;
    final globeCenter = Offset(
      size.width * 0.50,
      isTablet
          ? size.height * 0.23
          : (isShort ? size.height * 0.22 : size.height * 0.24),
    );
    final globeRadius = isTablet
        ? math.min(size.width * 0.34, 340.0).toDouble()
        : size.width * (isShort ? 0.37 : 0.40);

    _drawGlobeBase(canvas, globeCenter: globeCenter, globeRadius: globeRadius);
    _drawGlobeInterior(
      canvas,
      globeCenter: globeCenter,
      globeRadius: globeRadius,
    );
    _drawGlobeHighlight(
      canvas,
      globeCenter: globeCenter,
      globeRadius: globeRadius,
    );

    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withOpacity(0.54);
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

    final dotBaseRadius = 2.0 + (pulseValue * 1.5);
    final dotGlowSigma = 6.0 + (pulseValue * 4.0);
    final dots = <(int orbitIndex, double angleOffset)>[
      (0, 0.12),
      (1, 1.05),
      (2, 2.08),
      (3, 3.01),
      (4, 4.12),
      (2, 5.02),
    ];
    for (var i = 0; i < dots.length; i++) {
      final orbitIndex = dots[i].$1;
      final theta = dots[i].$2;
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
      canvas.drawCircle(dotCenter, dotBaseRadius * 1.55, glowPaint);
      final dotPaint = Paint()..color = Colors.white.withOpacity(0.78);
      canvas.drawCircle(dotCenter, dotBaseRadius, dotPaint);
    }

    final satellites =
        <
          ({
            double radiusMul,
            double angleOffset,
            double size,
            double speed,
            double opacity,
            double tilt,
            double squash,
          })
        >[
          (
            radiusMul: 0.96,
            angleOffset: -0.90,
            size: 27.0,
            speed: 0.84,
            opacity: 0.88,
            tilt: -0.35,
            squash: 0.82,
          ),
          (
            radiusMul: 1.05,
            angleOffset: 0.55,
            size: 24.0,
            speed: 1.02,
            opacity: 0.78,
            tilt: 0.18,
            squash: 0.90,
          ),
          (
            radiusMul: 1.15,
            angleOffset: 1.95,
            size: 26.0,
            speed: 0.92,
            opacity: 0.84,
            tilt: -0.70,
            squash: 0.86,
          ),
          (
            radiusMul: 1.24,
            angleOffset: 3.35,
            size: 23.0,
            speed: 1.12,
            opacity: 0.78,
            tilt: 0.72,
            squash: 0.78,
          ),
          (
            radiusMul: 1.34,
            angleOffset: 4.75,
            size: 28.0,
            speed: 0.96,
            opacity: 0.82,
            tilt: -1.10,
            squash: 0.88,
          ),
        ];

    for (final s in satellites) {
      final satelliteOrbitRadius = globeRadius * s.radiusMul;
      final satelliteAngle =
          (orbitValue * math.pi * 2 * s.speed) + s.angleOffset;
      final local = Offset(
        satelliteOrbitRadius * math.cos(satelliteAngle),
        satelliteOrbitRadius * math.sin(satelliteAngle) * s.squash,
      );
      final rotated = Offset(
        local.dx * math.cos(s.tilt) - local.dy * math.sin(s.tilt),
        local.dx * math.sin(s.tilt) + local.dy * math.cos(s.tilt),
      );
      final satelliteCenter = globeCenter + rotated;
      final glowPaint = Paint()
        ..color = Colors.white.withOpacity(0.08 * s.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
      canvas.drawCircle(satelliteCenter, s.size * 0.72, glowPaint);
      canvas.save();
      canvas.translate(satelliteCenter.dx, satelliteCenter.dy);
      canvas.rotate(satelliteAngle + math.pi / 2);
      _drawSatellite(canvas, s.size, opacity: s.opacity);
      canvas.restore();
    }
  }

  void _drawSatellite(Canvas canvas, double size, {double opacity = 1}) {
    final renderSize = size * 1.22;
    final bodyW = renderSize * 0.34;
    final bodyH = renderSize * 0.24;
    final panelW = renderSize * 0.24;
    final panelH = renderSize * 0.14;
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: bodyW, height: bodyH),
      Radius.circular(renderSize * 0.05),
    );
    final panelPaint = Paint()
      ..color = const Color(0xFF94A3B8).withOpacity(0.9 * opacity);
    final panelLinePaint = Paint()
      ..color = Colors.white.withOpacity(0.55 * opacity)
      ..strokeWidth = 0.8;
    final bodyPaint = Paint()
      ..color = const Color(0xFFE2E8F0).withOpacity(0.95 * opacity);
    canvas.drawRRect(bodyRect, bodyPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-bodyW * 0.65, 0),
          width: panelW,
          height: panelH,
        ),
        Radius.circular(renderSize * 0.02),
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
        Radius.circular(renderSize * 0.02),
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
      ..color = const Color(0xFF64748B).withOpacity(0.82 * opacity);
    final dishCenter = Offset(0, -bodyH * 0.72);
    canvas.drawCircle(dishCenter, renderSize * 0.065, dishPaint);
    canvas.drawLine(
      Offset.zero,
      dishCenter,
      Paint()
        ..color = const Color(0xFF64748B).withOpacity(0.82 * opacity)
        ..strokeWidth = 1.4,
    );
  }

  void _drawGlobeBase(
    Canvas canvas, {
    required Offset globeCenter,
    required double globeRadius,
  }) {
    final shadowPaint = Paint()
      ..color = const Color(0xFFCBD5E1).withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawCircle(
      globeCenter.translate(0, globeRadius * 0.10),
      globeRadius * 1.03,
      shadowPaint,
    );

    final globeRect = Rect.fromCircle(center: globeCenter, radius: globeRadius);
    final basePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFF8FAFC).withOpacity(0.92),
          const Color(0xFFE2E8F0).withOpacity(0.88),
          const Color(0xFFCBD5E1).withOpacity(0.76),
        ],
        stops: const [0.0, 0.54, 1.0],
      ).createShader(globeRect);
    canvas.drawCircle(globeCenter, globeRadius, basePaint);
  }

  void _drawGlobeInterior(
    Canvas canvas, {
    required Offset globeCenter,
    required double globeRadius,
  }) {
    final globeRect = Rect.fromCircle(center: globeCenter, radius: globeRadius);
    canvas.save();
    canvas.clipPath(Path()..addOval(globeRect));
    _drawGlobeGrid(canvas, globeCenter: globeCenter, globeRadius: globeRadius);
    _drawContinents(canvas, globeRect: globeRect);
    canvas.restore();
  }

  void _drawGlobeGrid(
    Canvas canvas, {
    required Offset globeCenter,
    required double globeRadius,
  }) {
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withOpacity(0.18);
    for (var i = -2; i <= 2; i++) {
      final yScale = 1 - (i.abs() * 0.12);
      canvas.save();
      canvas.translate(globeCenter.dx, globeCenter.dy + i * globeRadius * 0.13);
      canvas.scale(1, yScale);
      canvas.drawCircle(Offset.zero, globeRadius * 0.90, gridPaint);
      canvas.restore();
    }
    for (var i = -2; i <= 2; i++) {
      final x = globeCenter.dx + i * globeRadius * 0.22;
      final meridian = Path()
        ..moveTo(x, globeCenter.dy - globeRadius * 0.90)
        ..quadraticBezierTo(
          x + i * globeRadius * 0.04,
          globeCenter.dy,
          x,
          globeCenter.dy + globeRadius * 0.90,
        );
      canvas.drawPath(meridian, gridPaint);
    }
  }

  void _drawContinents(Canvas canvas, {required Rect globeRect}) {
    final w = globeRect.width;
    final h = globeRect.height;
    final ox = globeRect.left;
    final oy = globeRect.top;

    final landPrimary = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFB8C4D3).withOpacity(0.32);
    final landSecondary = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF94A3B8).withOpacity(0.16);
    final landHighlight = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withOpacity(0.10);

    final americas = Path()
      ..moveTo(ox + w * 0.24, oy + h * 0.30)
      ..quadraticBezierTo(
        ox + w * 0.18,
        oy + h * 0.40,
        ox + w * 0.24,
        oy + h * 0.48,
      )
      ..quadraticBezierTo(
        ox + w * 0.30,
        oy + h * 0.52,
        ox + w * 0.34,
        oy + h * 0.60,
      )
      ..quadraticBezierTo(
        ox + w * 0.35,
        oy + h * 0.68,
        ox + w * 0.30,
        oy + h * 0.74,
      )
      ..quadraticBezierTo(
        ox + w * 0.36,
        oy + h * 0.78,
        ox + w * 0.42,
        oy + h * 0.70,
      )
      ..quadraticBezierTo(
        ox + w * 0.40,
        oy + h * 0.58,
        ox + w * 0.38,
        oy + h * 0.48,
      )
      ..quadraticBezierTo(
        ox + w * 0.40,
        oy + h * 0.38,
        ox + w * 0.34,
        oy + h * 0.30,
      )
      ..close();
    canvas.drawPath(americas, landPrimary);

    final europeAfrica = Path()
      ..moveTo(ox + w * 0.56, oy + h * 0.26)
      ..quadraticBezierTo(
        ox + w * 0.52,
        oy + h * 0.34,
        ox + w * 0.56,
        oy + h * 0.40,
      )
      ..quadraticBezierTo(
        ox + w * 0.62,
        oy + h * 0.42,
        ox + w * 0.66,
        oy + h * 0.50,
      )
      ..quadraticBezierTo(
        ox + w * 0.66,
        oy + h * 0.60,
        ox + w * 0.62,
        oy + h * 0.70,
      )
      ..quadraticBezierTo(
        ox + w * 0.68,
        oy + h * 0.66,
        ox + w * 0.72,
        oy + h * 0.58,
      )
      ..quadraticBezierTo(
        ox + w * 0.72,
        oy + h * 0.46,
        ox + w * 0.68,
        oy + h * 0.38,
      )
      ..quadraticBezierTo(
        ox + w * 0.66,
        oy + h * 0.30,
        ox + w * 0.60,
        oy + h * 0.26,
      )
      ..close();
    canvas.drawPath(europeAfrica, landPrimary);

    final asiaHint = Path()
      ..moveTo(ox + w * 0.72, oy + h * 0.24)
      ..quadraticBezierTo(
        ox + w * 0.80,
        oy + h * 0.28,
        ox + w * 0.86,
        oy + h * 0.36,
      )
      ..quadraticBezierTo(
        ox + w * 0.86,
        oy + h * 0.44,
        ox + w * 0.80,
        oy + h * 0.50,
      )
      ..quadraticBezierTo(
        ox + w * 0.74,
        oy + h * 0.48,
        ox + w * 0.70,
        oy + h * 0.40,
      )
      ..quadraticBezierTo(
        ox + w * 0.68,
        oy + h * 0.32,
        ox + w * 0.72,
        oy + h * 0.24,
      )
      ..close();
    canvas.drawPath(asiaHint, landSecondary);

    final shimmer = Path()
      ..moveTo(ox + w * 0.28, oy + h * 0.34)
      ..quadraticBezierTo(
        ox + w * 0.34,
        oy + h * 0.32,
        ox + w * 0.36,
        oy + h * 0.38,
      )
      ..quadraticBezierTo(
        ox + w * 0.34,
        oy + h * 0.44,
        ox + w * 0.30,
        oy + h * 0.42,
      )
      ..close();
    canvas.drawPath(shimmer, landHighlight);
  }

  void _drawGlobeHighlight(
    Canvas canvas, {
    required Offset globeCenter,
    required double globeRadius,
  }) {
    final highlightPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.white.withOpacity(0.40),
              Colors.white.withOpacity(0),
            ],
            stops: const [0, 1],
          ).createShader(
            Rect.fromCircle(
              center: globeCenter.translate(
                globeRadius * 0.38,
                -globeRadius * 0.24,
              ),
              radius: globeRadius * 0.66,
            ),
          );
    canvas.drawCircle(globeCenter, globeRadius, highlightPaint);

    final shadePaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF475569).withOpacity(0.16),
              Colors.transparent,
            ],
            stops: const [0, 1],
          ).createShader(
            Rect.fromCircle(
              center: globeCenter.translate(
                -globeRadius * 0.32,
                globeRadius * 0.38,
              ),
              radius: globeRadius * 0.86,
            ),
          );
    canvas.drawCircle(globeCenter, globeRadius, shadePaint);
  }

  @override
  bool shouldRepaint(covariant OrbitLoginBackgroundPainter oldDelegate) {
    return oldDelegate.orbitValue != orbitValue ||
        oldDelegate.pulseValue != pulseValue;
  }
}
