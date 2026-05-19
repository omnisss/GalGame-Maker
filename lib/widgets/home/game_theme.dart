import 'dart:ui';
import 'package:flutter/material.dart';

class GameTheme {
  // 校园清新：粉蓝+奶白
  static const bgA = Color(0xFFF7FBFF); // 奶白偏蓝
  static const bgB = Color(0xFFFFF6FB); // 奶白偏粉
  static const bgC = Color(0xFFEFF7FF); // 浅蓝

  static const accentBlue = Color(0xFF5AA8FF);
  static const accentPink = Color(0xFFFEAE92);
  static const accentMint = Color(0xFF56D6C9);

  static Color fg([double o = 1]) => const Color(0xFF1F2A44).withValues(alpha: o);
  static Color muted([double o = 1]) => const Color(0xFF5B6B88).withValues(alpha: o);

  static LinearGradient bgGradient() => const LinearGradient(
        colors: [bgA, bgB, bgC],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static BoxDecoration card({
    double radius = 22,
    double opacity = 0.62,
    double borderOpacity = 0.35,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: borderOpacity)),
      boxShadow: [
        BoxShadow(
          blurRadius: 22,
          offset: const Offset(0, 12),
          color: Colors.black.withValues(alpha: 0.08),
        ),
      ],
    );
  }

  static BoxDecoration selectedGlow({
    required double radius,
    required Color a,
    required Color b,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        colors: [a.withValues(alpha: 0.20), b.withValues(alpha: 0.14)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  static Widget blur({required Widget child, double sigma = 14, double radius = 22}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: child,
      ),
    );
  }
  //标题
  static TextStyle title(BuildContext context) => TextStyle(
        fontSize: fontH(context, 0.030, min: 20, max: 34),
        fontWeight: FontWeight.w900,
        color: fg(0.92),
      );

  //左上角标题
  static TextStyle h2(BuildContext context) => TextStyle(
        fontSize: fontH(context, 0.020, min: 14, max: 20),
        fontWeight: FontWeight.w900,
        color: fg(0.90),
      );

  //副标题
  static TextStyle body(BuildContext context) => TextStyle(
        fontSize: fontH(context, 0.0175, min: 13, max: 18),
        height: 1.4,
        color: muted(0.85),
        fontWeight: FontWeight.w600,
      );

  //选项副标题
  static TextStyle tiny(BuildContext context) => TextStyle(
        fontSize: fontH(context, 0.015, min: 10, max: 20),
        color: muted(0.75),
        fontWeight: FontWeight.w600,
      );

  // 按屏幕高度比例缩放字号，并限制上下界，默认选用
  // ratio: 例如 0.030 表示 fontSize = screenHeight * 0.030 ，也就是字体大小为屏幕高度的 3%
  static double fontH(
    BuildContext context,
    double ratio, {
    double min = 12,
    double max = 40,
  }) {
    final h = MediaQuery.of(context).size.height;
    final v = h * ratio;
    return v.clamp(min, max).toDouble();
  }

  /// 可选：按屏幕最短边缩放（更适合横竖屏都一致）
  static double fontS(
    BuildContext context,
    double ratio, {
    double min = 12,
    double max = 40,
  }) {
    final s = MediaQuery.of(context).size.shortestSide;
    final v = s * ratio;
    return v.clamp(min, max).toDouble();
  }
  //================= one2one 模式相关样式 ==================
  // one2one 模式下的AI按钮样式
  static Widget one2oneGradientButton({
    required VoidCallback onPressed,
    required Widget child,
    EdgeInsets padding =
        const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentPink.withValues(alpha: 0.95),
            accentPink.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: accentPink.withValues(alpha: 0.35),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: onPressed,
        child: child,
      ),
    );
  }
  // 普通按钮：白底 + 主题色文字 + 轻边框（用于 上传/添加 等）
  static ButtonStyle one2oneSoftButtonStyle({
    EdgeInsets padding =
        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    double radius = 18,
  }) {
    return OutlinedButton.styleFrom(
      foregroundColor: accentPink,
      backgroundColor: Colors.white.withOpacity(0.65),
      padding: padding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      side: BorderSide(
        color: accentPink.withOpacity(0.35),
        width: 1,
      ),
    );
  }
  // 文字按钮：主题色文字（用于编辑/删除）
  static ButtonStyle one2oneTextButtonStyle({
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    double radius = 14,
  }) {
    return TextButton.styleFrom(
      foregroundColor: accentPink,
      padding: padding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
