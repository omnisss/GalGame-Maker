import 'dart:ui';
import 'package:flutter/material.dart';
//import 'game_theme.dart';
import 'game_fx.dart';
import 'home_left_rail.dart';
import 'home_right_panel.dart';
import '../one2one/one2one_asset_store.dart';
import '../one2one/one2one_persona_store.dart';
import '../one2one/one2one_save_state_store.dart';

enum HomeRootTab { start, load, settings }
enum LoadTab { story, one2one }

class HomeRoot extends StatefulWidget {
  final bool wsOk;
  final int rttMs;

  const HomeRoot({
    super.key,
    required this.wsOk,
    required this.rttMs,
  });

  @override
  State<HomeRoot> createState() => _HomeRootState();
}

class _HomeRootState extends State<HomeRoot> {
  HomeRootTab _root = HomeRootTab.start;
  LoadTab _load = LoadTab.story;
  //假数据
  final List<SaveEntry> _storySaves = const [
    SaveEntry(id: "S-01", title: "存档 A", subtitle: "校园 · Day 3 · 下午"),
    SaveEntry(id: "S-02", title: "存档 B", subtitle: "社团 · Day 12 · 放学后"),
    SaveEntry(id: "S-03", title: "存档 C", subtitle: "祭典 · Night"),
  ];

  //one2one 存档列表需要根据 roleId 从磁盘读取
  List<SaveEntry> _one2oneSaves = const [];
  bool _loadingO2O = false;

  //初始化
  @override
  void initState() {
    super.initState();
    _refreshOne2OneSaves(); 
  }
  //
  Future<void> _refreshOne2OneSaves() async {
    if (_loadingO2O) return;
    setState(() => _loadingO2O = true);

    try {
      final roleIds = await One2OneAssetStore.listRoleIds();

      final items = <SaveEntry>[];
      for (final roleId in roleIds) {
        // 1) 读人设（用于标题）
        String title = roleId;
        try {
          final persona = await One2OnePersonaStore.loadPersona(roleId);
          final name = (persona?['name'] as String?)?.trim();
          if (name != null && name.isNotEmpty) title = name;
        } catch (_) {
          // persona 读不到也不要紧，title 退化为 roleId
        }

        // 2) 读存档状态（用于“草稿/进行中”）
        final state = await One2OneSaveStateStore.load(roleId);
        final mode = One2OneSaveStateStore.activeModeOf(state); // 'draft' | 'gaming'

        // 3) 取对应的更新时间戳
        final int? ts = mode == 'draft'
            ? (state['draftSnapshot']?['updatedAt'] as int?)
            : (state['gamingSnapshot']?['updatedAt'] as int?);

        final timeText = _formatUpdatedAtTs(ts);
        final modeText = mode == 'draft' ? '草稿' : '进行中';
        final subtitle = timeText == null ? modeText : '$modeText · $timeText';

        items.add(SaveEntry(id: roleId, title: title, subtitle: subtitle));
      }

      if (!mounted) return;
      setState(() => _one2oneSaves = items);
    } finally {
      if (!mounted) return;
      setState(() => _loadingO2O = false);
    }
  }
  //时间格式化
  String? _formatUpdatedAtTs(int? ts) {
    if (ts == null || ts <= 0) return null;
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000).toLocal();
      String two(int v) => v.toString().padLeft(2, '0');
      return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
    } catch (_) {
      return null;
    }
  }
  //
  @override
  Widget build(BuildContext context) {
    final rttText = widget.rttMs < 0 ? "--" : "${widget.rttMs}ms";

    return Stack(
      children: [
        BackgroundImageLayer(assetPath: 'assets/bg/home.png'),
        const GameFxLayer(),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Row(
              children: [
                HomeLeftRail(
                  root: _root,
                  loadTab: _load,
                  wsOk: widget.wsOk,
                  rttText: rttText,
                  onSelectRoot: (r) => setState(() => _root = r),

                  // 切到 one2one 的读取存档页时，刷新一次列表
                  onSelectLoadTab: (t) {
                    setState(() {
                      _root = HomeRootTab.load;
                      _load = t;
                    });
                    if (t == LoadTab.one2one) {
                      _refreshOne2OneSaves();
                    }
                  },
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: HomeRightPanel(
                    root: _root,
                    loadTab: _load,
                    storySaves: _storySaves,

                    // ✅ 改为动态列表
                    one2oneSaves: _one2oneSaves,

                    onStartStory: () => Navigator.of(context).pushNamed("/story"),
                    //onStartOne2One: () => Navigator.of(context).pushNamed("/one2one"),

                    // 分配新 ID 后跳转到编辑页
                    onStartOne2One: () async {
                      /*final id = await One2OneIdStore.allocate(); // int
                      final roleId = id.toString();*/
                      Navigator.of(context).pushNamed(
                        "/one2one",
                        //arguments: {"roleId": roleId},
                      ).then((_) => _refreshOne2OneSaves());
                    },

                    onOpenSave: (entry) async {
                      if (_load == LoadTab.story) {
                        Navigator.of(context).pushNamed("/story");
                      } else {
                        final roleId = entry.id;

                        // 读存档状态：决定去编辑还是去游戏
                        final state = await One2OneSaveStateStore.load(roleId);
                        final mode = One2OneSaveStateStore.activeModeOf(state);

                        if (mode == 'gaming') {
                          Navigator.of(context)
                              .pushNamed("/one2one_play", arguments: {"roleId": roleId})
                              .then((_) => _refreshOne2OneSaves());
                        } else {
                          Navigator.of(context)
                              .pushNamed("/one2one", arguments: {"roleId": roleId})
                              .then((_) => _refreshOne2OneSaves());
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SaveEntry {
  final String id;
  final String title;
  final String subtitle;

  const SaveEntry({
    required this.id,
    required this.title,
    required this.subtitle,
  });
}

//背景图层，负责显示背景图、模糊和压暗效果
class BackgroundImageLayer extends StatelessWidget {
  final String assetPath; // 例如 'assets/bg/home.jpg'
  final BoxFit fit;
  final double dim; // 压暗强度 0~1（越大越暗）
  final double blur; // 模糊强度

  const BackgroundImageLayer({
    super.key,
    required this.assetPath,
    this.fit = BoxFit.cover,
    this.dim = 0.45,
    this.blur = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          // 背景图
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              alignment: Alignment.center,
              child: Image.asset(assetPath),
            ),
          ),

          // 模糊（可选）
          if (blur > 0)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: Container(color: Colors.transparent),
              ),
            ),

          // 压暗罩层（让 UI 更清晰）
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(dim)),
          ),
        ],
      ),
    );
  }
}
