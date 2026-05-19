import 'package:flutter/material.dart';
import 'game_theme.dart';
import 'home_root.dart';
import 'start_game_panel.dart';
import 'library_grid.dart';

class HomeRightPanel extends StatelessWidget {
  final HomeRootTab root;
  final LoadTab loadTab;
  final List<SaveEntry> storySaves;
  final List<SaveEntry> one2oneSaves;

  final VoidCallback onStartStory;
  final VoidCallback onStartOne2One;
  final ValueChanged<SaveEntry> onOpenSave;

  const HomeRightPanel({
    super.key,
    required this.root,
    required this.loadTab,
    required this.storySaves,
    required this.one2oneSaves,
    required this.onStartStory,
    required this.onStartOne2One,
    required this.onOpenSave,
  });

  @override
  Widget build(BuildContext context) {
    final title = switch (root) {
      HomeRootTab.start => "开始游戏",
      HomeRootTab.load => "读取存档",
      HomeRootTab.settings => "设置",
    };

    final subtitle = switch (root) {
      HomeRootTab.start => "选择你要进入的模式（两种模式的记忆互不互通）",
      HomeRootTab.load => loadTab == LoadTab.story ? "故事存档" : "一对一存档",
      HomeRootTab.settings => "资源与服务配置（占位）",
    };

    return GameTheme.blur(
      sigma: 18,
      radius: 22,
      child: Container(
        decoration: GameTheme.card(opacity: 0.60),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GameTheme.title(context)),
                      const SizedBox(height: 6),
                      Text(subtitle, style: GameTheme.body(context)),
                    ],
                  ),
                ),
                _HudIcon(icon: Icons.search_rounded),
                const SizedBox(width: 10),
                _HudIcon(icon: Icons.tune_rounded),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: switch (root) {
                  HomeRootTab.start => StartGamePanel(
                      key: const ValueKey("start"),
                      onStory: onStartStory,
                      onOne2one: onStartOne2One,
                      //传入背景图
                      storyBackground: const AssetImage("assets/bg/story.png"),
                      one2oneBackground: const AssetImage("assets/bg/one2one.png"),
                    ),
                  HomeRootTab.load => LibraryGrid(
                      key: ValueKey("load-$loadTab"),
                      items: loadTab == LoadTab.story ? storySaves : one2oneSaves,
                      onTap: onOpenSave,
                      showAdd: false,
                    ),
                  HomeRootTab.settings => const _SettingsPlaceholder(key: ValueKey("settings")),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HudIcon extends StatelessWidget {
  final IconData icon;

  const _HudIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return GameTheme.blur(
      sigma: 10,
      radius: 14,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.62),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.38)),
        ),
        child: Icon(icon, color: GameTheme.muted(0.55)),
      ),
    );
  }
}

class _SettingsPlaceholder extends StatelessWidget {
  const _SettingsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "设置页占位\n（后续放：资源校验、外部服务地址、缓存管理等）",
        textAlign: TextAlign.center,
        style: TextStyle(color: GameTheme.fg(0.72), fontWeight: FontWeight.w800, height: 1.35),
      ),
    );
  }
}
