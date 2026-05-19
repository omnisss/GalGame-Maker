//通用动作层，接收翻译层的参数并渲染
import 'dart:async';
import 'package:flutter/material.dart';
import 'actor_motion_spec.dart';

typedef MotionNotify = void Function();

class ActorMotionRuntime {
  ActorMotionRuntime({
    required MotionNotify onChanged,
  }) : _onChanged = onChanged;

  final MotionNotify _onChanged;

  Timer? _actionTimer;

  // ===== posture：常驻基态 =====
  double baseX = 0;
  double baseY = 0;
  double baseScale = 1;
  double baseRotation = 0;
  double baseOpacity = 1;
  double baseDownShiftFactor = 0.60; //立绘下沉比例，默认0.6（即60%）

  // ===== action：临时动作层 =====
  double actionX = 0;
  double actionY = 0;
  double actionScale = 0;
  double actionRotation = 0;
  double actionOpacity = 0;

  String currentPosture = '正常';

  void dispose() {
    _actionTimer?.cancel();
  }

  // 应用常驻姿态
  Future<void> applyPose(ActorPoseSpec spec, {String postureName = '正常'}) async {
    currentPosture = postureName;

    baseX = spec.x;
    baseY = spec.y;
    baseScale = spec.scale;
    baseRotation = spec.rotation;
    baseOpacity = spec.opacity;
    baseDownShiftFactor = spec.downShiftFactor;

    _onChanged();
  }

  // 播放一次性动作
  Future<void> playAction(ActorActionSpec spec) async {
    _actionTimer?.cancel();

    for (final step in spec.steps) {
      actionX = step.x;
      actionY = step.y;
      actionScale = step.scale;
      actionRotation = step.rotation;
      actionOpacity = step.opacity;

      _onChanged();

      await Future.delayed(step.duration);
    }

    if (spec.resetAfterDone) {
      resetAction();
    }
  }

  void resetAction() {
    actionX = 0;
    actionY = 0;
    actionScale = 0;
    actionRotation = 0;
    actionOpacity = 0;
    _onChanged();
  }
}