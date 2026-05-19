import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class PendantLayer extends StatefulWidget {
  final ValueListenable<Rect?> phoneFrameRectListenable;
  final ValueListenable<Offset?> anchorPxListenable;
  final Offset fallbackAnchorPx;
  final List<String> itemAssets;

  const PendantLayer({
    super.key,
    required this.phoneFrameRectListenable,
    required this.anchorPxListenable,
    this.fallbackAnchorPx = const Offset(36, 72),
    this.itemAssets = const [
      'assets/pendant/item1.png',
      'assets/pendant/item2.png',
      'assets/pendant/item3.png',
      'assets/pendant/item4.png',
    ],
  });

  @override
  State<PendantLayer> createState() => _PendantLayerState();
}

class _PendantLayerState extends State<PendantLayer> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  // --- verlet points ---
  final List<_Point> rope = [];
  late _Point ring;
  late final List<_Point> items;

  // --- tuning ---
  static const int segCount = 20;
  static const double gravity = 1400.0;
  static const double damping = 0.985;
  static const int iterations = 10;
  static const double ropeLen = 22.0;

  Size _size = Size.zero;

  // images
  final List<ui.Image?> _imgs = [null, null, null, null];
  bool _loading = false;

  // ---- interaction state ----
  bool _dragActive = false;     // 是否启用“交互层”
  int? _dragIndex;              // rope点索引，或 1000+item索引
  Offset _lastDragPos = Offset.zero; 
  late final List<int> attachIndex; // 每个挂件挂在哪一段绳子上

  @override
  void initState() {
    super.initState();
    _initSim();

    _ticker = createTicker(_tick)..start();
    widget.phoneFrameRectListenable.addListener(_onRectChanged);
    _loadImages();
  }

  @override
  void dispose() {
    widget.phoneFrameRectListenable.removeListener(_onRectChanged);
    _ticker.dispose();
    super.dispose();
  }

  void _onRectChanged() {
    // anchor 每帧会更新，无需 setState
  }

  Future<void> _loadImages() async {
    if (_loading) return;
    _loading = true;
    try {
      for (int i = 0; i < 4; i++) {
        final data = await DefaultAssetBundle.of(context).load(widget.itemAssets[i]);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        _imgs[i] = frame.image;
      }
    } catch (_) {
      // ignore; fallback to circles
    } finally {
      _loading = false;
      if (mounted) setState(() {});
    }
  }

  void _initSim() {
    rope.clear();
    final a = widget.fallbackAnchorPx;

    rope.add(_Point(a, pinned: true));
    for (int i = 1; i <= segCount; i++) {
      rope.add(_Point(a + Offset(0, ropeLen * i)));
    }

    ring = _Point(rope.last.pos + const Offset(0, 18));

    attachIndex = [5, 10, 15, 20]; //分布在绳子上（不要超过 segCount）

    items = List.generate(4, (i) {
      final base = rope[attachIndex[i]].pos;
      return _Point(base);
    });
  }

  /*Offset _anchorPx() {
    final rect = widget.phoneFrameRectListenable.value;
    if (rect == null) return widget.fallbackAnchorPx;

    // 1) 计算 fit: BoxFit.contain 的缩放
    final sx = rect.width / widget.designSize.width;
    final sy = rect.height / widget.designSize.height;
    final s = math.min(sx, sy);

    // 2) 计算图片真实绘制区域（在容器内居中 + 留边）
    final imgW = widget.designSize.width * s;
    final imgH = widget.designSize.height * s;
    final imgTopLeft = rect.topLeft + Offset(
      (rect.width - imgW) / 2,
      (rect.height - imgH) / 2,
    );

    // 3) 把“设计稿坐标（挂孔中心）”映射到屏幕
    return imgTopLeft + Offset(
      widget.anchorOffsetInFrame.dx * s,
      widget.anchorOffsetInFrame.dy * s,
    );
  }*/
  Offset _anchorPx() {
    return widget.anchorPxListenable.value ?? widget.fallbackAnchorPx;
  }



  void _tick(Duration now) {
    if (_last == Duration.zero) {
      _last = now;
      return;
    }
    final dt = (now - _last).inMicroseconds / 1e6;
    _last = now;

    if (_size == Size.zero) return;

    _step(dt.clamp(0.0, 1 / 20));
    // 只有画面刷新，不影响下层 UI
    setState(() {});
  }

  void _step(double dt) {
    // anchor 固定
    rope[0].pos = _anchorPx();
    rope[0].prev = rope[0].pos;

    // 拖拽点锁定
    if (_dragActive && _dragIndex != null) {
      final idx = _dragIndex!;
      if (idx >= 0 && idx < rope.length) {
        rope[idx].pos = _lastDragPos;
        rope[idx].prev = _lastDragPos;
      } else {
        final itemIdx = idx - 1000;
        if (itemIdx >= 0 && itemIdx < items.length) {
          items[itemIdx].pos = _lastDragPos;
          items[itemIdx].prev = _lastDragPos;
        }
      }
    }

    // integrate
    for (int i = 1; i < rope.length; i++) rope[i].verlet(dt);
    ring.verlet(dt);
    for (final it in items) it.verlet(dt);

    // gravity
    for (int i = 1; i < rope.length; i++) rope[i].acc += const Offset(0, gravity);
    ring.acc += const Offset(0, gravity);
    for (final it in items) it.acc += const Offset(0, gravity);

    // constraints
    for (int k = 0; k < iterations; k++) {
      for (int i = 0; i < rope.length - 1; i++) {
        _constrainDist(rope[i], rope[i + 1], ropeLen);
      }

      // ring 跟绳尾
      _constrainDist(rope.last, ring, 18);

      // 每个挂件挂在绳子不同段上
      for (int i = 0; i < items.length; i++) {
        final idx = attachIndex[i].clamp(1, rope.length - 1);
        _constrainDist(rope[idx], items[i], 6); // 6=挂坠垂下长度，可调
      }
      // 挂件之间的碰撞（可选）
      final rItem = _itemRadius();
      // 1) 挂件之间互撞
      for (int i = 0; i < items.length; i++) {
        for (int j = i + 1; j < items.length; j++) {
          _separateCircles(items[i], items[j], rItem, rItem);
        }
      }

      // 2) 挂件和 ring 碰撞（可选）
      for (final it in items) {
        _separateCircles(ring, it, 10, rItem);
      }

      //可选：挂件之间再串起来（让它们相互牵制更“串”）
      /*for (int i = 0; i < items.length - 1; i++) {
        _constrainDist(items[i], items[i + 1], 52); // 52=挂件间距，可调
      }*/

      for (int i = 1; i < rope.length; i++) rope[i].clampTo(_size);
      ring.clampTo(_size);
      for (final it in items) it.clampTo(_size);

      rope[0].pos = _anchorPx();
    }

    // damping
    for (int i = 1; i < rope.length; i++) rope[i].applyDamping(damping);
    ring.applyDamping(damping);
    for (final it in items) it.applyDamping(damping);
  }

  // 计算挂坠大小：跟手机框架宽度相关，画面越大挂坠越大
  double _itemRadius() {
    final base = widget.phoneFrameRectListenable.value?.width ?? _size.width;
    final itemSize = (base * 0.14).clamp(56.0, 110.0);
    return itemSize * 0.5; // 可以调，越大碰撞箱越大
  }

  // 圆形碰撞分离函数
  void _separateCircles(_Point a, _Point b, double ra, double rb) {
    final dx = b.pos.dx - a.pos.dx;
    final dy = b.pos.dy - a.pos.dy;
    final dist2 = dx * dx + dy * dy;
    final minDist = ra + rb;

    if (dist2 <= 1e-6) {
      if (!a.pinned) a.pos = a.pos + Offset(-minDist * 0.5, 0);
      if (!b.pinned) b.pos = b.pos + Offset(minDist * 0.5, 0);
      return;
    }

    final dist = math.sqrt(dist2);
    if (dist >= minDist) return;

    final overlap = (minDist - dist);
    final nx = dx / dist;
    final ny = dy / dist;

    final aMove = a.pinned ? 0.0 : 0.5;
    final bMove = b.pinned ? 0.0 : 0.5;

    final off = Offset(nx * overlap, ny * overlap);
    a.pos = a.pos - off * aMove;
    b.pos = b.pos + off * bMove;
  }

  void _constrainDist(_Point a, _Point b, double len) {
    final dx = b.pos.dx - a.pos.dx;
    final dy = b.pos.dy - a.pos.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 1e-6) return;
    final diff = (dist - len) / dist;

    final aMove = a.pinned ? 0.0 : 0.5;
    final bMove = b.pinned ? 0.0 : 0.5;

    final off = Offset(dx * diff, dy * diff);
    a.pos = a.pos + off * aMove;
    b.pos = b.pos - off * bMove;
  }

  int? _hitTest(Offset p) {
    // 命中范围跟 itemSize 相关，画面越大命中越大
    final base = widget.phoneFrameRectListenable.value?.width ?? _size.width;
    final itemSize = (base * 0.18).clamp(56.0, 110.0);
    final itemR = itemSize * 0.55;

    for (int i = 0; i < items.length; i++) {
      if ((items[i].pos - p).distance < itemR) return 1000 + i;
    }

    for (int i = 1; i < rope.length; i++) {
      if ((rope[i].pos - p).distance < 24) return i;
    }
    // ring 也可抓
    if ((ring.pos - p).distance < 22) return 999; // ring special
    return null;
  }

  void _kickOnRelease(int idx, Velocity v) {
    final impulse = v.pixelsPerSecond * 0.0022;

    if (idx == 999) {
      ring.kick(impulse);
      return;
    }

    if (idx >= 0 && idx < rope.length) {
      rope[idx].kick(impulse);
    } else {
      final itemIdx = idx - 1000;
      if (itemIdx >= 0 && itemIdx < items.length) items[itemIdx].kick(impulse);
    }
  }

  // 关键：只有“命中”才激活交互层
  /*void _tryActivateDrag(Offset downPos) {
    final idx = _hitTest(downPos);
    if (idx == null) return;

    _dragActive = true;
    _dragIndex = idx;
    _lastDragPos = downPos;
    setState(() {}); // 打开交互层
  }*/

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        _size = Size(c.maxWidth, c.maxHeight);

        return Stack(
          children: [
            // A) 永远可见的渲染层：不吃任何事件（不挡手机）
            IgnorePointer(
              ignoring: true,
              child: CustomPaint(
                painter: _PendantPainter(
                  rope: rope,
                  ring: ring,
                  items: items,
                  images: _imgs,
                  phoneRect: widget.phoneFrameRectListenable.value,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            // B') 单层交互，和下面的方式不同：一次按下即可拖拽（不需要第二次）
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,

                onPanStart: (d) {
                  final idx = _hitTest(d.localPosition);
                  if (idx == null) {
                    // 没点中挂坠：不进入拖拽
                    _dragActive = false;
                    _dragIndex = null;
                    return;
                  }
                  // 点中：立刻开始拖拽（同一次手势）
                  _dragActive = true;
                  _dragIndex = idx;
                  _lastDragPos = d.localPosition;
                },

                onPanUpdate: (d) {
                  if (!_dragActive) return;
                  _lastDragPos = d.localPosition;
                },

                onPanEnd: (d) {
                  if (!_dragActive) return;
                  final idx = _dragIndex;
                  if (idx != null) _kickOnRelease(idx, d.velocity);

                  _dragActive = false;
                  _dragIndex = null;
                },

                onPanCancel: () {
                  _dragActive = false;
                  _dragIndex = null;
                },

                child: const SizedBox.expand(),
              ),
            ),

            // B) 命中检测层：只负责 pointer down 探测，尽量不抢交互
            // 用 Listener 的 onPointerDown 来“尝试激活”，并且 behavior translucent
            /*Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (e) {
                  // 只有命中才会 setState 打开 _dragActive，之后才会真正拦截
                  _tryActivateDrag(e.localPosition);
                },
                child: const SizedBox.expand(),
              ),
            ),

            // C) 真正交互层：只有 _dragActive 才存在（存在期间它会吃掉移动/抬起）
            if (_dragActive)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanUpdate: (d) {
                    _lastDragPos = d.localPosition;
                  },
                  onPanEnd: (d) {
                    final idx = _dragIndex;
                    if (idx != null) _kickOnRelease(idx, d.velocity);

                    _dragActive = false;
                    _dragIndex = null;
                    setState(() {});
                  },
                  onPanCancel: () {
                    _dragActive = false;
                    _dragIndex = null;
                    setState(() {});
                  },
                  child: const SizedBox.expand(),
                ),
              ),*/
          ],
        );
      },
    );
  }
}

class _Point {
  Offset pos;
  Offset prev;
  Offset acc = Offset.zero;
  final bool pinned;

  _Point(this.pos, {this.pinned = false}) : prev = pos;

  void verlet(double dt) {
    if (pinned) return;
    final vel = pos - prev;
    final next = pos + vel + acc * (dt * dt);
    prev = pos;
    pos = next;
    acc = Offset.zero;
  }

  void applyDamping(double d) {
    if (pinned) return;
    final vel = pos - prev;
    prev = pos - vel * d;
  }

  void clampTo(Size s) {
    if (pinned) return;
    pos = Offset(
      pos.dx.clamp(0.0, s.width),
      pos.dy.clamp(0.0, s.height),
    );
  }

  void kick(Offset impulse) {
    if (pinned) return;
    prev = prev - impulse;
  }
}

class _PendantPainter extends CustomPainter {
  final List<_Point> rope;
  final _Point ring;
  final List<_Point> items;
  final List<ui.Image?> images;
  final Rect? phoneRect;

  _PendantPainter({
    required this.rope,
    required this.ring,
    required this.items,
    required this.images,
    required this.phoneRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF2B2B2B);

    final path = Path()..moveTo(rope.first.pos.dx, rope.first.pos.dy);
    for (int i = 1; i < rope.length; i++) {
      path.lineTo(rope[i].pos.dx, rope[i].pos.dy);
    }
    path.lineTo(ring.pos.dx, ring.pos.dy);
    canvas.drawPath(path, paint);

    canvas.drawCircle(ring.pos, 6.5, Paint()..color = const Color(0xFF333333));

    final base = phoneRect != null ? phoneRect!.width : size.width;
    final itemSize = (base * 0.18).clamp(56.0, 110.0);

    for (int i = 0; i < items.length; i++) {
      final p = items[i].pos;
      final img = images[i];

      if (img != null) {
        final dst = Rect.fromCenter(center: p, width: itemSize, height: itemSize);
        final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
        canvas.drawImageRect(img, src, dst, Paint());
      } else {
        canvas.drawCircle(p, itemSize * 0.32, Paint()..color = const Color(0xFFFFC857));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PendantPainter oldDelegate) => true;
}
