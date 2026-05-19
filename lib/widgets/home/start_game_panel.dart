import 'dart:ui';
import 'package:flutter/material.dart';
import 'game_theme.dart';

class StartGamePanel extends StatelessWidget {
  final VoidCallback onStory;
  final VoidCallback onOne2one;

  // 两张卡片的背景图（可选）
  // 传 null 就不显示图片，只用渐变色块
  final ImageProvider? storyBackground;
  final ImageProvider? one2oneBackground;

  const StartGamePanel({
    super.key,
    required this.onStory,
    required this.onOne2one,
    this.storyBackground,
    this.one2oneBackground,
  });

  @override
  Widget build(BuildContext context) {
    // 上下布局，每个模式占一半高度
    return Column(
      children: [
        Expanded(
          child: _ModeCard(
            title: "故事模式",
            subtitle: "以「游戏」为单位\n导演AI + 多角色演员AI合作处理\n世界观更完整，演出更丰富，拥有剧情缓存功能\n可选自己是否参与对话，可进行选项处理\n但响应相对较慢，且开局设计较复杂",
            hint: "适合：长线剧情 / 多角色互动",
            accent: GameTheme.accentBlue,
            icon: Icons.auto_stories_rounded,
            background: storyBackground,
            onTap: onStory,
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: _ModeCard(
            title: "一对一模式",
            subtitle: "以「角色」为单位\n标准私聊体验\n更轻量，开局设计较简单，响应更直接\n但缺乏世界观和其他角色的互动且不具备剧情缓存功能",
            hint: "适合：日常对话",
            accent: GameTheme.accentPink,
            icon: Icons.chat_bubble_outline_rounded,
            background: one2oneBackground,
            onTap: onOne2one,
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String hint;
  final Color accent;
  final IconData icon;
  final ImageProvider? background;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.accent,
    required this.icon,
    required this.onTap,
    this.background,
  });

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  bool _hover = false;
  bool _down = false;

  
  @override
  Widget build(BuildContext context) {
    final a = widget.accent;
    // 按屏幕高度比例计算字号，并限制范围（防止过小/过大）
    final titleSize = GameTheme.fontH(context, 0.040, min: 20, max: 50);   // 标题
    final subtitleSize = GameTheme.fontH(context, 0.025, min: 13, max: 50); // 副标题
    final hintSize = GameTheme.fontH(context, 0.020, min: 12, max: 50);     // hint


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
          scale: _down ? 0.98 : (_hover ? 1.02 : 1.0), // 按下略微缩小，悬浮略微放大
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox.expand(
              child: Stack(
                children: [
                  // ===== 1) 背景图片（可选）=====
                  if (widget.background != null)
                    Positioned.fill(
                      child: Image(
                        image: widget.background!,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),

                  // ===== 2) 若无背景图，用柔和渐变占位 =====
                  if (widget.background == null)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              a.withValues(alpha: 0.18),
                              Colors.white.withValues(alpha:0.55),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),

                  // ===== 3) 轻微模糊（让文字更读得清）=====
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: const SizedBox.expand(),
                    ),
                  ),

                  // ===== 4) 遮罩层：提升可读性（非常关键）=====
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        // 上部略亮、下部略深，保证底部 hint 可读
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.35),
                            Colors.white.withValues(alpha: 0.55),
                            Colors.white.withValues(alpha: 0.70),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // ===== 5) 选中/悬浮的柔和色块强调=====
                  Positioned.fill(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 160),
                      opacity: _hover ? 1.0 : 0.92,
                      child: Container(
                        decoration: GameTheme.selectedGlow(
                          radius: 24,
                          a: a,
                          b: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // ===== 6) 外框玻璃边线 + 轻阴影 =====
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: _hover ? 0.70 : 0.50),
                          width: 1.0,
                        ),
                      ),
                    ),
                  ),

                  // ===== 7) 内容 =====
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _IconPlate(accent: a, icon: widget.icon),
                            const SizedBox(width: 12),
                            //主标题
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: titleSize,
                                fontWeight: FontWeight.w900,
                                color: GameTheme.fg(0.92),
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.chevron_right_rounded, color: GameTheme.muted(0.55)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        //副标题
                        Text(
                          widget.subtitle,
                          style: GameTheme.body(context).copyWith(
                            fontSize: subtitleSize,
                            height: 1.4,
                          ),
                        ),
                        const Spacer(),
                        _HintChip(text: widget.hint, fontSize: hintSize),
                      ],
                    ),
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

class _IconPlate extends StatelessWidget {
  final Color accent;
  final IconData icon;

  const _IconPlate({required this.accent, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: accent.withValues(alpha: 0.18),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Icon(icon, color: GameTheme.fg(0.78)),
    );
  }
}

class _HintChip extends StatelessWidget {
  final String text;
  final double fontSize;

  const _HintChip({required this.text, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.75),
        border: Border.all(color: Colors.white.withValues(alpha: 0.60)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          color: GameTheme.fg(0.75),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

