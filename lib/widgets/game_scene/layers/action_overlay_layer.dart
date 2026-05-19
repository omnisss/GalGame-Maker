//演出效果层，负责角色的气泡，颜表情等
import 'package:flutter/material.dart';
import '../scene_state.dart';

class ActionOverlayLayer extends StatelessWidget {
  const ActionOverlayLayer({super.key, required this.state});
  final ActionFxState state;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Positioned.fill(
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              state.label,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }
}