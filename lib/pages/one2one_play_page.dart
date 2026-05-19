import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';

import '../api/ws_client.dart';
import '../stores/one2one_game_store.dart';
import 'package:path/path.dart' as p;
import '../widgets/one2one/one2one_asset_store.dart';
import '../stores/connection_store.dart';
import '../widgets/one2one/one2one_save_state_store.dart';

//GameScene
import '../widgets/game_scene/game_scene.dart';
import '../widgets/game_scene/scene_state.dart';
import '../stores/game_notice_store.dart';



class One2OnePlayPage extends StatelessWidget {
  const One2OnePlayPage({
    super.key,
    required this.roleId,
    this.startMode = "auto",
  });
  final String roleId;
  final String startMode; // auto | fresh | resume

  @override
  Widget build(BuildContext context) {
    final ws = context.read<WsClient>();
    final notice = context.read<GameNoticeStore>();

    return ChangeNotifierProvider(
      create: (_) => One2OneGameStore(ws, roleId, notice)..start(mode: startMode),
      child: _One2OnePlayBody(roleId: roleId),
    );
  }
}

class _One2OnePlayBody extends StatefulWidget {
  const _One2OnePlayBody({required this.roleId});
  final String roleId;

  @override
  State<_One2OnePlayBody> createState() => _One2OnePlayBodyState();
}


class _One2OnePlayBodyState extends State<_One2OnePlayBody> {
  String? _roleRootPath; // 缓存 one2one/<roleId> 根目录
  late One2OneGameStore _gameStore; //缓存context

  //右键控制对话框和topUI是否显示
  bool _hideDialogue = false; 
  bool _hideTopUi = false;   
  void _onSecondaryClick() {
    setState(() {
      final nextHidden = !(_hideDialogue && _hideTopUi);
      _hideDialogue = nextHidden;
      _hideTopUi = nextHidden;
    });
  }

  //初始化
  @override
  void initState() {
    super.initState();
     _gameStore = context.read<One2OneGameStore>();
    _initRoleRoot();
  }
  Future<void> _initRoleRoot() async {
    final dir = await One2OneAssetStore.roleRoot(widget.roleId);
    if (!mounted) return;
    setState(() => _roleRootPath = dir.path);
  }

  //格式化游戏时间
  String _two(int v) => v.toString().padLeft(2, '0');
  Map<String, int> _readGameTime(Map<String, dynamic> rt) {
    final raw = rt["gameTime"];
    if (raw is Map) {
      return {
        "year": (raw["year"] as num?)?.toInt() ?? 2026,
        "month": (raw["month"] as num?)?.toInt() ?? 1,
        "day": (raw["day"] as num?)?.toInt() ?? 1,
        "hour": (raw["hour"] as num?)?.toInt() ?? 0,
        "minute": (raw["minute"] as num?)?.toInt() ?? 0,
      };
    }
    return {
      "year": 2026,
      "month": 3,
      "day": 9,
      "hour": 21,
      "minute": 40,
    };
  }

  //
  String _absFromRel(String rel) {
    final root = _roleRootPath;
    if (root == null) return '';
    final r = rel.trim();
    if (r.isEmpty) return '';
    // runtime 里推荐存 "assets/xxx/yyy.png"
    if (r.startsWith('assets/')) return p.join(root, r);
    // 过渡兼容：如果已经是绝对路径则原样返回
    if (r.startsWith('/') || r.contains(':\\') || r.contains(':/')) return r;
    return ''; // 其它情况先不给（仍显示占位）
  }

  @override
  void dispose() {
    _gameStore.disposeStore();
    super.dispose();
  }

  SceneState _mapToSceneState(
    One2OneGameStore g,
    ConnectionStore conn,
  ) {
    final rt = g.runtime;

    final bgRel = (rt["bgPath"] ?? "").toString();
    final spRel = (rt["spritePath"] ?? "").toString();

    final bgAbs = _absFromRel(bgRel);
    final spAbs = _absFromRel(spRel);

    final gt = _readGameTime(rt);
    final timeText = "${_two(gt["hour"]!)}:${_two(gt["minute"]!)}";
    final dateText = "${gt["year"]}/${_two(gt["month"]!)}/${_two(gt["day"]!)}";

    // historyTail：只存最后一回合
    final hist = (rt["historyTail"] as List?) ?? const [];
    String speaker = "■■■";
    String text = "看到这条消息就说明你碰到bug了哦";

    if (hist.length == 2) {
      // 一回合（user + assistant）时：只显示 AI 的回复
      final a = (hist[1] as Map).cast<String, dynamic>();
      speaker = (a["name"] ?? "AI").toString();
      text = (a["text"] ?? "").toString(); // 不拼名字、不拼“你：”
    } else if (hist.length == 1) {
      // 只有一条时：可能是 user（AI未回）或 assistant
      final last = (hist[0] as Map).cast<String, dynamic>();
      final role = (last["role"] ?? "").toString();

      if (role == "assistant") {
        speaker = (last["name"] ?? "AI").toString();
        text = (last["text"] ?? "").toString();
      } else {
        // user：只在 AI 回复前短暂显示
        speaker = "你";
        text = (last["text"] ?? "").toString();
      }
    } else {
      speaker = "■■■";
      text = "看到这条消息就说明你碰到bug了哦";
    }

    return SceneState(
      bg: BackgroundState(
        label: bgRel.isEmpty ? "Background" : bgRel,
        filePath: bgAbs, 
      ),
      actors: ActorsState(items: [
        ActorState(
          id: "actor",
          name: spRel.isEmpty ? "Actor" : spRel,
          spritePath: spAbs,

          baseX: g.actorBaseX,
          baseY: g.actorBaseY,
          baseScale: g.actorBaseScale,
          baseRotation: g.actorBaseRotation,
          baseOpacity: g.actorBaseOpacity,
          baseDownShiftFactor: g.actorBaseDownShiftFactor,

          actionX: g.actorActionX,
          actionY: g.actorActionY,
          actionScale: g.actorActionScale,
          actionRotation: g.actorActionRotation,
          actionOpacity: g.actorActionOpacity,

          posture: g.actorPosture,
        ),
      ]),
      //
      dialogue: DialogueState(
        speaker: speaker,
        text: text,
        show: !_hideDialogue,

        // 左侧logo/头像：你想“说话时显示头像”就传 spAbs 或者头像路径
        avatarPath: '', // 先空：显示LOGO占位；
        
        //输入框锁定/解锁
        inputEnabled: !g.isWaitingReply && !g.isWaitingOpeningReply,

        // 把发送逻辑移植给新输入框
        onSubmit: (t) => g.sendUserText(t),

        // 右侧竖按钮（先留空）
        onSettings: () =>_onSettingsTap(g),
        onEdit: () =>_onEditTap(g),
        onLog: () {},
      ),

      topUi: TopUiState(
        timeText: timeText,
        dateText: dateText,
        //locationText: backgroundNameFromRuntimeOrLastMsg, //显示当前场景，先留着
        statusText: "/WS: ${conn.wsConnected ? "OK" : "OFF"} / ${conn.httpRttMs < 0 ? "--" : "${conn.httpRttMs}ms"} / #${g.lastMsgId}",
        show: !_hideTopUi,
        //onMenuTap: () {},
      ),
    );
  }
  //设置按钮
  Future<void> _onSettingsTap(One2OneGameStore g) async {
    await One2OneSaveStateStore.saveGamingSnapshot(widget.roleId, g.runtime);
    if (!mounted) return;
    Navigator.of(context).pop();
  }
  //编辑按钮
  Future<void> _onEditTap(One2OneGameStore g) async {
    await One2OneSaveStateStore.saveGamingSnapshot(widget.roleId, g.runtime);

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      '/one2one',
      arguments: {
        'roleId': widget.roleId,
        'fromGaming': true,
        'initialPage': 1,
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Consumer2<One2OneGameStore, ConnectionStore>(
      builder: (context, g, conn, _) {
        if (!g.loaded) {
          return const Scaffold(
            body: _One2OneLoadingView(
              title: '正在进入世界...',
              subtitle: '正在准备角色与场景资源',
            ),
          );
        }

        if (g.isWaitingOpeningReply) {
          return Scaffold(
            body: _One2OneLoadingView(
              title: '正在等待角色开场...',
              subtitle: '首回合生成中，请稍候',
            ),
          );
        }

        final scene = _mapToSceneState(g, conn);
        return Scaffold(
          body: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) {
              if (event.kind == PointerDeviceKind.mouse &&
                  (event.buttons & kSecondaryMouseButton) != 0) {
                _onSecondaryClick();
              }
            },
            child: GameScene(state: scene),
          ),
        );
      },
    );
  }
}

class _One2OneLoadingView extends StatelessWidget {
  const _One2OneLoadingView({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF120F1F),
            Color(0xFF1A1630),
            Color(0xFF0E0B18),
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.16),
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 30,
                    spreadRadius: 2,
                    color: Colors.black.withValues(alpha: 0.28),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 14,
                      height: 1.45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}