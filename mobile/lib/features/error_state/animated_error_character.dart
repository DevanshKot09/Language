import 'dart:math' as math;
import 'package:flutter/material.dart';

/// An original animated character ("Volt-E", a friendly cartoon robot explorer)
/// who discovers an unplugged cable, inspects it in confusion, and gets a comical,
/// harmless little zap before returning to idle.
///
/// Multi-stage looping sequence (~7.0 seconds total):
///   - Stage a (0.00 – 0.25): Sitting idle on ground, soft breathing, blinking.
///   - Stage b (0.25 – 0.45): Notices loose cable, stands up, lifts plug.
///   - Stage c (0.45 – 0.65): Confused: tilts head, scratches antenna, inspects prongs.
///   - Stage d (0.65 – 0.80): Curious: holds plug right near visor.
///   - Stage e (0.80 – 1.00): ZAP! Electric spark arc, brief bright x-ray flash,
///                            comical jitter shake, gentle smoke puff, sits back down.
///
/// Built with native [AnimationController] and [CustomPainter] — zero third-party assets,
/// zero pixelation, lightweight 60fps rendering, respects `disableAnimations`.
class AnimatedErrorCharacter extends StatefulWidget {
  final double size;
  final bool isDark;

  const AnimatedErrorCharacter({
    super.key,
    this.size = 220,
    this.isDark = false,
  });

  @override
  State<AnimatedErrorCharacter> createState() => _AnimatedErrorCharacterState();
}

class _AnimatedErrorCharacterState extends State<AnimatedErrorCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    if (disableAnimations) {
      return RepaintBoundary(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _VoltECharacterPainter(
              progress: 0.55, // Static curious pose
              isDark: widget.isDark,
              isStatic: true,
            ),
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _VoltECharacterPainter(
                progress: _controller.value,
                isDark: widget.isDark,
                isStatic: false,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter rendering the original Volt-E character with procedural animation poses.
class _VoltECharacterPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  final bool isStatic;

  _VoltECharacterPainter({
    required this.progress,
    required this.isDark,
    required this.isStatic,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final s = w / 220.0; // scale factor relative to 220 design canvas

    // Palette tokens
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.35)
        : const Color(0xFF1E1B4B).withValues(alpha: 0.08);
    const bodyBase = Color(0xFF4A4ABF); // Lingual primary purple/slate
    const bodyHighlight = Color(0xFF6B6BE2);
    const facePlateColor = Color(0xFF18202A);
    const eyeCyan = Color(0xFF2DD4BF);
    const wireColor = Color(0xFF334155);
    const plugColor = Color(0xFFF59E7A);
    const prongColor = Color(0xFFCBD5E1);
    const sparkGold = Color(0xFFFBBF24);
    const sparkWhite = Color(0xFFFFFFFF);

    // Timeline calculation (0.0 to 1.0)
    final double t = isStatic ? 0.55 : progress;

    // Stage evaluations
    final bool stageA = t < 0.25;
    final bool stageB = t >= 0.25 && t < 0.45;
    final bool stageC = t >= 0.45 && t < 0.65;
    final bool stageD = t >= 0.65 && t < 0.80;
    final bool stageE = t >= 0.80;

    // Sub-stage normalized progressions
    final double tA = (t / 0.25).clamp(0.0, 1.0);
    final double tB = ((t - 0.25) / 0.20).clamp(0.0, 1.0);
    final double tC = ((t - 0.45) / 0.20).clamp(0.0, 1.0);
    final double tD = ((t - 0.65) / 0.15).clamp(0.0, 1.0);
    final double tE = ((t - 0.80) / 0.20).clamp(0.0, 1.0);

    // 1. Dynamic motion offsets
    double bodyYOffset = 0.0;
    double headTilt = 0.0;
    double shakeX = 0.0;
    double shakeY = 0.0;
    double handPlugX = 0.0;
    double handPlugY = 0.0;
    bool isStanding = false;
    bool isZapActive = false;
    double zapFlashOpacity = 0.0;
    double antennaBulbRadius = 5.0 * s;
    Color antennaColor = eyeCyan;
    double blinkFactor = 1.0; // 1.0 = fully open, 0.0 = closed eye

    if (stageA) {
      // Gentle breathing float (±2.5px)
      bodyYOffset = math.sin(tA * math.pi * 4) * 2.5 * s;
      // Blinks at ~tA=0.3 and tA=0.7
      if ((tA > 0.28 && tA < 0.35) || (tA > 0.68 && tA < 0.75)) {
        blinkFactor = 0.1;
      }
      isStanding = false;
      handPlugX = 145 * s;
      handPlugY = 168 * s;
    } else if (stageB) {
      // Standing up transition
      final standCurve = Curves.easeInOutCubic.transform(tB);
      isStanding = standCurve > 0.5;
      bodyYOffset = -standCurve * 16.0 * s;
      handPlugX = uiLerp(145 * s, 138 * s, standCurve);
      handPlugY = uiLerp(168 * s, 135 * s, standCurve);
    } else if (stageC) {
      // Confused head tilt & scratch
      isStanding = true;
      bodyYOffset = -16.0 * s;
      final tiltCurve = math.sin(tC * math.pi);
      headTilt = tiltCurve * 0.22; // ~12 degrees
      antennaColor = const Color(0xFFF59E0B); // Amber
      antennaBulbRadius = 6.0 * s;
      handPlugX = 135 * s;
      handPlugY = 130 * s;
    } else if (stageD) {
      // Holds plug close to face
      isStanding = true;
      bodyYOffset = -16.0 * s + math.sin(tD * math.pi * 2) * 2.0 * s;
      headTilt = 0.08;
      handPlugX = uiLerp(135 * s, 118 * s, Curves.easeOutQuad.transform(tD));
      handPlugY = uiLerp(130 * s, 112 * s, Curves.easeOutQuad.transform(tD));
      antennaColor = const Color(0xFFEF4444); // Alert red
    } else if (stageE) {
      // ZAP! Rapid shake, glow flash, sparks
      if (tE < 0.65) {
        isZapActive = true;
        final zapDecay = (1.0 - (tE / 0.65)).clamp(0.0, 1.0);
        // High frequency vibration
        shakeX = math.sin(tE * math.pi * 32) * 5.0 * s * zapDecay;
        shakeY = math.cos(tE * math.pi * 32) * 4.0 * s * zapDecay;
        zapFlashOpacity = (math.sin(tE * math.pi * 8).abs() * zapDecay).clamp(0.0, 1.0);
        isStanding = true;
        bodyYOffset = -16.0 * s + shakeY;
        handPlugX = 120 * s + shakeX;
        handPlugY = 110 * s + shakeY;
      } else {
        // Return back to sitting down smoothly
        final returnCurve = ((tE - 0.65) / 0.35).clamp(0.0, 1.0);
        final smoothReturn = Curves.easeInOutCubic.transform(returnCurve);
        isStanding = smoothReturn < 0.5;
        bodyYOffset = uiLerp(-16.0 * s, 0.0, smoothReturn);
        handPlugX = uiLerp(120 * s, 145 * s, smoothReturn);
        handPlugY = uiLerp(110 * s, 168 * s, smoothReturn);
      }
    }

    // -------------------------------------------------------------------------
    // DRAW: Ambient Ground Shadow
    // -------------------------------------------------------------------------
    final shadowPaint = Paint()..color = shadowColor;
    final shadowWidth = (isStanding ? 70.0 : 92.0) * s;
    final shadowHeight = 12.0 * s;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(105 * s, 185 * s),
        width: shadowWidth,
        height: shadowHeight,
      ),
      shadowPaint,
    );

    // -------------------------------------------------------------------------
    // DRAW: Unplugged Power Cable & Loose Socket on the Ground
    // -------------------------------------------------------------------------
    final cablePaint = Paint()
      ..color = wireColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * s
      ..strokeCap = StrokeCap.round;

    final wallSocketPaint = Paint()..color = const Color(0xFF94A3B8);
    // Wall / power outlet base on the left ground
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(20 * s, 168 * s, 18 * s, 22 * s),
        Radius.circular(4 * s),
      ),
      wallSocketPaint,
    );
    // Two empty slots in the outlet
    final outletHolePaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawRect(Rect.fromLTWH(24 * s, 173 * s, 3 * s, 5 * s), outletHolePaint);
    canvas.drawRect(Rect.fromLTWH(31 * s, 173 * s, 3 * s, 5 * s), outletHolePaint);

    // Wire curve path from socket to plug
    final wirePath = Path();
    wirePath.moveTo(38 * s, 179 * s);
    if (!isStanding && stageA) {
      // Coiled slacked wire along floor
      wirePath.cubicTo(60 * s, 184 * s, 90 * s, 176 * s, 115 * s, 182 * s);
      wirePath.cubicTo(128 * s, 185 * s, 138 * s, 176 * s, handPlugX, handPlugY);
    } else {
      // Stretched arc up to the hand
      wirePath.cubicTo(55 * s, 188 * s, 85 * s, 182 * s, 105 * s, 165 * s);
      wirePath.cubicTo(120 * s, 155 * s, 125 * s, 140 * s, handPlugX, handPlugY);
    }
    canvas.drawPath(wirePath, cablePaint);

    // -------------------------------------------------------------------------
    // DRAW: ZAP Glow Aura (Stage e)
    // -------------------------------------------------------------------------
    if (isZapActive && zapFlashOpacity > 0.05) {
      final glowPaint = Paint()
        ..color = sparkGold.withValues(alpha: 0.35 * zapFlashOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
      canvas.drawCircle(Offset(105 * s + shakeX, 120 * s + shakeY), 54 * s, glowPaint);

      // Starburst lightning aura
      final burstPaint = Paint()
        ..color = sparkWhite.withValues(alpha: 0.8 * zapFlashOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * s;
      _drawSparkBurst(canvas, Offset(handPlugX, handPlugY), 18 * s, burstPaint);
    }

    // -------------------------------------------------------------------------
    // DRAW: Robot Body & Legs
    // -------------------------------------------------------------------------
    canvas.save();
    canvas.translate(shakeX, bodyYOffset);

    // Legs
    final legPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.fill;
    final footPaint = Paint()..color = const Color(0xFF1E293B);

    if (isStanding) {
      // Standing upright legs
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(88 * s, 158 * s, 10 * s, 22 * s), Radius.circular(5 * s)),
        legPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(112 * s, 158 * s, 10 * s, 22 * s), Radius.circular(5 * s)),
        legPaint,
      );
      // Feet / rubber boots
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(85 * s, 176 * s, 15 * s, 9 * s), Radius.circular(4 * s)),
        footPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(110 * s, 176 * s, 15 * s, 9 * s), Radius.circular(4 * s)),
        footPaint,
      );
    } else {
      // Seated / folded legs
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(80 * s, 168 * s, 22 * s, 12 * s), Radius.circular(6 * s)),
        legPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(108 * s, 168 * s, 22 * s, 12 * s), Radius.circular(6 * s)),
        legPaint,
      );
      canvas.drawCircle(Offset(78 * s, 174 * s), 6 * s, footPaint);
      canvas.drawCircle(Offset(132 * s, 174 * s), 6 * s, footPaint);
    }

    // Main Torso / Chassis
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [bodyHighlight, bodyBase],
      ).createShader(Rect.fromLTWH(76 * s, 115 * s, 58 * s, 52 * s));

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(76 * s, 115 * s, 58 * s, 50 * s),
      Radius.circular(16 * s),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    // Torso highlight bevel
    final bevelPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * s;
    canvas.drawRRect(bodyRect, bevelPaint);

    // Torso belly screen / power gauge
    final gaugeBgPaint = Paint()..color = const Color(0xFF1E1B4B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(92 * s, 135 * s, 26 * s, 18 * s), Radius.circular(6 * s)),
      gaugeBgPaint,
    );

    // Battery / pulse meter inside belly
    final gaugeFillPaint = Paint()..color = isZapActive ? sparkGold : eyeCyan;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(95 * s, 139 * s, isZapActive ? 20 * s : 14 * s, 10 * s),
        Radius.circular(3 * s),
      ),
      gaugeFillPaint,
    );

    // -------------------------------------------------------------------------
    // DRAW: Robot Head & Expressive Visor (with tilt)
    // -------------------------------------------------------------------------
    canvas.save();
    // Pivot around neck center (105, 112)
    canvas.translate(105 * s, 112 * s);
    canvas.rotate(headTilt);
    canvas.translate(-105 * s, -112 * s);

    // Antenna stalk
    final antennaStalkPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 3.0 * s
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final antennaPath = Path();
    antennaPath.moveTo(105 * s, 68 * s);
    if (isZapActive) {
      // Straight upright zig-zag like lightning rod
      antennaPath.lineTo(105 * s, 48 * s);
    } else if (stageC) {
      // Inquisitive curved bend
      antennaPath.quadraticBezierTo(112 * s, 58 * s, 108 * s, 50 * s);
    } else {
      antennaPath.quadraticBezierTo(108 * s, 60 * s, 105 * s, 52 * s);
    }
    canvas.drawPath(antennaPath, antennaStalkPaint);

    // Antenna glowing orb
    final orbPaint = Paint()..color = antennaColor;
    final orbGlowPaint = Paint()
      ..color = antennaColor.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final orbCenter = Offset(isZapActive ? 105 * s : 107 * s, isZapActive ? 46 * s : 50 * s);
    canvas.drawCircle(orbCenter, antennaBulbRadius + 2 * s, orbGlowPaint);
    canvas.drawCircle(orbCenter, antennaBulbRadius, orbPaint);

    // Head base chassis
    final headRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(73 * s, 66 * s, 64 * s, 48 * s),
      Radius.circular(18 * s),
    );
    final headPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [bodyHighlight, bodyBase],
      ).createShader(Rect.fromLTWH(73 * s, 66 * s, 64 * s, 48 * s));
    canvas.drawRRect(headRect, headPaint);

    // Metallic ear bolts
    final boltPaint = Paint()..color = const Color(0xFF64748B);
    canvas.drawCircle(Offset(72 * s, 90 * s), 4.5 * s, boltPaint);
    canvas.drawCircle(Offset(138 * s, 90 * s), 4.5 * s, boltPaint);

    // Face visor screen
    final visorRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(80 * s, 74 * s, 50 * s, 32 * s),
      Radius.circular(12 * s),
    );
    final visorPaint = Paint()..color = facePlateColor;
    canvas.drawRRect(visorRect, visorPaint);

    // Expressive Digital Eyes
    final eyePaint = Paint()
      ..color = (isZapActive && zapFlashOpacity > 0.4) ? sparkWhite : eyeCyan
      ..style = PaintingStyle.fill;

    if (stageC) {
      // Confused asymmetrical eyes (left eye wide circle, right eye tilted quizzical arc)
      canvas.drawCircle(Offset(94 * s, 88 * s), 4.5 * s, eyePaint);
      final browPath = Path()
        ..moveTo(110 * s, 86 * s)
        ..quadraticBezierTo(116 * s, 84 * s, 122 * s, 88 * s);
      final browPaint = Paint()
        ..color = eyeCyan
        ..strokeWidth = 2.5 * s
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(browPath, browPaint);
      canvas.drawCircle(Offset(116 * s, 90 * s), 3.0 * s, eyePaint);
    } else if (stageD) {
      // Inquisitive wide question eyes
      canvas.drawCircle(Offset(95 * s, 88 * s), 5.5 * s, eyePaint);
      canvas.drawCircle(Offset(115 * s, 88 * s), 5.5 * s, eyePaint);
      // Pupil shine dots
      final pupilShine = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(96 * s, 86 * s), 1.8 * s, pupilShine);
      canvas.drawCircle(Offset(116 * s, 86 * s), 1.8 * s, pupilShine);
    } else if (isZapActive) {
      // X-ray / startled spiral or wide flash eyes
      final zapEyeRadius = (6.0 + math.sin(tE * math.pi * 16).abs() * 2.0) * s;
      canvas.drawCircle(Offset(95 * s, 88 * s), zapEyeRadius, eyePaint);
      canvas.drawCircle(Offset(115 * s, 88 * s), zapEyeRadius, eyePaint);
    } else {
      // Normal blinking oval eyes
      final eyeH = 7.0 * s * blinkFactor;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(95 * s, 88 * s), width: 9.0 * s, height: math.max(1.5 * s, eyeH)),
        eyePaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(115 * s, 88 * s), width: 9.0 * s, height: math.max(1.5 * s, eyeH)),
        eyePaint,
      );
    }

    // Left arm (scratches head during Stage c, rests otherwise)
    final armPaint = Paint()
      ..color = bodyBase
      ..strokeWidth = 5.5 * s
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (stageC) {
      // Left hand reaching up to scratch antenna
      final scratchPath = Path();
      scratchPath.moveTo(76 * s, 125 * s);
      scratchPath.cubicTo(60 * s, 110 * s, 62 * s, 75 * s, 76 * s, 68 * s);
      canvas.drawPath(scratchPath, armPaint);
      canvas.drawCircle(Offset(76 * s, 68 * s), 4.5 * s, Paint()..color = const Color(0xFF334155));
    } else {
      // Normal resting arm
      final restArmPath = Path();
      restArmPath.moveTo(76 * s, 125 * s);
      restArmPath.quadraticBezierTo(66 * s, 140 * s, 72 * s, 155 * s);
      canvas.drawPath(restArmPath, armPaint);
      canvas.drawCircle(Offset(72 * s, 155 * s), 4.5 * s, Paint()..color = const Color(0xFF334155));
    }

    canvas.restore(); // Restore head transform

    canvas.restore(); // Restore body transform

    // -------------------------------------------------------------------------
    // DRAW: Right Hand Holding the Plug
    // -------------------------------------------------------------------------
    final rightArmPaint = Paint()
      ..color = bodyBase
      ..strokeWidth = 5.5 * s
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rightArmPath = Path();
    rightArmPath.moveTo(134 * s, 125 * s + bodyYOffset);
    rightArmPath.quadraticBezierTo(
      (134 * s + handPlugX) / 2 + 10 * s,
      (125 * s + bodyYOffset + handPlugY) / 2,
      handPlugX,
      handPlugY,
    );
    canvas.drawPath(rightArmPath, rightArmPaint);

    // Hand clamp
    final handPaint = Paint()..color = const Color(0xFF334155);
    canvas.drawCircle(Offset(handPlugX, handPlugY), 5.5 * s, handPaint);

    // Plug housing (orange/salmon rectangular block)
    final plugPaint = Paint()..color = plugColor;
    final plugAngle = stageC || stageD ? -0.4 : 0.2;
    canvas.save();
    canvas.translate(handPlugX, handPlugY);
    canvas.rotate(plugAngle);

    final plugRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(3 * s, -7 * s, 14 * s, 14 * s),
      Radius.circular(3 * s),
    );
    canvas.drawRRect(plugRRect, plugPaint);

    // Two metal prongs sticking out of the plug
    final prongPaint = Paint()
      ..color = prongColor
      ..strokeWidth = 2.5 * s
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(Offset(17 * s, -3.5 * s), Offset(25 * s, -3.5 * s), prongPaint);
    canvas.drawLine(Offset(17 * s, 3.5 * s), Offset(25 * s, 3.5 * s), prongPaint);

    // If zap active: draw electrical sparks emitting from the prongs!
    if (isZapActive) {
      final sparkArcPaint = Paint()
        ..color = sparkGold
        ..strokeWidth = 2.0 * s
        ..style = PaintingStyle.stroke;

      final sparkPath = Path()
        ..moveTo(25 * s, -3.5 * s)
        ..lineTo(31 * s, -7 * s)
        ..lineTo(29 * s, -2 * s)
        ..lineTo(36 * s, 0 * s)
        ..lineTo(27 * s, 4 * s)
        ..lineTo(32 * s, 8 * s);
      canvas.drawPath(sparkPath, sparkArcPaint);

      final sparkDotPaint = Paint()..color = sparkWhite;
      canvas.drawCircle(Offset(36 * s, 0 * s), 2.5 * s, sparkDotPaint);
      canvas.drawCircle(Offset(31 * s, -7 * s), 1.8 * s, sparkDotPaint);
    }

    canvas.restore();

    // -------------------------------------------------------------------------
    // DRAW: Little Smoke Rings (late Stage e)
    // -------------------------------------------------------------------------
    if (stageE && tE > 0.45 && tE < 0.90) {
      final smokeT = (tE - 0.45) / 0.45;
      final smokePaint = Paint()
        ..color = const Color(0xFF94A3B8).withValues(alpha: (0.45 * (1.0 - smokeT)).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8 * s;

      final smokeY = 90 * s - smokeT * 32.0 * s;
      canvas.drawCircle(Offset(125 * s, smokeY), (4.0 + smokeT * 10.0) * s, smokePaint);
      canvas.drawCircle(Offset(115 * s, smokeY - 10 * s), (3.0 + smokeT * 7.0) * s, smokePaint);
    }
  }

  void _drawSparkBurst(Canvas canvas, Offset center, double radius, Paint paint) {
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3);
      final p1 = Offset(center.dx + math.cos(angle) * (radius * 0.4), center.dy + math.sin(angle) * (radius * 0.4));
      final p2 = Offset(center.dx + math.cos(angle) * radius, center.dy + math.sin(angle) * radius);
      canvas.drawLine(p1, p2, paint);
    }
  }

  static double uiLerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(covariant _VoltECharacterPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isStatic != isStatic;
  }
}
