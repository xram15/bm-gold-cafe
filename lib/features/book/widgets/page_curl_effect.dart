import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// ============================================================================
/// 📖 MOTEUR DE PLIAGE & ENROULEMENT DE PAGE 3D (PAGE CURL & BEND)
/// ============================================================================
/// Simule un pliage de page réaliste où la feuille se plie physiquement,
/// s'enroule vers l'extérieur (vers l'utilisateur), avec un arc cylindrique,
/// une ligne de pli diagonale naturelle, une crête de brillance lumineuse,
/// et une ombre portée douce sur la page du dessous.
/// ============================================================================

class PageCurlClipper extends CustomClipper<Path> {
  final double turnProgress; // 0.0 -> 1.0
  final bool isForward;

  PageCurlClipper({
    required this.turnProgress,
    required this.isForward,
  });

  @override
  Path getClip(Size size) {
    if (turnProgress <= 0.001) {
      return Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }
    if (turnProgress >= 0.999) {
      return Path(); // Page entièrement pliée et tournée
    }

    final double t = turnProgress;
    final path = Path();

    if (isForward) {
      // Pliage vers l'avant : la page se soulève depuis le bord droit
      // Angle diagonal naturel : le bas se plie légèrement plus vite que le haut
      final double xt = size.width * (1.0 - t * 0.92);
      final double xb = size.width * (1.0 - t * 1.18);
      // Courbure douce du pli (la feuille ne fait pas un trait droit)
      final double xc = (xt + xb) / 2 + size.width * 0.06 * sin(t * pi);
      final double yc = size.height * 0.5;

      path.moveTo(0, 0);
      path.lineTo(xt.clamp(0.0, size.width), 0);
      path.quadraticBezierTo(
        xc.clamp(0.0, size.width),
        yc,
        xb.clamp(0.0, size.width),
        size.height,
      );
      path.lineTo(0, size.height);
      path.close();
    } else {
      // Pliage vers l'arrière : la page précédente revient depuis la gauche
      final double xt = size.width * (t * 0.92);
      final double xb = size.width * (t * 1.18);
      final double xc = (xt + xb) / 2 - size.width * 0.06 * sin(t * pi);
      final double yc = size.height * 0.5;

      path.moveTo(size.width, 0);
      path.lineTo(xt.clamp(0.0, size.width), 0);
      path.quadraticBezierTo(
        xc.clamp(0.0, size.width),
        yc,
        xb.clamp(0.0, size.width),
        size.height,
      );
      path.lineTo(size.width, size.height);
      path.close();
    }

    return path;
  }

  @override
  bool shouldReclip(covariant PageCurlClipper oldClipper) {
    return oldClipper.turnProgress != turnProgress || oldClipper.isForward != isForward;
  }
}

/// Peintre du pli de papier, de la courbure cylindrique et de l'ombre portée
class PageCurlPainter extends CustomPainter {
  final double turnProgress;
  final bool isForward;
  final Color pageColor;
  final Color goldColor;

  PageCurlPainter({
    required this.turnProgress,
    required this.isForward,
    required this.pageColor,
    required this.goldColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (turnProgress <= 0.005 || turnProgress >= 0.995) return;

    final double t = turnProgress;
    final double sinT = sin(t * pi);

    // Points clés de la ligne de pli diagonale
    final double xt = isForward
        ? size.width * (1.0 - t * 0.92)
        : size.width * (t * 0.92);

    final double xb = isForward
        ? size.width * (1.0 - t * 1.18)
        : size.width * (t * 1.18);

    final double curveSign = isForward ? 1.0 : -1.0;
    final double xc = (xt + xb) / 2 + size.width * 0.06 * sinT * curveSign;
    final double yc = size.height * 0.5;

    // ── 1. OMBRE PORTÉE DU PLI SUR LA PAGE DU DESSOUS ────────────────────────
    // Quand le papier se plie et se courbe vers l'extérieur, il projette une ombre douce
    final double shadowWidth = size.width * 0.12 * sinT;
    final shadowPath = Path();

    if (isForward) {
      shadowPath.moveTo(xt, 0);
      shadowPath.quadraticBezierTo(xc, yc, xb, size.height);
      shadowPath.lineTo(xb + shadowWidth, size.height);
      shadowPath.quadraticBezierTo(xc + shadowWidth * 1.2, yc, xt + shadowWidth, 0);
      shadowPath.close();
    } else {
      shadowPath.moveTo(xt, 0);
      shadowPath.quadraticBezierTo(xc, yc, xb, size.height);
      shadowPath.lineTo(xb - shadowWidth, size.height);
      shadowPath.quadraticBezierTo(xc - shadowWidth * 1.2, yc, xt - shadowWidth, 0);
      shadowPath.close();
    }

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: (0.35 * sinT).clamp(0.0, 0.40))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(shadowPath, shadowPaint);

    // ── 2. LA PAGE QUI SE PLIE EN COURBURE CYLINDRIQUE (LE VOLET TOURNANT) ──
    // La largeur du volet plié s'enroulant vers l'extérieur
    final double foldWidth = size.width * (0.28 * sinT + 0.16 * (isForward ? t : (1.0 - t)));

    final flapPath = Path();
    final double flapXt = isForward ? xt - foldWidth : xt + foldWidth;
    final double flapXb = isForward ? xb - foldWidth : xb + foldWidth;
    final double flapXc = isForward ? xc - foldWidth * 1.08 : xc + foldWidth * 1.08;

    flapPath.moveTo(xt, 0);
    flapPath.quadraticBezierTo(xc, yc, xb, size.height);
    flapPath.lineTo(flapXb, size.height);
    flapPath.quadraticBezierTo(flapXc, yc, flapXt, 0);
    flapPath.close();

    // Fond de la feuille pliée (verso)
    final backColor = _getVersoColor(pageColor);
    final flapPaint = Paint()..color = backColor;
    canvas.drawPath(flapPath, flapPaint);

    // Filet doré décoratif le long de la tranche du volet plié
    final goldTrimPaint = Paint()
      ..color = goldColor.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final trimPath = Path();
    trimPath.moveTo(flapXt, 0);
    trimPath.quadraticBezierTo(flapXc, yc, flapXb, size.height);
    canvas.drawPath(trimPath, goldTrimPaint);

    // ── 3. DÉGRADÉ 3D DE CYLINDRE (EFFET DE COURBURE & BRILLANCE DU PAPIER) ─
    // Crée le relief volumétrique de la page qui se courbe vers l'extérieur
    final Offset startGradient = isForward ? Offset(xt, 0) : Offset(xt, 0);
    final Offset endGradient = isForward ? Offset(flapXt, 0) : Offset(flapXt, 0);

    final cylinderGradient = Paint()
      ..shader = ui.Gradient.linear(
        startGradient,
        endGradient,
        [
          // Ombre au creux du pli
          Colors.black.withValues(alpha: 0.30 * sinT),
          // Sommet du pli cylindrique : Brillance blanche vers l'extérieur
          Colors.white.withValues(alpha: 0.35 * sinT),
          // Corps de la page
          Colors.black.withValues(alpha: 0.05),
          // Tranche extérieure
          Colors.black.withValues(alpha: 0.22 * sinT),
        ],
        const [0.0, 0.22, 0.65, 1.0],
      );
    canvas.drawPath(flapPath, cylinderGradient);

    // ── 4. LIGNE LUMINEUSE AU FAÎTE DU PLI (CRÊTE BLANCHE DU PAPIER) ─────────
    final crestPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.40 * sinT)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    final crestPath = Path();
    final double crestOffset = isForward ? -4.0 : 4.0;
    crestPath.moveTo(xt + crestOffset, 0);
    crestPath.quadraticBezierTo(xc + crestOffset, yc, xb + crestOffset, size.height);
    canvas.drawPath(crestPath, crestPaint);
  }

  Color _getVersoColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    // Verso légèrement texturé plus riche
    return hsl
        .withLightness((hsl.lightness * 0.94).clamp(0.08, 0.92))
        .toColor();
  }

  @override
  bool shouldRepaint(covariant PageCurlPainter oldDelegate) {
    return oldDelegate.turnProgress != turnProgress ||
        oldDelegate.isForward != isForward ||
        oldDelegate.pageColor != pageColor;
  }
}

