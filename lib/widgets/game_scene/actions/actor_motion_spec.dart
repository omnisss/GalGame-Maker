import 'package:flutter/animation.dart';

class ActorPoseSpec {
  final double x;
  final double y;
  final double scale;
  final double rotation;
  final double opacity;
  final double downShiftFactor;

  final Duration duration;
  final Curve curve;

  const ActorPoseSpec({
    this.x = 0,
    this.y = 0,
    this.scale = 1,
    this.rotation = 0,
    this.opacity = 1,
    this.downShiftFactor = 0.60,
    this.duration = const Duration(milliseconds: 220),
    this.curve = Curves.easeOutCubic,
  });
}

class ActorActionStep {
  final double x;
  final double y;
  final double scale;
  final double rotation;
  final double opacity;
  final Duration duration;
  final Curve curve;

  const ActorActionStep({
    this.x = 0,
    this.y = 0,
    this.scale = 0,
    this.rotation = 0,
    this.opacity = 0,
    required this.duration,
    this.curve = Curves.linear,
  });
}

class ActorActionSpec {
  final List<ActorActionStep> steps;
  final bool resetAfterDone;

  const ActorActionSpec({
    required this.steps,
    this.resetAfterDone = true,
  });
}