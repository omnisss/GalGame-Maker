//背景层，负责背景图
import 'dart:io';
import 'package:flutter/material.dart';
import '../scene_state.dart';

class BackgroundLayer extends StatelessWidget {
  const BackgroundLayer({super.key, required this.state});
  final BackgroundState state;

  @override
  Widget build(BuildContext context) {
    final path = state.filePath.trim();
    final exists = path.isNotEmpty && File(path).existsSync();

    return Positioned.fill(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,

        // 让 AnimatedSwitcher 内部的 Stack 强制铺满背景，以免背景图尺寸变化时导致布局抖动
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },

        child: SizedBox.expand(
          key: ValueKey(exists ? path : 'fallback_${state.label}'),
          child: exists
              ? Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.high,
                )
              : _fallback(),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111827), Color(0xFF0B1020)],
        ),
      ),
      child: Center(
        child: Text(
          state.label,
          style: const TextStyle(fontSize: 20, color: Colors.white54),
        ),
      ),
    );
  }
}