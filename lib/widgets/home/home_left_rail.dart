import 'package:flutter/material.dart';
import 'game_theme.dart';
import 'home_root.dart';

class HomeLeftRail extends StatelessWidget {
  final HomeRootTab root;
  final LoadTab loadTab;
  final ValueChanged<HomeRootTab> onSelectRoot;
  final ValueChanged<LoadTab> onSelectLoadTab;
  final bool wsOk;
  final String rttText;

  const HomeLeftRail({
    super.key,
    required this.root,
    required this.loadTab,
    required this.onSelectRoot,
    required this.onSelectLoadTab,
    required this.wsOk,
    required this.rttText,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Column(
        children: [
          GameTheme.blur(
            sigma: 14,
            radius: 22,
            child: Container(
              decoration: GameTheme.card(opacity: 0.68),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          GameTheme.accentPink.withValues(alpha: 0.85),
                          GameTheme.accentBlue.withValues(alpha: 0.85),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(Icons.school_rounded, color: Colors.black.withValues(alpha:0.75)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Galgame，启动！", style: GameTheme.h2(context)),
                        const SizedBox(height: 2),
                        Text("Main Menu", style: GameTheme.tiny(context)),
                      ],
                    ),
                  ),
                  Icon(Icons.more_horiz_rounded, color: GameTheme.muted(0.55)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: GameTheme.blur(
              sigma: 16,
              radius: 22,
              child: Container(
                decoration: GameTheme.card(opacity: 0.62),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _RailButton(
                      selected: root == HomeRootTab.start,
                      title: "开始游戏",
                      subtitle: "选择模式",
                      icon: Icons.play_circle_fill_rounded,
                      accent: GameTheme.accentBlue,
                      onTap: () => onSelectRoot(HomeRootTab.start),
                    ),
                    const SizedBox(height: 10),
                    _RailButton(
                      selected: root == HomeRootTab.load,
                      title: "读取存档",
                      subtitle: "故事 / 一对一",
                      icon: Icons.folder_open_rounded,
                      accent: GameTheme.accentPink,
                      onTap: () => onSelectRoot(HomeRootTab.load),
                    ),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: root == HomeRootTab.load
                          ? Padding(
                              key: const ValueKey("load-sub"),
                              padding: const EdgeInsets.only(top: 10),
                              child: Column(
                                children: [
                                  _SubButton(
                                    selected: loadTab == LoadTab.story,
                                    title: "故事存档",
                                    onTap: () => onSelectLoadTab(LoadTab.story),
                                  ),
                                  const SizedBox(height: 8),
                                  _SubButton(
                                    selected: loadTab == LoadTab.one2one,
                                    title: "一对一存档",
                                    onTap: () => onSelectLoadTab(LoadTab.one2one),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(key: ValueKey("load-sub-empty")),
                    ),

                    const SizedBox(height: 10),
                    _RailButton(
                      selected: root == HomeRootTab.settings,
                      title: "设置",
                      subtitle: "资源 / 服务 / 外挂",
                      icon: Icons.settings_rounded,
                      accent: GameTheme.accentMint,
                      onTap: () => onSelectRoot(HomeRootTab.settings),
                    ),

                    const Spacer(),
                    _HudStatus(wsOk: wsOk, rttText: rttText),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailButton extends StatefulWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _RailButton({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_RailButton> createState() => _RailButtonState();
}

class _RailButtonState extends State<_RailButton> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: _down ? 0.988 : (_hover ? 1.01 : 1.0),
          child: Stack(
            children: [
              if (selected)
                Positioned.fill(
                  child: Container(
                    decoration: GameTheme.selectedGlow(
                      radius: 18,
                      a: widget.accent,
                      b: Colors.white,
                    ),
                  ),
                ),
              GameTheme.blur(
                sigma: 12,
                radius: 18,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: selected ? 0.78 : 0.68),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: selected ? 0.55 : 0.40)),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 16,
                        offset: const Offset(0, 10),
                        color: Colors.black.withValues(alpha: 0.06),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: widget.accent.withValues(alpha: 0.18),
                          border: Border.all(color: widget.accent.withValues(alpha: 0.22)),
                        ),
                        child: Icon(widget.icon, color: GameTheme.fg(0.78)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.title, style: TextStyle(fontWeight: FontWeight.w900, color: GameTheme.fg(0.90))),
                            const SizedBox(height: 2),
                            Text(widget.subtitle, style: GameTheme.tiny(context)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: GameTheme.muted(0.55)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubButton extends StatelessWidget {
  final bool selected;
  final String title;
  final VoidCallback onTap;

  const _SubButton({
    required this.selected,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? Colors.white.withValues(alpha: 0.78) : Colors.white.withValues(alpha: 0.62);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: GameTheme.blur(
        sigma: 10,
        radius: 14,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: selected ? 0.55 : 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? GameTheme.accentBlue.withValues(alpha: 0.75) : GameTheme.muted(0.28),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w900, color: GameTheme.fg(selected ? 0.88 : 0.72)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HudStatus extends StatelessWidget {
  final bool wsOk;
  final String rttText;

  const _HudStatus({required this.wsOk, required this.rttText});

  @override
  Widget build(BuildContext context) {
    return GameTheme.blur(
      sigma: 10,
      radius: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.38)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                "tips：右下角的手机图案可以打开手机界面",
                style: TextStyle(fontSize: 11.5, color: GameTheme.fg(0.70), fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
