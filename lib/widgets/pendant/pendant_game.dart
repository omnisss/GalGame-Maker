//这个东西翻车了，留给有缘人吧
/*import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flame/components.dart' hide Vector2;
import 'package:flame/events.dart'; // ✅ DragStartInfo / DragUpdateInfo 等在这里
import 'package:flame/input.dart' hide Vector2;

import 'package:flame_forge2d/flame_forge2d.dart';

class PendantGame extends Forge2DGame with PanDetector {
  final ValueListenable<Rect?> phoneFrameRectListenable;
  final Offset fallbackAnchorPx;
  final Offset anchorOffsetInFrame;

  // ✅ 自己保存一个 zoom，避免版本差异导致类里没有 zoom 字段
  static const double kZoom = 10.0;
  @override
  Color backgroundColor() => Colors.transparent;

  PendantGame({
    required this.phoneFrameRectListenable,
    required this.fallbackAnchorPx,
    required this.anchorOffsetInFrame,
  }) : super(
          gravity: Vector2(0, 18),
          zoom: kZoom,
        );

  late Body anchor;
  final List<Body> rope = [];
  final List<Body> items = [];
  Body? _dragBody;
  Body? _boundsBody;

  MouseJoint? _mouseJoint;


  @override
  Future<void> onLoad() async {
    await super.onLoad();
    Body? _boundsBody;


    final a = _pxToWorld(Vector2(fallbackAnchorPx.dx, fallbackAnchorPx.dy));
    anchor = world.createBody(
      BodyDef()
        ..type = BodyType.static
        ..position = a,
    );

    _buildRopeAndItems();

    add(RopeRender(anchor: anchor, rope: rope));
    add(ItemsRender(items: items));
  }

    @override
    void onGameResize(Vector2 size) {
      super.onGameResize(size);
      _recreateBounds(size);
    }
    void _recreateBounds(Vector2 sizePx) {
    // 删除旧边界
    if (_boundsBody != null) {
      world.destroyBody(_boundsBody!);
      _boundsBody = null;
    }

    if (sizePx.x <= 0 || sizePx.y <= 0) return;

    final w = _pxToWorld(sizePx).x;
    final h = _pxToWorld(sizePx).y;

    final ground = world.createBody(BodyDef()..type = BodyType.static);
    ground.createFixture(FixtureDef(EdgeShape()..set(Vector2(0, 0), Vector2(w, 0))));
    ground.createFixture(FixtureDef(EdgeShape()..set(Vector2(0, h), Vector2(w, h))));
    ground.createFixture(FixtureDef(EdgeShape()..set(Vector2(0, 0), Vector2(0, h))));
    ground.createFixture(FixtureDef(EdgeShape()..set(Vector2(w, 0), Vector2(w, h))));

    _boundsBody = ground;
  }



  @override
  void update(double dt) {
    super.update(dt);
    _syncAnchorToPhoneFrame();
  }

  void _syncAnchorToPhoneFrame() {
    final rect = phoneFrameRectListenable.value;
    final Offset anchorPx =
        rect == null ? fallbackAnchorPx : (rect.topLeft + anchorOffsetInFrame);

    final wp = _pxToWorld(Vector2(anchorPx.dx, anchorPx.dy));
    anchor.setTransform(wp, 0);
  }

  void _buildRopeAndItems() {
    const int segCount = 14;
    const double segRadius = 0.12;

    Body prev = anchor;

    for (int i = 0; i < segCount; i++) {
      final b = world.createBody(
        BodyDef()
          ..type = BodyType.dynamic
          ..position = anchor.position + Vector2(0, 0.28 * (i + 1))
          ..linearDamping = 0.2
          ..angularDamping = 0.6,
      );

      b.createFixture(
        FixtureDef(
          CircleShape()..radius = segRadius,
          density: 0.7,
          friction: 0.2,
          restitution: 0.1,
        ),
      );

      rope.add(b);

      // ✅ createJoint 要传 Joint，不是 JointDef
      final djd = DistanceJointDef()
        ..initialize(prev, b, prev.position, b.position)
        ..length = (b.position - prev.position).length
        ..frequencyHz = 6.0
        ..dampingRatio = 0.25;

      world.createJoint(DistanceJoint(djd));

      prev = b;
    }

    final ring = _createItemBody(prev.position + Vector2(0, 0.35), radius: 0.18);
    items.add(ring);

    final ringDef = DistanceJointDef()
      ..initialize(prev, ring, prev.position, ring.position)
      ..length = (ring.position - prev.position).length
      ..frequencyHz = 5.0
      ..dampingRatio = 0.3;

    world.createJoint(DistanceJoint(ringDef));

    final offsets = <Vector2>[
      Vector2(-0.45, 0.45),
      Vector2(0.45, 0.45),
      Vector2(-0.25, 0.95),
      Vector2(0.25, 0.95),
    ];

    for (final off in offsets) {
      final b = _createItemBody(ring.position + off, radius: 0.22);
      items.add(b);

      final def = DistanceJointDef()
        ..initialize(ring, b, ring.position, b.position)
        ..length = off.length
        ..frequencyHz = 4.5
        ..dampingRatio = 0.25;

      world.createJoint(DistanceJoint(def));
    }
  }

  Body _createItemBody(Vector2 pos, {required double radius}) {
    final b = world.createBody(
      BodyDef()
        ..type = BodyType.dynamic
        ..position = pos
        ..linearDamping = 0.15
        ..angularDamping = 0.8,
    );

    b.createFixture(
      FixtureDef(
        CircleShape()..radius = radius,
        density: 1.0,
        friction: 0.6,
        restitution: 0.15,
      ),
    );

    return b;
  }

  void _createBounds() {
    final s = canvasSize;
    if (s.x == 0 || s.y == 0) return;

    final w = _pxToWorld(s).x;
    final h = _pxToWorld(s).y;

    final ground = world.createBody(BodyDef()..type = BodyType.static);

    ground.createFixture(FixtureDef(EdgeShape()..set(Vector2(0, 0), Vector2(w, 0))));
    ground.createFixture(FixtureDef(EdgeShape()..set(Vector2(0, h), Vector2(w, h))));
    ground.createFixture(FixtureDef(EdgeShape()..set(Vector2(0, 0), Vector2(0, h))));
    ground.createFixture(FixtureDef(EdgeShape()..set(Vector2(w, 0), Vector2(w, h))));
  }

  // -------- 拖拽：PanDetector --------
  @override
  void onPanStart(DragStartInfo info) {
    final p = screenToWorld(info.eventPosition.global);
    final hit = _hitTest(p);
    if (hit == null) return;

    _dragBody = hit;

    final mjd = MouseJointDef()
      ..bodyA = anchor
      ..bodyB = hit
      ..target.setFrom(p)
      ..maxForce = 2000.0 * hit.mass
      ..frequencyHz = 8.0
      ..dampingRatio = 0.9;

    // ✅ 更通用：先 new MouseJoint 再 createJoint（少 cast，少踩坑）
    _mouseJoint = MouseJoint(mjd);
    world.createJoint(_mouseJoint!);
    hit.setAwake(true);
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    final j = _mouseJoint;
    if (j == null) return;
    j.setTarget(screenToWorld(info.eventPosition.global));
  }

  @override
  void onPanEnd(DragEndInfo info) {
    final j = _mouseJoint;
    if (j != null) {
      world.destroyJoint(j);
      _mouseJoint = null;

      final b = _dragBody;
      if (b != null) {
        final v = info.velocity; // px/s
        final impulse = Vector2(v.x, v.y) * 0.002;
        b.applyLinearImpulse(impulse);
      }
    }
    _dragBody = null;
  }

  Body? _hitTest(Vector2 p) {
    Body? best;
    double bestD2 = 1e9;

    for (final b in [...rope, ...items]) {
      final d2 = (b.position - p).length2;
      if (d2 < bestD2) {
        bestD2 = d2;
        best = b;
      }
    }
    return bestD2 < 0.25 ? best : null;
  }

  Vector2 _pxToWorld(Vector2 px) => px / kZoom;
}

// --- 绳子渲染 ---
class RopeRender extends Component with HasGameRef<PendantGame> {
  final Body anchor;
  final List<Body> rope;

  RopeRender({required this.anchor, required this.rope});

  final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFF2B2B2B);

  @override
  void render(Canvas canvas) {
    final pts = <Offset>[];
    pts.add(gameRef.worldToScreen(anchor.position).toOffset());
    for (final b in rope) {
      pts.add(gameRef.worldToScreen(b.position).toOffset());
    }

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(path, _paint);
  }
}

// --- 挂件渲染（圆占位）---
class ItemsRender extends Component with HasGameRef<PendantGame> {
  final List<Body> items;

  ItemsRender({required this.items});

  final Paint _p = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xFFFFC857);

  @override
  void render(Canvas canvas) {
    for (final b in items) {
      final p = gameRef.worldToScreen(b.position).toOffset();
      canvas.drawCircle(p, 18, _p);
    }
  }
}*/
