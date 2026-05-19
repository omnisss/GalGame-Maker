//场景装饰层，负责角色以外的装饰元素，如家具、天气效果等
import 'package:flutter/material.dart';
import '../scene_state.dart';

class SceneDecorLayer extends StatelessWidget {
  const SceneDecorLayer({super.key, required this.state});
  final DecorState state;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Positioned.fill(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 90,
            margin: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withOpacity(0.06),
            ),
            child: Center(
              child: Text(
                state.label,
                style: const TextStyle(color: Colors.white54),
              ),
            ),
          ),
        ),
      ),
    );
  }
}