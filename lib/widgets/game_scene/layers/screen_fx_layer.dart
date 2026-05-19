//全局效果层，负责全局的屏幕特效，如扫描线、暗角等
import 'package:flutter/material.dart';
import '../scene_state.dart';

class ScreenFxLayer extends StatelessWidget {
  const ScreenFxLayer({super.key, required this.state});
  final ScreenFxState state;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: CustomPaint(
        painter: _FxPainter(state),
        size: Size.infinite,
      ),
    );
  }
}

class _FxPainter extends CustomPainter {
  final ScreenFxState s;
  _FxPainter(this.s);

  @override
  void paint(Canvas canvas, Size size) {
    // 占位：轻微的透明遮罩 + 简单扫描线
    final base = Paint()..color = Colors.black.withOpacity(0.08);
    canvas.drawRect(Offset.zero & size, base);

    if (s.scanline) {
      final p = Paint()..color = Colors.white.withOpacity(0.03);
      for (double y = 0; y < size.height; y += 3) {
        canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), p);
      }
    }

    if (s.vignette) {
      final vignette = Paint()..color = Colors.black.withOpacity(0.12);
      // 超简化：四边框遮罩占位
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 18), vignette);
      canvas.drawRect(Rect.fromLTWH(0, size.height - 18, size.width, 18), vignette);
      canvas.drawRect(Rect.fromLTWH(0, 0, 18, size.height), vignette);
      canvas.drawRect(Rect.fromLTWH(size.width - 18, 0, 18, size.height), vignette);
    }
  }

  @override
  bool shouldRepaint(covariant _FxPainter oldDelegate) => oldDelegate.s != s;
}