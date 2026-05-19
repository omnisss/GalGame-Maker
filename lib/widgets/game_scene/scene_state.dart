// 场景状态，包含各层的状态数据
import 'package:flutter/foundation.dart';

@immutable
class SceneState {
  final ScreenFxState fx;
  final BackgroundState bg;
  final DecorState decorBack;
  final ActorsState actors;
  final DecorState decorFront;
  final ActionFxState actionFx;
  final DialogueState dialogue;
  final TopUiState topUi;

  const SceneState({
    this.fx = const ScreenFxState(),
    this.bg = const BackgroundState(),
    this.decorBack = const DecorState(label: 'DecorBack'),
    this.actors = const ActorsState(),
    this.decorFront = const DecorState(label: 'DecorFront'),
    this.actionFx = const ActionFxState(),
    this.dialogue = const DialogueState(),
    this.topUi = const TopUiState(),
  });

  SceneState copyWith({
    ScreenFxState? fx,
    BackgroundState? bg,
    DecorState? decorBack,
    ActorsState? actors,
    DecorState? decorFront,
    ActionFxState? actionFx,
    DialogueState? dialogue,
    TopUiState? topUi,
  }) {
    return SceneState(
      fx: fx ?? this.fx,
      bg: bg ?? this.bg,
      decorBack: decorBack ?? this.decorBack,
      actors: actors ?? this.actors,
      decorFront: decorFront ?? this.decorFront,
      actionFx: actionFx ?? this.actionFx,
      dialogue: dialogue ?? this.dialogue,
      topUi: topUi ?? this.topUi,
    );
  }
}

@immutable
class ScreenFxState {
  final bool scanline;
  final bool vignette;
  final bool grain;
  const ScreenFxState({this.scanline = true, this.vignette = true, this.grain = false});
}

@immutable
class BackgroundState {
  final String label;     // debug/兜底显示
  final String filePath;  // 绝对路径（优先使用）
  const BackgroundState({
    this.label = 'Background',
    this.filePath = '',
  });
}

@immutable
class DecorState {
  final String label;
  const DecorState({required this.label});
}

@immutable
class ActorsState {
  final List<ActorState> items;
  const ActorsState({this.items = const []});
}

@immutable
class ActorState {
  final String id;
  final String name;
  final String spritePath;

  // ===== posture：常驻基态 =====
  final double baseX;
  final double baseY;
  final double baseScale;
  final double baseRotation;
  final double baseOpacity;
  final double baseDownShiftFactor; //立绘下沉比例，默认0.6（即60%）

  // ===== action：临时动作层 =====
  final double actionX;
  final double actionY;
  final double actionScale;
  final double actionRotation;
  final double actionOpacity;

  final double dim;

  // 便于调试 / 存档 / 后续扩展
  final String posture;

  const ActorState({
    required this.id,
    required this.name,
    this.spritePath = '',

    this.baseX = 0,
    this.baseY = 0,
    this.baseScale = 1,
    this.baseRotation = 0,
    this.baseOpacity = 1,
    this.baseDownShiftFactor = 0.60,

    this.actionX = 0,
    this.actionY = 0,
    this.actionScale = 0,
    this.actionRotation = 0,
    this.actionOpacity = 0,

    this.dim = 0,
    this.posture = '正常',
  });

  double get x => baseX + actionX;
  double get y => baseY + actionY;
  double get scale => baseScale + actionScale;
  double get rotation => baseRotation + actionRotation;
  double get opacity => (baseOpacity + actionOpacity).clamp(0.0, 1.0);
  double get downShiftFactor => baseDownShiftFactor;
}

@immutable
class ActionFxState {
  final String label;
  const ActionFxState({this.label = 'ActionFx'});
}

@immutable
class DialogueState {
  final String speaker;
  final String text;
  final bool show;  //是否显示

  // 预留：头像（绝对路径或未来资源系统路径都行）
  final String avatarPath;
  
  // 输入框
  final String inputHint;
  final bool inputEnabled;
  final ValueChanged<String>? onSubmit; //把发送能力传进来

  // 底部按钮回调（可空）
  final VoidCallback? onSettings;
  final VoidCallback? onEdit;
  final VoidCallback? onLog;

  const DialogueState({
    this.speaker = 'System',
    this.text = '（对话层占位）',
    this.show = true,
    this.avatarPath = '',
    this.inputHint = '输入...',
    this.inputEnabled = true,
    this.onSubmit,
    this.onSettings,
    this.onEdit,
    this.onLog,
  });
}

@immutable
class TopUiState {
  final String timeText;     // 时间：例21:40
  final String dateText;     // 日期：例2026/03/09
  final String statusText;   // WS: OK / lastMsgId: 101
  final String locationText; // 可选：教室-晚上
  final bool showMenuButton;
  final bool show;  //是否显示
  //final VoidCallback? onMenuTap;

  const TopUiState({
    this.timeText = '00:00',
    this.dateText = '0000/00/00',
    this.statusText = 'WS: - / Ping: -',
    this.locationText = '',
    this.show = true, 
    this.showMenuButton = true,
    //this.onMenuTap,
  });
}