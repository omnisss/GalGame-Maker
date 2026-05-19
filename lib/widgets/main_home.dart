//这个文件代码暂时废弃了，臃肿，界面也不满意。但我保留了代码以供参考（比如一些玻璃morphism的UI细节）。你之后可以根据需要把它里面的组件搬到其他界面里。
/*import 'dart:ui';
import 'package:flutter/material.dart';
import '../pages/story_mode_page.dart';
import '../pages/one2one_edit_page.dart';

enum HomeRoot { start, load, settings }
enum LoadTab { story, one2one }

class MainHome extends StatefulWidget {
  final bool wsOk;
  final int rttMs;

  const MainHome({
    super.key,
    required this.wsOk,
    required this.rttMs,
  });

  @override
  State<MainHome> createState() => _MainHomeState();
}

class _MainHomeState extends State<MainHome> {
  HomeRoot _root = HomeRoot.start;
  LoadTab _loadTab = LoadTab.story;

  // 先用假数据占位；之后你从本地/后端读存档时替换即可
  final List<_LibraryItem> _storySaves = const [
    _LibraryItem(id: "g1", title: "存档 A", subtitle: "世界观：校园 · 轻喜剧"),
    _LibraryItem(id: "g2", title: "存档 B", subtitle: "世界观：幻想 · 冒险"),
    _LibraryItem(id: "g3", title: "存档 C", subtitle: "世界观：都市 · 悬疑"),
  ];

  final List<_LibraryItem> _one2oneSaves = const [
    _LibraryItem(id: "c1", title: "因幡巡", subtitle: "最近：2 分钟前"),
    _LibraryItem(id: "c2", title: "角色 2", subtitle: "最近：昨天"),
    _LibraryItem(id: "c3", title: "角色 3", subtitle: "最近：3 天前"),
  ];

  @override
  Widget build(BuildContext context) {
    final rttText = widget.rttMs < 0 ? "--" : "${widget.rttMs}ms";

    return Stack(
      children: [
        // ===== 背景层 =====
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF5F7FA), Color(0xFFE4EAF2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),

        // ===== 柔化层（游戏味）=====
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(color: Colors.white.withValues(alpha: 0.05)),
          ),
        ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Row(
              children: [
                _LeftRail(
                  root: _root,
                  loadTab: _loadTab,
                  wsOk: widget.wsOk,
                  rttText: rttText,
                  onSelectRoot: (r) => setState(() => _root = r),
                  onSelectLoadTab: (t) => setState(() {
                    _root = HomeRoot.load;
                    _loadTab = t;
                  }),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _RightPanel(
                    root: _root,
                    loadTab: _loadTab,
                    storyItems: _storySaves,
                    one2oneItems: _one2oneSaves,
                    onStartStory: () => _openStory(context),
                    onStartOne2One: () => _openOne2One(context),
                    onTapSave: (item) => _openSave(context, item),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openStory(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StoryModePage()));
  }

  void _openOne2One(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const One2OneEditPage()));
  }

  void _openSave(BuildContext context, _LibraryItem item) {
    // 这里之后按 item.id 打开对应存档
    if (_loadTab == LoadTab.story) {
      _openStory(context);
    } else {
      _openOne2One(context);
    }
  }
}

class _LeftRail extends StatelessWidget {
  final HomeRoot root;
  final LoadTab loadTab;
  final ValueChanged<HomeRoot> onSelectRoot;
  final ValueChanged<LoadTab> onSelectLoadTab;
  final bool wsOk;
  final String rttText;

  const _LeftRail({
    required this.root,
    required this.loadTab,
    required this.onSelectRoot,
    required this.onSelectLoadTab,
    required this.wsOk,
    required this.rttText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      decoration: _glassBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            "Galgame Engine",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.black.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "主界面",
            style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.55)),
          ),
          const SizedBox(height: 16),

          _RailButton(
            selected: root == HomeRoot.start,
            icon: Icons.play_circle_fill_rounded,
            title: "开始游戏",
            subtitle: "选择模式",
            onTap: () => onSelectRoot(HomeRoot.start),
          ),
          const SizedBox(height: 10),
          _RailButton(
            selected: root == HomeRoot.load,
            icon: Icons.folder_open_rounded,
            title: "读取存档",
            subtitle: "故事 / 一对一",
            onTap: () => onSelectRoot(HomeRoot.load),
          ),

          // 读取存档的“子选项”（只在读取存档时展开）
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: root == HomeRoot.load
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
            selected: root == HomeRoot.settings,
            icon: Icons.settings_rounded,
            title: "设置",
            subtitle: "资源 / 连接 / 外挂",
            onTap: () => onSelectRoot(HomeRoot.settings),
          ),

          const Spacer(),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Text("tips：右下角小胶囊可以打开手机界面", style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.55))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RightPanel extends StatelessWidget {
  final HomeRoot root;
  final LoadTab loadTab;
  final List<_LibraryItem> storyItems;
  final List<_LibraryItem> one2oneItems;

  final VoidCallback onStartStory;
  final VoidCallback onStartOne2One;
  final ValueChanged<_LibraryItem> onTapSave;

  const _RightPanel({
    required this.root,
    required this.loadTab,
    required this.storyItems,
    required this.one2oneItems,
    required this.onStartStory,
    required this.onStartOne2One,
    required this.onTapSave,
  });

  @override
  Widget build(BuildContext context) {
    final title = switch (root) {
      HomeRoot.start => "开始游戏",
      HomeRoot.load => "读取存档",
      HomeRoot.settings => "设置",
    };

    final subtitle = switch (root) {
      HomeRoot.start => "两种模式的记忆互不互通：选择你要进入的世界",
      HomeRoot.load => loadTab == LoadTab.story
          ? "故事模式存档（世界观/导演AI/多角色）"
          : "一对一存档（单角色私聊/精简世界）",
      HomeRoot.settings => "占位：资源校验、ComfyUI/GPT-SoVITS 等配置",
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _glassBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.black.withValues(alpha: 0.86),
                ),
              ),
              const Spacer(),
              Icon(Icons.search_rounded, color: Colors.black.withValues(alpha: 0.35)),
              const SizedBox(width: 10),
              Icon(Icons.tune_rounded, color: Colors.black.withValues(alpha: 0.35)),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.55))),
          const SizedBox(height: 14),

          Expanded(
            child: switch (root) {
              HomeRoot.start => _StartGamePanel(
                  onStory: onStartStory,
                  onOne2one: onStartOne2One,
                ),
              HomeRoot.load => _LibraryGrid(
                  items: loadTab == LoadTab.story ? storyItems : one2oneItems,
                  showAdd: false, // ✅ 读取存档：不显示“添加”
                  onTapItem: onTapSave,
                ),
              HomeRoot.settings => const _SettingsPlaceholder(),
            },
          ),
        ],
      ),
    );
  }
}

class _StartGamePanel extends StatelessWidget {
  final VoidCallback onStory;
  final VoidCallback onOne2one;

  const _StartGamePanel({required this.onStory, required this.onOne2one});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final vertical = w < 980;

    final story = _BigModeCard(
      title: "故事模式",
      subtitle: "以“游戏”为单位\n导演AI + 多角色演员AI\n更强的世界观与演出能力",
      hint: "适合：推剧情 / 多角色互动",
      icon: Icons.auto_stories_rounded,
      onTap: onStory,
    );

    final one2one = _BigModeCard(
      title: "一对一模式",
      subtitle: "以“角色”为单位\n标准私聊体验\n精简世界观，响应更直接",
      hint: "适合：陪伴 / 日常对话",
      icon: Icons.chat_bubble_outline_rounded,
      onTap: onOne2one,
    );

    if (vertical) {
      return ListView(
        children: [
          story,
          const SizedBox(height: 12),
          one2one,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: story),
        const SizedBox(width: 12),
        Expanded(child: one2one),
      ],
    );
  }
}

class _BigModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String hint;
  final IconData icon;
  final VoidCallback onTap;

  const _BigModeCard({
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // 背景“模糊感”块（你之后可以换成背景图）
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.75),
                      Colors.white.withValues(alpha: 0.45),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.white.withValues(alpha: 0.05)),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                        ),
                        child: Icon(icon),
                      ),
                      const SizedBox(width: 12),
                      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    subtitle,
                    style: TextStyle(
                      height: 1.35,
                      fontSize: 13,
                      color: Colors.black.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      hint,
                      style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.65), fontWeight: FontWeight.w800),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryGrid extends StatelessWidget {
  final List<_LibraryItem> items;
  final bool showAdd;
  final VoidCallback? onTapAdd;   
  final ValueChanged<_LibraryItem> onTapItem;

  const _LibraryGrid({
    required this.items,
    required this.showAdd,
    required this.onTapItem,
    this.onTapAdd,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final crossAxisCount = w >= 1200 ? 4 : (w >= 900 ? 3 : 2);

    final total = (showAdd ? 1 : 0) + items.length;

    return GridView.builder(
      padding: const EdgeInsets.only(top: 4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemCount: total,
      itemBuilder: (context, index) {
        if (showAdd) {
          if (index == 0) {
            return _AddTile(text: "添加", onTap: onTapAdd ?? () {});
          }
          final item = items[index - 1];
          return _ItemTile(item: item, onTap: () => onTapItem(item));
        } else {
          final item = items[index];
          return _ItemTile(item: item, onTap: () => onTapItem(item));
        }
      },
    );
  }
}

class _AddTile extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _AddTile({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.40),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                ),
                child: const Icon(Icons.add_rounded, size: 28),
              ),
              const SizedBox(height: 10),
              Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text("点击创建", style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.55))),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final _LibraryItem item;
  final VoidCallback onTap;

  const _ItemTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              offset: const Offset(0, 10),
              color: Colors.black.withValues(alpha: 0.06),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.70),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
              ),
              child: Text(item.id, style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.65))),
            ),
            const Spacer(),
            Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(item.subtitle, style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.55))),
          ],
        ),
      ),
    );
  }
}

class _SettingsPlaceholder extends StatelessWidget {
  const _SettingsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "设置页占位\n（后续放：资源完整性校验、外部服务地址、语音/ComfyUI开关等）",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black.withValues(alpha: 0.6), fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RailButton({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? Colors.white.withValues(alpha: 0.75) : Colors.white.withValues(alpha: 0.45);
    final bd = selected ? Colors.white.withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.30);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: bd),
          boxShadow: [
            BoxShadow(
              blurRadius: selected ? 18 : 10,
              offset: const Offset(0, 10),
              color: Colors.black.withValues(alpha: selected ? 0.10 : 0.06),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.55))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
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
    final bg = selected ? Colors.white.withValues(alpha: 0.70) : Colors.white.withValues(alpha: 0.40);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: selected ? 0.70 : 0.25),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900))),
          ],
        ),
      ),
    );
  }
}

class _LibraryItem {
  final String id;
  final String title;
  final String subtitle;

  const _LibraryItem({
    required this.id,
    required this.title,
    required this.subtitle,
  });
}

BoxDecoration _glassBox() {
  return BoxDecoration(
    color: Colors.white.withValues(alpha: 0.55),
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
    boxShadow: [
      BoxShadow(
        blurRadius: 24,
        offset: const Offset(0, 12),
        color: Colors.black.withValues(alpha: 0.08),
      )
    ],
  );
}*/
