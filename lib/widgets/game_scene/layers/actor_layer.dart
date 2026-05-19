// 立绘（角色）层：保持正常大小 + 整体下移露出上半身
import 'dart:io';
import 'package:flutter/material.dart';
import '../scene_state.dart';

class ActorLayer extends StatelessWidget {
  const ActorLayer({super.key, required this.state});
  final ActorsState state;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;

          // 立绘高度：跟随屏幕高度，参数越大占屏幕越多
          final baseSpriteH = h * 2.2;

          final actors = state.items.isEmpty
              ? const [
                  ActorState(
                    id: 'demo',
                    name: 'Actor (placeholder)',
                    baseX: 0,
                    baseY: 0,
                    baseScale: 1,
                    baseRotation: 0,
                    baseOpacity: 1,
                    actionX: 0,
                    actionY: 0,
                    actionScale: 0,
                    actionRotation: 0,
                    actionOpacity: 0,
                    posture: '正常',
                  ),
                ]
              : state.items;

          return Stack(
            children: [
              for (final a in actors)
                _ActorSprite(
                  actor: a,
                  screenW: w,
                  baseSpriteH: baseSpriteH,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ActorSprite extends StatelessWidget {
  const _ActorSprite({
    required this.actor,
    required this.screenW,
    required this.baseSpriteH,
  });

  final ActorState actor;
  final double screenW;
  final double baseSpriteH;

  @override
  Widget build(BuildContext context) {
    final sprite = actor.spritePath.trim();
    final exists = sprite.isNotEmpty && File(sprite).existsSync();

    // x：你的 ActorState.x 约定为 -1..1（你现在是 0.0）
    final ax = actor.x.clamp(-1.0, 1.0);

    // 立绘大小随 scale（默认 1）
    final spriteH = baseSpriteH * actor.scale;

    // 每个 posture 自己决定露出比例
    final baseDownShift = spriteH * actor.downShiftFactor; //默认0.6，即立绘下移60%，露出40%

    //下移隐藏底部（正值是往下）
    // y：作为“微调”，建议范围 -0.2..0.2（负数=再往下，正数=往上露更多）
    final fine = (actor.y.clamp(-1.0, 1.0)) * (MediaQuery.of(context).size.height * 0.05);
    final downShift = baseDownShift - fine;
    //
    return Align(
      alignment: Alignment(ax * 0.70, 1.0),
      child: Transform.translate(
        offset: Offset(0, downShift),
        child: Transform.rotate(
          angle: actor.rotation,
          alignment: Alignment.bottomCenter,
          child: Opacity(
            opacity: (actor.opacity * (1.0 - actor.dim)).clamp(0.15, 1.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: exists
                  ? OverflowBox(
                      key: ValueKey(sprite),
                      alignment: Alignment.bottomCenter,
                      minHeight: 0,
                      maxHeight: spriteH, // 允许比屏幕高
                      minWidth: 0,
                      maxWidth: double.infinity,
                      child: SizedBox(
                        height: spriteH,
                        child: Image.file(
                          File(sprite),
                          fit: BoxFit.fitHeight,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    )
                  : _fallbackCard(actor.name),
            )
          ),
        ),
      ),
    );
  }

  Widget _fallbackCard(String name) {
    return Container(
      key: ValueKey('fallback_$name'),
      width: 220,
      height: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white24),
        color: Colors.white.withValues(alpha: 0.08),
      ),
      alignment: Alignment.center,
      child: Text(name, style: const TextStyle(color: Colors.white70)),
    );
  }
}