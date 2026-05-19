import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 全局播报头像的故障艺术风特效
///
/// 设计目标：
/// 四种效果随机触发：
///    - RGB 分离
///    - 横向扫描行抖动
///    - 块状错位
///    - 波动式抖动
/// 扫描线作为轻微 CRT 质感
///
/// - 外层霓虹边框在 global_notice_host 中处理
/// - 本文件只负责头像内部画面效果
class NoticeAvatarGlitch extends StatefulWidget {
  const NoticeAvatarGlitch({
    super.key,
    required this.avatarPath,
    required this.accent,
    required this.fallbackLabel,
    this.width = 88,
    this.height = 88,
    this.radius = 22,
  });

  final String avatarPath;
  final Color accent;
  final String fallbackLabel;
  final double width;
  final double height;
  final double radius;

  @override
  State<NoticeAvatarGlitch> createState() => NoticeAvatarGlitchState();
}

enum _GlitchMode {
  rgbSplit,
  scanJitter,
  blockShift,
  waveWarp,
}

class _GlitchConfig {
  const _GlitchConfig({
    required this.mode,
    required this.duration,
    required this.intensity,
  });

  final _GlitchMode mode;

  /// 本次故障持续多久
  final Duration duration;

  /// 本次强度倍率，给各个效果内部乘一下
  final double intensity;
}


class NoticeAvatarGlitchState extends State<NoticeAvatarGlitch>
    with TickerProviderStateMixin {
  late final AnimationController _scanCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _glitchCtrl;

  Timer? _glitchTimer;
  final _rng = math.Random();

  _GlitchConfig? _activeGlitch;
  bool _glitchRunning = false;

  bool get _hasAvatar {
    final p = widget.avatarPath.trim();
    return p.isNotEmpty && File(p).existsSync();
  }

  File get _avatarFile => File(widget.avatarPath);

  @override
  void initState() {
    super.initState();

    // 缓慢扫描节奏：供扫描光/基础节奏使用
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    )..repeat();

    // 轻微呼吸：用于亮度浮动，避免完全静止
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // glitch 爆发控制器：每次短暂出现，然后回落
    _glitchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 190),
    );

    _scheduleNextGlitch();
  }

  void _scheduleNextGlitch() {
    _glitchTimer?.cancel();

    // 下一次触发前的随机等待时间
    final waitMs = 900 + _rng.nextInt(3200); // 0.9s ~ 4.1s

    _glitchTimer = Timer(Duration(milliseconds: waitMs), () async {
      if (!mounted || _glitchRunning) return;

      _glitchRunning = true;

      final config = _randomGlitchConfig();

      _activeGlitch = config;

      // 每次 glitch 都重新设置 duration
      _glitchCtrl.duration = config.duration;

      if (mounted) {
        setState(() {});
      }

      try {
        await _glitchCtrl.forward(from: 0);
      } finally {
        if (!mounted) return;

        _activeGlitch = null;
        _glitchRunning = false;
        setState(() {});

        // 这次结束后，再安排下一次
        _scheduleNextGlitch();
      }
    });
  }

  _GlitchConfig _randomGlitchConfig() {
    final mode = _GlitchMode.values[_rng.nextInt(_GlitchMode.values.length)];

    switch (mode) {
      case _GlitchMode.rgbSplit:
        return _GlitchConfig(
          mode: mode,
          duration: Duration(milliseconds: 90 + _rng.nextInt(140)), // 90~230
          intensity: 0.7 + _rng.nextDouble() * 0.7, // 0.7~1.4
        );

      case _GlitchMode.scanJitter:
        return _GlitchConfig(
          mode: mode,
          duration: Duration(milliseconds: 120 + _rng.nextInt(220)), // 120~340
          intensity: 0.9 + _rng.nextDouble() * 0.9, // 0.9~1.8
        );

      case _GlitchMode.blockShift:
        return _GlitchConfig(
          mode: mode,
          duration: Duration(milliseconds: 80 + _rng.nextInt(120)), // 80~200
          intensity: 1.0 + _rng.nextDouble() * 1.0, // 1.0~2.0
        );

      case _GlitchMode.waveWarp:
        return _GlitchConfig(
          mode: mode,
          duration: Duration(milliseconds: 180 + _rng.nextInt(260)), // 180~440
          intensity: 0.8 + _rng.nextDouble() * 0.8, // 0.8~1.6
        );
    }
  }

  @override
  void dispose() {
    _glitchTimer?.cancel();
    _scanCtrl.dispose();
    _pulseCtrl.dispose();
    _glitchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scanCtrl, _pulseCtrl, _glitchCtrl]),
      builder: (context, _) {
        final pulse = _pulseCtrl.value;
        final t = _glitchCtrl.value;

        // 做成“冲起 -> 回落”的包络
        final envelope = t < 0.5 ? (t * 2.0) : ((1.0 - t) * 2.0);

        // 当前 glitch 的强度倍率
        final intensity = _activeGlitch?.intensity ?? 0.0;

        // 最终强度
        final glitchPower = envelope * intensity;

        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.radius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 基础头像 / 占位
                _buildBaseAvatar(pulse),

                // 随机故障层
                if (_hasAvatar) ...[
                  if (_activeGlitch != null) ...[
                    switch (_activeGlitch!.mode) {
                      _GlitchMode.rgbSplit => _buildRgbSplitEffect(glitchPower),
                      _GlitchMode.scanJitter => _buildScanJitterEffect(glitchPower),
                      _GlitchMode.blockShift => _buildBlockShiftEffect(glitchPower),
                      _GlitchMode.waveWarp => _buildWaveWarpEffect(glitchPower),
                    },
                  ],
                ],

                // 轻微扫描线：只做 CRT 氛围，不做主体故障
                CustomPaint(
                  painter: _ScanlinePainter(
                    opacity: 0.05 + glitchPower * 0.03,
                  ),
                ),

                // 轻微顶部高光
                _buildTopGloss(),

                // 非常轻的扫描光带
                _buildSweepLight(glitchPower),

                // glitch 瞬间的小白闪
                if (glitchPower > 0.02)
                  _buildFlashOverlay(glitchPower),
              ],
            ),
          ),
        );
      },
    );
  }

  /// =========================
  /// 基础头像层
  /// =========================
  Widget _buildBaseAvatar(double pulse) {
    if (_hasAvatar) {
      // 轻微亮度呼吸，不做夸张变形
      final gain = 0.96 + pulse * 0.06;

      return ColorFiltered(
        colorFilter: ColorFilter.matrix([
          gain, 0, 0, 0, 0,
          0, gain, 0, 0, 0,
          0, 0, gain, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: Image.file(
          _avatarFile,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
      );
    }

    // 没有头像时的 fallback
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.accent.withValues(alpha: 0.58),
            widget.accent.withValues(alpha: 0.20),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        widget.fallbackLabel,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.98),
          fontWeight: FontWeight.w900,
          fontSize: 16,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  /// =========================
  /// 效果 1：RGB 分离故障
  ///
  /// 核心思想：
  /// - 原图正常显示
  /// - 再叠两层偏色图
  /// - 让红/青两层向左右轻微错位
  /// =========================
  Widget _buildRgbSplitEffect(double glitchPower) {
    final split = 1.5 + glitchPower * 6.5;

    Widget tintedLayer({
      required Color color,
      required double dx,
      required double opacity,
    }) {
      return Transform.translate(
        offset: Offset(dx, 0),
        child: Opacity(
          opacity: opacity,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(color, BlendMode.screen),
            child: Image.file(
              _avatarFile,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        tintedLayer(
          color: const Color(0xFFFF3348),
          dx: split,
          opacity: 0.16 + glitchPower * 0.18,
        ),
        tintedLayer(
          color: const Color(0xFF30D8FF),
          dx: -split,
          opacity: 0.14 + glitchPower * 0.16,
        ),
      ],
    );
  }

  /// =========================
  /// 效果 2：扫描行横向抖动
  ///
  /// 核心思想：
  /// - 把头像切成很多横条
  /// - 每条根据 y 与时间的组合做随机偏移
  /// - 不是给表面贴扫描线，而是“按行重采样”
  /// =========================
  Widget _buildScanJitterEffect(double glitchPower) {
    const sliceH = 3.0;
    final children = <Widget>[];
    final h = widget.height;
    final w = widget.width;
    final time = _scanCtrl.value * 10.0;

    for (double y = 0; y < h; y += sliceH) {
      final n = math.sin(y * 0.38 + time * 7.2) +
          math.cos(y * 0.18 - time * 5.1);

      double dx = 0.0;
      double opacity = 0.0;

      if (n.abs() > 1.12) {
        dx = n * (1.2 + glitchPower * 8.5);
        opacity = 0.12 + glitchPower * 0.30;
      }

      if (opacity <= 0.001) continue;

      children.add(
        Positioned(
          left: dx,
          top: y,
          width: w,
          height: sliceH,
          child: Opacity(
            opacity: opacity,
            child: ClipRect(
              child: Align(
                alignment: Alignment(0, (y / h) * 2 - 1),
                heightFactor: sliceH / h,
                child: SizedBox(
                  width: w,
                  height: h,
                  child: Image.file(
                    _avatarFile,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Stack(children: children);
  }

  /// =========================
  /// 效果 3：块状错位故障
  ///
  /// 核心思想：
  /// - 随机抽取几个矩形块
  /// - 每块内部重新取样并错位
  /// - 少量即可，太多会像贴图坏掉
  /// =========================
  Widget _buildBlockShiftEffect(double glitchPower) {
    final blocks = <Widget>[];
    final count = 2 + (glitchPower * 5).floor();

    for (int i = 0; i < count; i++) {
      final bw = 16.0 + _rng.nextDouble() * 32.0;
      final bh = 8.0 + _rng.nextDouble() * 18.0;
      final bx = _rng.nextDouble() * math.max(1, widget.width - bw);
      final by = _rng.nextDouble() * math.max(1, widget.height - bh);

      final dx = (-10 + _rng.nextDouble() * 20) * glitchPower;
      final dy = (-3 + _rng.nextDouble() * 6) * glitchPower;

      final blockOpacity = 0.14 + _rng.nextDouble() * 0.22;

      blocks.add(
        Positioned(
          left: bx,
          top: by,
          width: bw,
          height: bh,
          child: Opacity(
            opacity: blockOpacity,
            child: ClipRect(
              child: Transform.translate(
                offset: Offset(dx, dy),
                child: SizedBox(
                  width: widget.width,
                  height: widget.height,
                  child: Image.file(
                    _avatarFile,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // 偶尔给块加一层偏色，增强“数字错误感”
      if (_rng.nextBool()) {
        blocks.add(
          Positioned(
            left: bx,
            top: by,
            width: bw,
            height: bh,
            child: Opacity(
              opacity: 0.06 + glitchPower * 0.10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: (_rng.nextBool()
                          ? const Color(0xFFFF3B5C)
                          : const Color(0xFF31DFFF))
                      .withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
        );
      }
    }

    return Stack(children: blocks);
  }

  /// =========================
  /// 效果 4：波动式横向扭曲
  ///
  /// 核心思想：
  /// - 仍然按横条切片
  /// - 但位移不是跳变，而是波浪型连续变化
  /// - 并叠一点轻微 RGB 偏移
  /// =========================
  Widget _buildWaveWarpEffect(double glitchPower) {
    const sliceH = 2.5;
    final children = <Widget>[];
    final h = widget.height;
    final w = widget.width;
    final time = _scanCtrl.value * math.pi * 2.0;

    for (double y = 0; y < h; y += sliceH) {
      final wave1 = math.sin(y * 0.16 + time * 4.8);
      final wave2 = math.cos(y * 0.07 - time * 7.5);
      final dx = (wave1 * wave2) * (1.5 + glitchPower * 7.5);

      final localOpacity = 0.10 + glitchPower * 0.18;

      children.add(
        Positioned(
          left: dx,
          top: y,
          width: w,
          height: sliceH,
          child: Opacity(
            opacity: localOpacity,
            child: ClipRect(
              child: Align(
                alignment: Alignment(0, (y / h) * 2 - 1),
                heightFactor: sliceH / h,
                child: SizedBox(
                  width: w,
                  height: h,
                  child: Image.file(
                    _avatarFile,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // 波动模式下再叠一个非常轻的 RGB 偏移
    final split = 0.8 + glitchPower * 2.6;

    return Stack(
      fit: StackFit.expand,
      children: [
        Stack(children: children),
        Transform.translate(
          offset: Offset(split, 0),
          child: Opacity(
            opacity: 0.08 + glitchPower * 0.08,
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Color(0xFFFF4360),
                BlendMode.screen,
              ),
              child: Image.file(
                _avatarFile,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(-split, 0),
          child: Opacity(
            opacity: 0.07 + glitchPower * 0.07,
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Color(0xFF31DFFF),
                BlendMode.screen,
              ),
              child: Image.file(
                _avatarFile,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// =========================
  /// 顶部轻微高光
  /// =========================
  Widget _buildTopGloss() {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.08),
              Colors.white.withValues(alpha: 0.02),
              Colors.transparent,
            ],
            stops: const [0.0, 0.12, 0.32],
          ),
        ),
      ),
    );
  }

  /// =========================
  /// 轻微扫描光带
  ///
  /// 只是氛围，不需要太重
  /// =========================
  Widget _buildSweepLight(double glitchPower) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment(0, -1.10 + _scanCtrl.value * 2.20),
        child: Container(
          height: 12,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.accent.withValues(alpha: 0.00),
                widget.accent.withValues(alpha: 0.03 + glitchPower * 0.02),
                Colors.white.withValues(alpha: 0.06 + glitchPower * 0.03),
                widget.accent.withValues(alpha: 0.03 + glitchPower * 0.02),
                widget.accent.withValues(alpha: 0.00),
              ],
              stops: const [0.0, 0.24, 0.5, 0.76, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  /// =========================
  /// glitch 瞬间的小白闪
  /// =========================
  Widget _buildFlashOverlay(double glitchPower) {
    return IgnorePointer(
      child: Container(
        color: Colors.white.withValues(alpha: glitchPower * 0.05),
      ),
    );
  }
}

/// =========================
/// 轻量扫描线：弱 CRT 氛围
/// =========================
class _ScanlinePainter extends CustomPainter {
  const _ScanlinePainter({
    required this.opacity,
  });

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: opacity);

    const gap = 3.0;
    const lineH = 0.8;

    for (double y = 0; y < size.height; y += gap) {
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, lineH),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScanlinePainter oldDelegate) {
    return oldDelegate.opacity != opacity;
  }
}