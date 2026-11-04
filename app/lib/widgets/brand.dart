import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Vector take on the RedCross Connect+ mark (orange arc, red cross, green hands).
/// Drawn in code so the app needs no image assets.
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: size, height: size, child: CustomPaint(painter: _LogoPainter()));
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;

    canvas.drawArc(
      Rect.fromLTWH(w * .04, h * .04, w * .92, h * .92),
      math.pi * 1.02,
      math.pi * .96,
      false,
      Paint()
        ..color = const Color(0xFFFF6A00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .05
        ..strokeCap = StrokeCap.round,
    );

    final red = Paint()..color = const Color(0xFFE60000);
    final arm = w * .13;
    final len = w * .36;
    final c = Offset(w * .5, h * .36);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: arm, height: len), Radius.circular(arm * .2)), red);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: len, height: arm), Radius.circular(arm * .2)), red);

    final green = Paint()..color = const Color(0xFF2E9A1F);
    Path leaf(bool left) {
      double x(double v) => w * (left ? v : 1 - v);
      return Path()
        ..moveTo(x(.50), h * .90)
        ..quadraticBezierTo(x(.16), h * .88, x(.12), h * .56)
        ..quadraticBezierTo(x(.30), h * .70, x(.50), h * .74)
        ..close();
    }

    canvas.drawPath(leaf(true), green);
    canvas.drawPath(leaf(false), green);
    canvas.drawPath(
      Path()
        ..moveTo(w * .22, h * .72)
        ..quadraticBezierTo(w * .5, h * 1.0, w * .78, h * .72)
        ..quadraticBezierTo(w * .5, h * .86, w * .22, h * .72)
        ..close(),
      green,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Logo + "REDCROSS / Connect+" wordmark.
class BrandLockup extends StatelessWidget {
  final double logoSize;
  final Color connectColor;
  const BrandLockup({super.key, this.logoSize = 110, this.connectColor = const Color(0xFFC7B4B4)});

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        AppLogo(size: logoSize),
        const SizedBox(height: 6),
        Text('REDCROSS', style: TextStyle(color: C.logoRed, fontSize: logoSize * .22, fontWeight: FontWeight.w800, height: 1.1)),
        Text('Connect+', style: TextStyle(color: connectColor, fontSize: logoSize * .2, fontWeight: FontWeight.w800, height: 1.1)),
      ]);
}

/// White text with a black outline (the "SAVE LIVES" / "NOW !" treatment).
class OutlinedText extends StatelessWidget {
  final String text;
  final double size;
  final double stroke;
  final TextAlign align;
  const OutlinedText(this.text, {super.key, this.size = 40, this.stroke = 5, this.align = TextAlign.center});

  @override
  Widget build(BuildContext context) => Stack(alignment: Alignment.center, children: [
        Text(text,
            textAlign: align,
            style: display(size).copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = stroke
                ..strokeJoin = StrokeJoin.round
                ..color = Colors.black,
            )),
        Text(text, textAlign: align, style: display(size, color: const Color(0xFFEDEDED))),
      ]);
}
