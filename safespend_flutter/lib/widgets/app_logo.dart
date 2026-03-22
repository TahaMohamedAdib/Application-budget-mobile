import 'dart:math' as math;
import 'package:flutter/material.dart';

/// SafeSpend brand logo widget.
///
/// [onDark] = false → frosted glass (for dark/slate backgrounds)
/// [onDark] = true  → slate coin on dark background
class AppLogoWidget extends StatelessWidget {
  final double size;
  final bool onDark;

  const AppLogoWidget({super.key, this.size = 120, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.25,
      height: size * 1.25,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ambient glow
          Container(
            width: size * 1.25,
            height: size * 1.25,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.10),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Main logo container
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.22),
                  Colors.white.withOpacity(0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(size * 0.265),
              border: Border.all(
                color: Colors.white.withOpacity(0.40),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.20),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: CustomPaint(
              size: Size(size, size),
              painter: _LogoPainter(onDark: onDark, containerSize: size),
            ),
          ),

          // Top-right sparkle dot
          Positioned(
            top: size * 0.06,
            right: size * 0.06,
            child: Container(
              width: size * 0.09,
              height: size * 0.09,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final bool onDark;
  final double containerSize;

  const _LogoPainter({required this.onDark, required this.containerSize});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);
    final coinR = size.width * 0.34;

    // ── Coin outer ring ──────────────────────────────────────────────────────
    final ringPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = SweepGradient(
        colors: [
          Colors.white.withOpacity(0.70),
          Colors.white.withOpacity(0.35),
          Colors.white.withOpacity(0.55),
          Colors.white.withOpacity(0.25),
          Colors.white.withOpacity(0.70),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: coinR));

    canvas.drawCircle(center, coinR, ringPaint);

    // ── Coin inner face ──────────────────────────────────────────────────────
    final innerR = coinR * 0.84;
    final facePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        colors: [
          Colors.white.withOpacity(0.45),
          Colors.white.withOpacity(0.18),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: innerR));

    canvas.drawCircle(center, innerR, facePaint);

    // ── "S" lettermark ───────────────────────────────────────────────────────
    final sPainter = TextPainter(
      text: TextSpan(
        text: 'S',
        style: TextStyle(
          color: Colors.white,
          fontSize: size.width * 0.37,
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    sPainter.layout();
    sPainter.paint(
      canvas,
      Offset(cx - sPainter.width / 2, cy - sPainter.height / 2),
    );

    // ── Dollar-sign bars (two thin horizontal strokes through the S) ─────────
    final barPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.028
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(0.85);

    final barW = size.width * 0.12;
    final topBar = cy - size.width * 0.105;
    final botBar = cy + size.width * 0.105;

    canvas.drawLine(Offset(cx - barW, topBar), Offset(cx + barW, topBar), barPaint);
    canvas.drawLine(Offset(cx - barW, botBar), Offset(cx + barW, botBar), barPaint);

    // ── Shine highlight (crescent arc in top-left of coin) ───────────────────
    final shinePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        center: const Alignment(-0.6, -0.6),
        colors: [Colors.white.withOpacity(0.30), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: innerR));

    final path = Path()
      ..addArc(
        Rect.fromCircle(center: center, radius: innerR),
        math.pi * 1.15,
        math.pi * 0.5,
      );

    canvas.drawPath(path, shinePaint..style = PaintingStyle.stroke..strokeWidth = innerR * 0.35..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) =>
      oldDelegate.onDark != onDark;
}
