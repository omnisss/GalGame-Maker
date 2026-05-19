//这里负责指令->动作参数的翻译
import 'package:flutter/material.dart';
import 'actor_motion_spec.dart';

class ActorMotionTranslator {
  const ActorMotionTranslator._();

  // posture 翻译层
  static ActorPoseSpec? translatePosture(String? posture) {
    final p = (posture ?? '').trim();

    switch (p) {
      case '正常':
        return const ActorPoseSpec(
          x: 0,
          y: 0,
          scale: 1,
          rotation: 0,
          opacity: 1,
          duration: Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      case '靠近':
        return const ActorPoseSpec(
          x: 0,
          y: 0,
          scale: 1.8,
          rotation: 0,
          opacity: 1,
          downShiftFactor: 0.75,
        );
      case '远离':
        return const ActorPoseSpec(
          x: 0,
          y: 0,
          scale: 0.70,
          rotation: 0,
          opacity: 1,
          downShiftFactor: 0.40,
        );
      default:
        return null;
    }
  }

  // action 翻译层
  static ActorActionSpec? translateAction(String? action) {
    final a = (action ?? '').trim();

    switch (a) {
      case '跳':
        return const ActorActionSpec(
          steps: [
            // 起跳：向上
            ActorActionStep(
              y: 0.16,
              duration: Duration(milliseconds: 160),
              curve: Curves.easeOut,
            ),
            // 落下：回归
            ActorActionStep(
              y: 0.0,
              duration: Duration(milliseconds: 200),
              curve: Curves.easeIn,
            ),
          ],
          resetAfterDone: true,
        );

      default:
        return null;
    }
  }
}