import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/home/game_theme.dart';
import '../widgets/one2one/one2one_models.dart';
import '../widgets/one2one/one2one_persona_panel.dart';
import 'package:path/path.dart' as p;
import '../widgets/one2one/one2one_asset_store.dart';
import '../widgets/one2one/one2one_sprites_panel.dart';
import '../widgets/one2one/one2one_backgrounds_panel.dart';
import '../widgets/one2one/one2one_persona_store.dart';
import '../api/api_client.dart';
import '../widgets/one2one/one2one_save_state_store.dart';
import '../widgets/one2one/one2one_id_store.dart';
import '../stores/game_notice_store.dart';

class One2OneEditPage extends StatefulWidget {
  const One2OneEditPage({
    super.key,
    required this.roleId,
  });

  final String? roleId;

  @override
  State<One2OneEditPage> createState() => _One2OneEditPageState();
}

class _One2OneEditPageState extends State<One2OneEditPage> {
  final nameCtrl = TextEditingController();
  final personaCtrl = TextEditingController();
  /*final greetingCtrl = TextEditingController();
  final styleCtrl = TextEditingController();
  final tabooCtrl = TextEditingController();*/
  //final String roleId = 'demo_role';
  //String get roleId => widget.roleId;
  String? _roleId; 
  String get roleIdDisplay => _roleId ?? 'NEW'; 
  //final String Filename = 'demo_role';
  String? _roleRootPath;

  late List<SpriteCell> spriteCells;
  late List<BackgroundFolder> backgroundFolders;

  final PageController _pageCtrl = PageController();

  int _pageIndex = 0; // 0=人设 1=立绘资源 2=背景资源

  final api = ApiClient();

  @override
  void initState() {
    super.initState();
    spriteCells = [];
    backgroundFolders = [];
    //_pageCtrl = PageController(initialPage: 0);
    //_bootstrapDemo();
    //_loadFromDiskOrInit();
    _roleId = widget.roleId; // 可能为空
    
    if (_roleId != null) {
      _loadFromDiskOrInit(_roleId!);
    } else {
      _bootstrapDemo(); // 只初始化内存/UI，不写文件
    }
  }
  // 从磁盘加载（人设 + 资源），如果没有就初始化（demo数据）
  Future<void> _loadFromDiskOrInit(roleId) async {
    //先传目录
    final root = await One2OneAssetStore.roleRoot(roleId);
    _roleRootPath = root.path;
    // 1)加载人设
    final persona = await One2OnePersonaStore.loadPersona(roleId);
    if (persona != null) {
      nameCtrl.text = (persona['name'] ?? '') as String;
      personaCtrl.text = (persona['persona'] ?? '') as String;
    }

    // 2)加载资源(manifest)
    final assets = await One2OneAssetStore.loadAssets(roleId);
    if (assets != null) {
      spriteCells = assets.sprites;
      backgroundFolders = assets.backgrounds;
      if (!mounted) return;
      setState(() {});
      return;
    }

    // 3) 都没有 => 新建角色（保底）
    _bootstrapDemo(); 
  }

  //首次进入编辑界面自带的示例数据
  void _bootstrapDemo() {
    if (spriteCells.isNotEmpty || backgroundFolders.isNotEmpty) return;

    spriteCells = [
      SpriteCell(
        outfit: '校服',
        emotion: '高兴',
        variants:[
          const SpriteVariant(variant: '1', note: '未绑定文件'),
          const SpriteVariant(variant: '2', note: '未绑定文件'),
        ],
      ),
      SpriteCell(
        outfit: '校服',
        emotion: '难过',
        variants:[
          const SpriteVariant(variant: '1', note: '未绑定文件'),
        ],
      ),
      SpriteCell(
        outfit: '私服',
        emotion: '高兴',
        variants:[
          const SpriteVariant(variant: '1', note: '未绑定文件'),
        ],
      ),
    ];
    //背景列表相比于立绘列表是旧写法，迟早会改的，只是我现在懒啦
    backgroundFolders = [
      BackgroundFolder(
        title: '教室',
        variants: const [
          BackgroundVariant(title: '教室-白天', note: '未绑定文件'),
          BackgroundVariant(title: '教室-黄昏', note: '未绑定文件'),
          BackgroundVariant(title: '教室-晚上', note: '未绑定文件'),
        ],
      ),
    ];

    setState(() {});

  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    nameCtrl.dispose();
    personaCtrl.dispose();
    /*greetingCtrl.dispose();
    styleCtrl.dispose();
    tabooCtrl.dispose();*/
    super.dispose();
  }

  // 构建保存用的副本，并在副本里做 pickedPath -> file 绑定 + 清理空数据
  ({List<SpriteCell> sprites, List<BackgroundFolder> backgrounds}) _buildSavingCopies() {
    // 1) 先深拷贝
    var sprites = spriteCells.map((f) => f.copyWith(variants: List.of(f.variants))).toList();
    var bgs = backgroundFolders.map((f) => f.copyWith(variants: List.of(f.variants))).toList();

    // 2) 在副本里做 pickedPath -> file 绑定（等价于你原来的 for 循环）
    for (var i = 0; i < sprites.length; i++) {
      final cell = sprites[i];
      final nextVariants = <SpriteVariant>[];

      for (final v in cell.variants) {
        if (v.pickedPath == null) {
          nextVariants.add(v);
          continue;
        }

        final ext = p.extension(v.pickedPath!).toLowerCase();
        final safeVariant =
            v.variant.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
        final rel = 'assets/sprites/${cell.outfit}/${cell.emotion}/$safeVariant'
            '${ext.isEmpty ? '.png' : ext}';

        nextVariants.add(
          v.copyWith(
            file: rel,
            pickedPath: null,
            note: '已绑定',
          ),
        );
      }
      sprites[i] = cell.copyWith(variants: nextVariants);
    }

    for (var i = 0; i < bgs.length; i++) {
      final folder = bgs[i];
      final vars = <BackgroundVariant>[];
      for (final v in folder.variants) {
        if (v.pickedPath == null) {
          vars.add(v);
          continue;
        }
        final ext = p.extension(v.pickedPath!).toLowerCase();
        final name = (v.title).trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_') +
            (ext.isEmpty ? '.jpg' : ext);
        final rel = 'assets/backgrounds/${folder.title}/$name';

        vars.add(v.copyWith(
          file: rel,
          pickedPath: null,
          note: '已绑定',
        ));
      }
      bgs[i] = folder.copyWith(variants: vars);
    }

    // 3) prune：只在副本里删空项（根据 file 判断）
    // 3.1 删除 file 为空的 frame
    for (var i = 0; i < sprites.length; i++) {
      final folder = sprites[i];
      final cleaned = folder.variants.where((f) => (f.file ?? '').trim().isNotEmpty).toList();
      sprites[i] = folder.copyWith(variants: cleaned);
    }
    // 3.2 删除空分类
    sprites.removeWhere((f) => f.variants.isEmpty);

    // 3.3 背景同理
    for (var i = 0; i < bgs.length; i++) {
      final folder = bgs[i];
      final cleaned = folder.variants.where((v) => (v.file ?? '').trim().isNotEmpty).toList();
      bgs[i] = folder.copyWith(variants: cleaned);
    }
    bgs.removeWhere((f) => f.variants.isEmpty);

    return (sprites: sprites, backgrounds: bgs);
  }

  // 构建后端请求用的 payload（从副本构建，避免误发 pickedPath）
  Map<String, dynamic> _buildBackendPayloadFromCopies(
    List<SpriteCell> spritesCopy,
    List<BackgroundFolder> backgroundsCopy,
  ) {
    final outfits = spritesCopy
        .map((c) => c.outfit.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final emotions = spritesCopy
        .map((c) => c.emotion.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final backgrounds = <Map<String, dynamic>>[];
    for (final folder in backgroundsCopy) {
      for (final v in folder.variants) {
        if ((v.file ?? '').trim().isEmpty) continue;
        backgrounds.add({
          "title": v.title,
        });
      }
    }

    return {
      "schema": 1,
      "roleId": _roleId,
      "name": nameCtrl.text.trim(),
      "persona": personaCtrl.text.trim(),
      "updatedAt": DateTime.now().toUtc().toIso8601String(),
      "outfits": outfits,
      "emotions": emotions,
      "backgrounds": backgrounds,
    };
  }

  //清理无用资源用
  Set<String> _collectWantedRelPaths(
    List<SpriteCell> sprites,
    List<BackgroundFolder> bgs,
  ) {
    final keep = <String>{};

    for (final folder in sprites) {
      for (final f in folder.variants) {
        final rel = (f.file ?? '').trim();
        if (rel.isNotEmpty) keep.add(rel);
      }
    }

    for (final folder in bgs) {
      for (final v in folder.variants) {
        final rel = (v.file ?? '').trim();
        if (rel.isNotEmpty) keep.add(rel);
      }
    }
    return keep;
  }

  Future<void> _cleanupOrphanFiles({
    required String roleId,
    required Set<String> keepRelPaths,
  }) async {
    final base = await One2OneAssetStore.roleRoot(roleId);

    // 只清理这两个目录，避免误删别的
    final targets = <Directory>[
      Directory(p.join(base.path, 'assets', 'sprites')),
      Directory(p.join(base.path, 'assets', 'backgrounds')),
    ];

    for (final d in targets) {
      if (!await d.exists()) continue;

      await for (final entity in d.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;

        final full = entity.path;
        // 转成 relPath 格式：assets/xxx/yyy.png
        final rel = p.relative(full, from: base.path).replaceAll('\\', '/');

        // 如果磁盘文件不在 keep 集合里 => 删
        if (!keepRelPaths.contains(rel)) {
          try {
            await entity.delete();
            debugPrint('Deleted orphan file: $rel');
          } catch (e) {
            debugPrint('Failed to delete $rel : $e');
          }
        }
      }
    }
    // 清理空目录
    // 这里没做，先空着，绝对不是因为我懒
  }

  Future<void> _save() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      // ignore: avoid_print
      print(dir.path);

      // 0) 如果还没 roleId，先分配一个
      _roleId ??= await One2OneIdStore.allocate();
      final roleId = _roleId!;

      // 1) 生成待保存副本（不影响 UI）
      final copies = _buildSavingCopies();
      final savingSprites = copies.sprites;
      final savingBgs = copies.backgrounds;

      // 2) 先保存本地（用副本写 manifest，避免空分类写入）
      await One2OnePersonaStore.savePersona(
        roleId,
        name: nameCtrl.text.trim(),
        persona: personaCtrl.text.trim(),
      );

      await One2OneAssetStore.saveAssets(
        roleId: roleId,
        spriteCells: savingSprites,
        backgroundFolders: savingBgs,
      );
      // 清理本地多余文件（根据副本里的 file 字段收集应该保留的 relPath）
      final keep = _collectWantedRelPaths(savingSprites, savingBgs);
      await _cleanupOrphanFiles(roleId: roleId, keepRelPaths: keep);

      // 更新存档状态（草稿模式 + 更新时间）
      await One2OneSaveStateStore.saveDraft(roleId);

      // 3) 发后端（用副本构建 payload）
      final payload = _buildBackendPayloadFromCopies(
        savingSprites,
        savingBgs,
      );

      final pretty = const JsonEncoder.withIndent('  ').convert(payload);
      debugPrint("====== One2One Save Request ======");
      debugPrint(pretty);
      debugPrint("==================================");

      await api.saveOne2OneProfile(payload);

      //  4) 全部成功才把副本写回 UI + setState
      spriteCells = savingSprites;
      backgroundFolders = savingBgs;

      if (!mounted) return;
      setState(() {});
      context.read<GameNoticeStore>().success(
        '资源已保存',
        avatarPath: 'assets/■■■/■■■.png',
      );
    } catch (e) {
      if (!mounted) return;
      context.read<GameNoticeStore>().error(
        '保存失败：$e',
        avatarPath: 'assets/■■■/■■■.png',
      );
    }
  }

  // 页签切换函数
  void _jumpTo(int index) {
    if (_pageIndex == index) return;
    setState(() => _pageIndex = index);
    _pageCtrl.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }
  //开始游戏
  Future<void> _nextOrStart() async {
    if (_pageIndex < 2) {
      _jumpTo(_pageIndex + 1);
      return;
    }

    await _save();

    if (!mounted || _roleId == null) return;

    final save = await One2OneSaveStateStore.load(_roleId!);
    final canResume = One2OneSaveStateStore.hasEstablishedGamingSnapshot(save);

    Navigator.of(context).pushReplacementNamed(
      '/one2one_play',
      arguments: {
        'roleId': _roleId!,
        'startMode': canResume ? 'resume' : 'fresh',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastPage = _pageIndex == 2;
    final nextLabel = isLastPage ? '开始游戏' : '下一页';
    final nextIcon = isLastPage ? Icons.play_arrow_rounded : Icons.arrow_forward_rounded;

    return Scaffold(
      backgroundColor: GameTheme.bgA,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('一对一 - 角色编辑', style: GameTheme.h2(context)),
        actions: [
          //第二个按钮：下一页 / 开始游戏
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: OutlinedButton.icon(
              style: GameTheme.one2oneSoftButtonStyle(),
              onPressed: _nextOrStart,
              icon: Icon(nextIcon, size: 18),
              label: Text(nextLabel),
            ),
          ),

          //保存按钮
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GameTheme.one2oneGradientButton(
              onPressed: _save,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.save_outlined, size: 18),
                  SizedBox(width: 6),
                  Text('保存'),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: GameTheme.bgGradient()),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // 顶部“页签切换条”（游戏UI风格的两段按钮）
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: GameTheme.blur(
                  radius: 18,
                  child: Container(
                    decoration: GameTheme.card(radius: 18, opacity: 0.55),
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SegBtn(
                            active: _pageIndex == 0,
                            text: '人设',
                            icon: Icons.badge_outlined,
                            onTap: () => _jumpTo(0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SegBtn(
                            active: _pageIndex == 1,
                            text: '立绘资源',
                            icon: Icons.collections_outlined,
                            onTap: () => _jumpTo(1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SegBtn(
                            active: _pageIndex == 2,
                            text: '背景资源',
                            icon: Icons.image_outlined,
                            onTap: () => _jumpTo(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              //三页内容：PageView
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  onPageChanged: (i) => setState(() => _pageIndex = i),
                  children: [
                    _Split2Pane(
                      left: One2OnePersonaPanel(
                        roleId: roleIdDisplay,
                        nameCtrl: nameCtrl,
                        personaCtrl: personaCtrl,
                      ),
                      right: const One2OnePersonaSettingsPanel(),
                    ),
                    One2OneSpritesPanel(
                      roleRootPath: _roleRootPath,
                      spriteCells: spriteCells,
                      onChanged: () => setState(() {}),
                    ),
                    One2OneBackgroundsPanel(
                      roleRootPath: _roleRootPath,
                      backgroundFolders: backgroundFolders,
                      onChanged: () => setState(() {}),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

///页签切换按钮组件
class _SegBtn extends StatelessWidget {
  const _SegBtn({
    required this.active,
    required this.text,
    required this.icon,
    required this.onTap,
  });

  final bool active;
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = active ? Colors.white.withOpacity(0.75) : Colors.white.withOpacity(0.25);
    final border = active ? Colors.white.withOpacity(0.55) : Colors.white.withOpacity(0.25);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Text(text, style: GameTheme.h2(context)),
          ],
        ),
      ),
    );
  }
}

//通用左右栏
class _Split2Pane extends StatelessWidget {
  const _Split2Pane({
    required this.left,
    required this.right,
    this.breakpoint = 860,
    this.gap = 12,
  });

  final Widget left;
  final Widget right;
  final double breakpoint;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= breakpoint;

        if (wide) {
          return Row(
            children: [
              Expanded(child: left),
              SizedBox(width: gap),
              Expanded(child: right),
            ],
          );
        }

        // 窄屏：上下排列（各自滚动）
        return Column(
          children: [
            Expanded(child: left),
            SizedBox(height: gap),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}
