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
          ? size.height * 0.22
          : (isShort ? size.height * 0.21 : size.height * 0.22),
    );
    final globeRadius = isTablet
        ? math.min(size.width * 0.35, 340.0).toDouble()
        : size.width * (isShort ? 0.39 : 0.41);

    final satelliteConfigs = <_SatelliteConfig>[
      const _SatelliteConfig(
        radiusXMul: 0.95,
        radiusYMul: 0.62,
        angleOffset: 0.10,
        size: 24.0,
        speed: 0.90,
        tilt: -0.35,
        opacity: 0.85,
      ),
      const _SatelliteConfig(
        radiusXMul: 1.02,
        radiusYMul: 0.68,
        angleOffset: 1.20,
        size: 22.0,
        speed: 1.00,
        tilt: 0.20,
        opacity: 0.78,
      ),
      const _SatelliteConfig(
        radiusXMul: 1.10,
        radiusYMul: 0.58,
        angleOffset: 2.20,
        size: 25.0,
        speed: 0.95,
        tilt: -0.75,
        opacity: 0.82,
      ),
      const _SatelliteConfig(
        radiusXMul: 1.16,
        radiusYMul: 0.72,
        angleOffset: 3.40,
        size: 21.0,
        speed: 1.08,
        tilt: 0.65,
        opacity: 0.74,
      ),
      const _SatelliteConfig(
        radiusXMul: 1.24,
        radiusYMul: 0.66,
        angleOffset: 4.45,
        size: 23.0,
        speed: 0.88,
        tilt: -1.00,
        opacity: 0.80,
      ),
    ];
    final satellites = _buildSatelliteInstances(
      globeCenter: globeCenter,
      globeRadius: globeRadius,
      orbitValue: orbitValue,
      configs: satelliteConfigs,
    );

    for (final s in satellites.where((s) => s.isBehind)) {
      _drawSatelliteInstance(canvas, s);
    }

    _drawGlobeShadow(
      canvas,
      globeCenter: globeCenter,
      globeRadius: globeRadius,
    );
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

    for (final s in satellites.where((s) => !s.isBehind)) {
      _drawSatelliteInstance(canvas, s);
    }

    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withOpacity(0.46);
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

    final dotBaseRadius = 2.0 + (pulseValue * 1.2);
    final dotGlowSigma = 6.0 + (pulseValue * 3.2);
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
        ..color = Colors.white.withOpacity(0.44)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, dotGlowSigma);
      canvas.drawCircle(dotCenter, dotBaseRadius * 1.55, glowPaint);
      final dotPaint = Paint()..color = Colors.white.withOpacity(0.72);
      canvas.drawCircle(dotCenter, dotBaseRadius, dotPaint);
    }
  }

  List<_SatelliteInstance> _buildSatelliteInstances({
    required Offset globeCenter,
    required double globeRadius,
    required double orbitValue,
    required List<_SatelliteConfig> configs,
  }) {
    final out = <_SatelliteInstance>[];
    for (final c in configs) {
      final angle = -(orbitValue * math.pi * 2 * c.speed) + c.angleOffset;
      final localX = math.cos(angle) * globeRadius * c.radiusXMul;
      final localY = math.sin(angle) * globeRadius * c.radiusYMul;
      final rotatedX = localX * math.cos(c.tilt) - localY * math.sin(c.tilt);
      final rotatedY = localX * math.sin(c.tilt) + localY * math.cos(c.tilt);
      final center = globeCenter + Offset(rotatedX, rotatedY);
      out.add(
        _SatelliteInstance(
          center: center,
          angle: angle,
          size: c.size,
          opacity: c.opacity,
          isBehind: localY < 0,
        ),
      );
    }
    return out;
  }

  void _drawSatelliteInstance(Canvas canvas, _SatelliteInstance s) {
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity((s.isBehind ? 0.05 : 0.08) * s.opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawCircle(s.center, s.size * 0.72, glowPaint);
    canvas.save();
    canvas.translate(s.center.dx, s.center.dy);
    canvas.rotate(s.angle + math.pi / 2);
    _drawSatellite(
      canvas,
      s.size,
      opacity: s.isBehind ? s.opacity * 0.82 : s.opacity,
    );
    canvas.restore();
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
    final globeRect = Rect.fromCircle(center: globeCenter, radius: globeRadius);
    final basePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFFFFF).withOpacity(0.98),
          const Color(0xFFF8FAFC).withOpacity(0.94),
          const Color(0xFFE2E8F0).withOpacity(0.88),
          const Color(0xFFCBD5E1).withOpacity(0.76),
          const Color(0xFF94A3B8).withOpacity(0.38),
        ],
        stops: const [0.0, 0.22, 0.56, 0.84, 1.0],
      ).createShader(globeRect);
    canvas.drawCircle(globeCenter, globeRadius, basePaint);

    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = globeRadius * 0.018
      ..color = Colors.white.withOpacity(0.42);
    canvas.drawCircle(globeCenter, globeRadius * 0.992, rimPaint);
  }

  void _drawGlobeShadow(
    Canvas canvas, {
    required Offset globeCenter,
    required double globeRadius,
  }) {
    final shadowPaint = Paint()
      ..color = const Color(0xFFCBD5E1).withOpacity(0.34)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 44);
    canvas.drawCircle(
      globeCenter.translate(globeRadius * 0.06, globeRadius * 0.14),
      globeRadius * 1.04,
      shadowPaint,
    );
    final depthPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF64748B).withOpacity(0.24),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: globeCenter.translate(
                globeRadius * 0.18,
                globeRadius * 0.26,
              ),
              radius: globeRadius * 0.95,
            ),
          );
    canvas.drawCircle(globeCenter, globeRadius, depthPaint);
  }

  void _drawGlobeInterior(
    Canvas canvas, {
    required Offset globeCenter,
    required double globeRadius,
  }) {
    final globeRect = Rect.fromCircle(center: globeCenter, radius: globeRadius);
    canvas.save();
    canvas.clipPath(Path()..addOval(globeRect));
    _drawGlobeMapPattern(canvas, globeRect: globeRect);
    _drawGlobeMapLabels(canvas, globeRect: globeRect, globeRadius: globeRadius);
    _drawGlobeGrid(canvas, globeCenter: globeCenter, globeRadius: globeRadius);
    canvas.restore();
  }

  void _drawGlobeMapLabels(
    Canvas canvas, {
    required Rect globeRect,
    required double globeRadius,
  }) {
    final baseSize = (globeRadius * 0.045).clamp(7.0, 10.0);
    final labels = <_MapLabel>[
      _MapLabel('New York', 0.30, 0.34, size: baseSize + 0.6, opacity: 0.30),
      _MapLabel(
        'United States',
        0.23,
        0.43,
        size: baseSize - 0.4,
        opacity: 0.24,
      ),
      _MapLabel('Atlantic', 0.43, 0.52, size: baseSize - 0.1, opacity: 0.20),
      _MapLabel('Europe', 0.58, 0.38, size: baseSize, opacity: 0.26),
      _MapLabel('Africa', 0.55, 0.65, size: baseSize + 0.2, opacity: 0.28),
      _MapLabel('Nigeria', 0.52, 0.58, size: baseSize, opacity: 0.30),
      _MapLabel('Kano', 0.51, 0.55, size: baseSize - 0.8, opacity: 0.26),
      _MapLabel('Lagos', 0.50, 0.62, size: baseSize - 0.8, opacity: 0.24),
      _MapLabel('Dubai', 0.66, 0.45, size: baseSize - 0.5, opacity: 0.24),
      _MapLabel('India', 0.72, 0.52, size: baseSize, opacity: 0.28),
      _MapLabel('Delhi', 0.74, 0.47, size: baseSize - 0.8, opacity: 0.24),
      _MapLabel('Mumbai', 0.69, 0.56, size: baseSize - 0.6, opacity: 0.23),
    ];

    for (final label in labels) {
      final x = globeRect.left + globeRect.width * label.dx;
      final y = globeRect.top + globeRect.height * label.dy;
      final p = Offset(x, y);
      final center = globeRect.center;
      final dist = (p - center).distance;
      final rimT = (dist / (globeRadius * 0.96)).clamp(0.0, 1.0);
      final rimFade = (1 - (rimT * rimT * 0.55)).clamp(0.45, 1.0);
      final color = const Color(
        0xFF64748B,
      ).withOpacity(label.opacity * rimFade);

      final tp = TextPainter(
        text: TextSpan(
          text: label.text,
          style: TextStyle(
            color: color,
            fontSize: label.size,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width * 0.5, y - tp.height * 0.5));
    }
  }

  void _drawGlobeMapPattern(Canvas canvas, {required Rect globeRect}) {
    final w = globeRect.width;
    final h = globeRect.height;
    final ox = globeRect.left;
    final oy = globeRect.top;

    final districtPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFCBD5E1).withOpacity(0.15);
    final district2Paint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF94A3B8).withOpacity(0.12);

    final blockA = Path()
      ..moveTo(ox + w * 0.14, oy + h * 0.30)
      ..lineTo(ox + w * 0.36, oy + h * 0.22)
      ..lineTo(ox + w * 0.44, oy + h * 0.34)
      ..lineTo(ox + w * 0.26, oy + h * 0.46)
      ..close();
    final blockB = Path()
      ..moveTo(ox + w * 0.48, oy + h * 0.28)
      ..lineTo(ox + w * 0.74, oy + h * 0.20)
      ..lineTo(ox + w * 0.86, oy + h * 0.36)
      ..lineTo(ox + w * 0.60, oy + h * 0.42)
      ..close();
    final blockC = Path()
      ..moveTo(ox + w * 0.18, oy + h * 0.56)
      ..lineTo(ox + w * 0.42, oy + h * 0.48)
      ..lineTo(ox + w * 0.58, oy + h * 0.66)
      ..lineTo(ox + w * 0.34, oy + h * 0.80)
      ..close();
    final blockD = Path()
      ..moveTo(ox + w * 0.56, oy + h * 0.52)
      ..lineTo(ox + w * 0.82, oy + h * 0.44)
      ..lineTo(ox + w * 0.90, oy + h * 0.66)
      ..lineTo(ox + w * 0.64, oy + h * 0.78)
      ..close();
    canvas.drawPath(blockA, districtPaint);
    canvas.drawPath(blockB, district2Paint);
    canvas.drawPath(blockC, district2Paint);
    canvas.drawPath(blockD, districtPaint);

    final roadPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(0.30);
    final roadPaint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.95
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF94A3B8).withOpacity(0.15);

    final majorRoad1 = Path()
      ..moveTo(ox + w * 0.06, oy + h * 0.38)
      ..quadraticBezierTo(
        ox + w * 0.34,
        oy + h * 0.24,
        ox + w * 0.56,
        oy + h * 0.36,
      )
      ..quadraticBezierTo(
        ox + w * 0.78,
        oy + h * 0.48,
        ox + w * 0.96,
        oy + h * 0.36,
      );
    final majorRoad2 = Path()
      ..moveTo(ox + w * 0.02, oy + h * 0.64)
      ..quadraticBezierTo(
        ox + w * 0.28,
        oy + h * 0.50,
        ox + w * 0.52,
        oy + h * 0.62,
      )
      ..quadraticBezierTo(
        ox + w * 0.70,
        oy + h * 0.74,
        ox + w * 0.96,
        oy + h * 0.58,
      );
    canvas.drawPath(majorRoad1, roadPaint);
    canvas.drawPath(majorRoad2, roadPaint);

    for (var i = 0; i < 10; i++) {
      final y = oy + h * (0.24 + i * 0.08);
      final lane = Path()
        ..moveTo(ox + w * 0.12, y)
        ..quadraticBezierTo(
          ox + w * 0.48,
          y - h * 0.06,
          ox + w * 0.86,
          y + h * 0.03,
        );
      canvas.drawPath(lane, roadPaint2);
    }
    for (var i = 0; i < 8; i++) {
      final x = ox + w * (0.18 + i * 0.12);
      final lane = Path()
        ..moveTo(x, oy + h * 0.14)
        ..quadraticBezierTo(
          x - w * 0.05,
          oy + h * 0.50,
          x + w * 0.02,
          oy + h * 0.88,
        );
      canvas.drawPath(lane, roadPaint2);
    }

    final ringRoad = Path()
      ..moveTo(ox + w * 0.16, oy + h * 0.52)
      ..quadraticBezierTo(
        ox + w * 0.34,
        oy + h * 0.40,
        ox + w * 0.56,
        oy + h * 0.50,
      )
      ..quadraticBezierTo(
        ox + w * 0.76,
        oy + h * 0.58,
        ox + w * 0.86,
        oy + h * 0.74,
      );
    canvas.drawPath(
      ringRoad,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.6
        ..color = Colors.white.withOpacity(0.24),
    );

    final river = Path()
      ..moveTo(ox + w * 0.08, oy + h * 0.70)
      ..quadraticBezierTo(
        ox + w * 0.26,
        oy + h * 0.62,
        ox + w * 0.42,
        oy + h * 0.72,
      )
      ..quadraticBezierTo(
        ox + w * 0.62,
        oy + h * 0.84,
        ox + w * 0.88,
        oy + h * 0.72,
      );
    canvas.drawPath(
      river,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = const Color(0xFFE2E8F0).withOpacity(0.15),
    );

    final rimFade = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          const Color(0xFFE2E8F0).withOpacity(0.10),
          const Color(0xFF94A3B8).withOpacity(0.18),
        ],
        stops: const [0.68, 0.86, 1.0],
      ).createShader(globeRect);
    canvas.drawOval(globeRect, rimFade);
  }

  void _drawGlobeGrid(
    Canvas canvas, {
    required Offset globeCenter,
    required double globeRadius,
  }) {
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withOpacity(0.16);
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

  void _drawGlobeHighlight(
    Canvas canvas, {
    required Offset globeCenter,
    required double globeRadius,
  }) {
    final globeRect = Rect.fromCircle(center: globeCenter, radius: globeRadius);
    canvas.save();
    canvas.clipPath(Path()..addOval(globeRect));

    final highlightPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.white.withOpacity(0.38),
              Colors.white.withOpacity(0.06),
              Colors.transparent,
            ],
            stops: const [0.0, 0.38, 1.0],
          ).createShader(
            Rect.fromCircle(
              center: globeCenter.translate(
                globeRadius * 0.34,
                -globeRadius * 0.30,
              ),
              radius: globeRadius * 0.74,
            ),
          );
    canvas.drawCircle(globeCenter, globeRadius, highlightPaint);

    final glossPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Colors.white.withOpacity(0.22),
          Colors.white.withOpacity(0.02),
          Colors.transparent,
        ],
        stops: const [0.0, 0.28, 1.0],
      ).createShader(globeRect);
    canvas.drawOval(
      Rect.fromCenter(
        center: globeCenter.translate(globeRadius * 0.14, -globeRadius * 0.10),
        width: globeRadius * 1.24,
        height: globeRadius * 1.02,
      ),
      glossPaint,
    );

    final shadePaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF475569).withOpacity(0.26),
              const Color(0xFF64748B).withOpacity(0.08),
              Colors.transparent,
            ],
            stops: const [0.0, 0.46, 1.0],
          ).createShader(
            Rect.fromCircle(
              center: globeCenter.translate(
                -globeRadius * 0.32,
                globeRadius * 0.36,
              ),
              radius: globeRadius * 0.92,
            ),
          );
    canvas.drawCircle(globeCenter, globeRadius, shadePaint);

    final vignettePaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, const Color(0xFF94A3B8).withOpacity(0.20)],
        stops: const [0.74, 1.0],
      ).createShader(globeRect);
    canvas.drawCircle(globeCenter, globeRadius, vignettePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant OrbitLoginBackgroundPainter oldDelegate) {
    return oldDelegate.orbitValue != orbitValue ||
        oldDelegate.pulseValue != pulseValue;
  }
}

class _MapLabel {
  const _MapLabel(
    this.text,
    this.dx,
    this.dy, {
    required this.size,
    required this.opacity,
  });

  final String text;
  final double dx;
  final double dy;
  final double size;
  final double opacity;
}

class _SatelliteConfig {
  const _SatelliteConfig({
    required this.radiusXMul,
    required this.radiusYMul,
    required this.angleOffset,
    required this.size,
    required this.speed,
    required this.tilt,
    required this.opacity,
  });

  final double radiusXMul;
  final double radiusYMul;
  final double angleOffset;
  final double size;
  final double speed;
  final double tilt;
  final double opacity;
}

class _SatelliteInstance {
  const _SatelliteInstance({
    required this.center,
    required this.angle,
    required this.size,
    required this.opacity,
    required this.isBehind,
  });

  final Offset center;
  final double angle;
  final double size;
  final double opacity;
  final bool isBehind;
}
