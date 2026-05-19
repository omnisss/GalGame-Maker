import 'dart:math' as math;
import 'package:flutter/material.dart';

class GameFxLayer extends StatelessWidget {
  const GameFxLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _SchoolFxPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _SchoolFxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 光斑（阳光感）
    void blob(Offset c, double r, Color color, double o) {
      final p = Paint()
        ..shader = RadialGradient(
          colors: [color.withOpacity(o), Colors.transparent],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r));
      canvas.drawCircle(c, r, p);
    }

    blob(Offset(size.width * 0.18, size.height * 0.22), size.shortestSide * 0.22, const Color(0xFFFFC7DD), 0.35);
    blob(Offset(size.width * 0.78, size.height * 0.18), size.shortestSide * 0.26, const Color(0xFFBFE3FF), 0.33);
    blob(Offset(size.width * 0.72, size.height * 0.72), size.shortestSide * 0.30, const Color(0xFFCFF7F2), 0.25);

    // 极淡暗角（让中心更聚焦）
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withOpacity(0.06)],
        stops: const [0.65, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.45),
        radius: math.max(size.width, size.height) * 0.75,
      ));
    canvas.drawRect(Offset.zero & size, vignette);

    // 细噪点（非常淡，像纸张颗粒）
    final dotPaint = Paint()..color = Colors.black.withOpacity(0.015);
    final rnd = math.Random(3);
    final dots = (size.width * size.height / 22000).clamp(60, 180).toInt();
    for (int i = 0; i < dots; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), rnd.nextDouble() * 0.9 + 0.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
