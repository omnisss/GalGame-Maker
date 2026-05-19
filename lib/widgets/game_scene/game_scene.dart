//渲染各层
import 'package:flutter/material.dart';
import 'scene_state.dart';

import 'layers/screen_fx_layer.dart';
import 'layers/background_layer.dart';
import 'layers/scene_decor_layer.dart';
import 'layers/actor_layer.dart';
import 'layers/action_overlay_layer.dart';
import 'layers/dialogue_layer.dart';
import 'layers/top_ui_layer.dart';

class GameScene extends StatelessWidget {
  const GameScene({
    super.key,
    required this.state,
  });

  final SceneState state;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // [0] Screen FX 全局效果（最底层也可放最顶层，看你是“覆盖”还是“底色调”）
        //ScreenFxLayer(state: state.fx),

        // [1] 背景
        BackgroundLayer(state: state.bg),

        // [2] 场景装饰（后）
        //SceneDecorLayer(state: state.decorBack),

        // [3] 角色层
        ActorLayer(state: state.actors),

        // [4] 场景装饰（前）
        //SceneDecorLayer(state: state.decorFront),

        // [5] 局部演出特效层
        //ActionOverlayLayer(state: state.actionFx),

        // [6] 对话层
        if (state.dialogue.show)
          DialogueLayer(state: state.dialogue),

        // [7] 顶层 UI
        if (state.topUi.show)
          TopUiLayer(state: state.topUi),
      ],
    );
  }
}