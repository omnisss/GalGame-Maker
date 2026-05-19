import 'dart:io';
import 'package:flutter/material.dart';
import '../scene_state.dart';
import '../../home/game_theme.dart';

class DialogueLayer extends StatelessWidget {
  const DialogueLayer({super.key, required this.state});
  final DialogueState state;

  @override
  Widget build(BuildContext context) {
    if (!state.show) return const SizedBox.shrink();

    final bottom = MediaQuery.of(context).padding.bottom;
    final panelH = (MediaQuery.of(context).size.height * 0.28)
        .clamp(180.0, 260.0);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SizedBox(
        height: panelH + bottom,
        child: Stack(
          children: [
            // 渐变背景
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        GameTheme.accentPink.withValues(alpha: 0.8),
                        GameTheme.accentPink.withValues(alpha: 0.6),
                        GameTheme.accentPink.withValues(alpha: 0.4),
                        GameTheme.accentPink.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.35, 0.70, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // =========================
                    // 左侧 LOGO 区（矩形）
                    // =========================
                    _LogoRect(path: state.avatarPath),

                    const SizedBox(width: 14),

                    // =========================
                    // 中间对话区
                    // =========================
                    Expanded(
                      child: _CenterDialogueBlock(state: state),
                    ),

                    const SizedBox(width: 14),

                    // =========================
                    // 右侧按钮（竖直）
                    // =========================
                    _VerticalButtons(
                      onSettings: state.onSettings,
                      onEdit: state.onEdit,
                      onLog: state.onLog,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//logo框
class _LogoRect extends StatelessWidget {
  const _LogoRect({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    final hasFile = path.trim().isNotEmpty && File(path).existsSync();

    return Container(
      width: 200,          // 矩形宽
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: hasFile
            ? Image.file(
                File(path),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              )
            : _LogoFallback(),
      ),
    );
  }
}

//左侧矩形框
class _LogoFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            GameTheme.accentPink.withValues(alpha: 0.5),
            GameTheme.accentPink.withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(
        'LOGO',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

//中间对话区
class _CenterDialogueBlock extends StatefulWidget {
  const _CenterDialogueBlock({required this.state});
  final DialogueState state;

  @override
  State<_CenterDialogueBlock> createState() =>
      _CenterDialogueBlockState();
}

class _CenterDialogueBlockState
    extends State<_CenterDialogueBlock> {

  @override
  Widget build(BuildContext context) {
    final nameStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w900,
      fontSize:
          GameTheme.fontH(context, 0.040, min: 20, max: 40),
      shadows: [
        Shadow(
            blurRadius: 14,
            color: Colors.black.withValues(alpha: 0.35))
      ],
    );

    final textStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.98),
      fontSize: GameTheme.fontH(context, 0.030, min: 15, max: 30),
      fontWeight: FontWeight.w600,
      height: 1.25,
      shadows: [
        Shadow(blurRadius: 14, color: Colors.black.withValues(alpha: 0.40)),
        Shadow(blurRadius: 4, color: Colors.black.withValues(alpha: 0.35)),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 上层：名字
        Text('【${widget.state.speaker}】', style: nameStyle),

        const SizedBox(height: 6),

        // 中层：台词
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Text(
              '「${widget.state.text}」',
              style: textStyle,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // 下层：输入框
        _InputBar(state: widget.state),
      ],
    );
  }
}
//输入框
class _InputBar extends StatefulWidget {
  const _InputBar({required this.state});
  final DialogueState state;

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();

  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!mounted) return;
      setState(() => _focused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    widget.state.onSubmit?.call(text);
    _ctrl.clear();
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.state.inputEnabled && widget.state.onSubmit != null;

    final borderColor = _focused
        ? GameTheme.accentPink.withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.18);

    final fillColor = _focused
        ? Colors.black.withValues(alpha: 0.28)
        : Colors.black.withValues(alpha: 0.18);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: _focused ? 1.5 : 1),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: GameTheme.accentPink.withValues(alpha: 0.28),
                  blurRadius: 16,
                  spreadRadius: 1,
                )
              ]
            : [],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              focusNode: _focus,
              controller: _ctrl,
              enabled: enabled,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              cursorColor: GameTheme.accentPink.withValues(alpha: 0.95), // ✅ 光标更明显
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: widget.state.inputHint,
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: _focused ? 0.55 : 0.40),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: enabled ? _submit : null,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 40,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _focused
                    ? GameTheme.accentPink.withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.send_rounded,
                size: 18,
                color: Colors.white.withValues(alpha: enabled ? 0.95 : 0.35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
//右侧按钮
class _VerticalButtons extends StatelessWidget {
  const _VerticalButtons({
    required this.onSettings,
    required this.onEdit,
    required this.onLog,
  });

  final VoidCallback? onSettings;
  final VoidCallback? onEdit;
  final VoidCallback? onLog;

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, VoidCallback? onTap) {
      final enabled = onTap != null;

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              //底色
              color: Colors.black.withValues(alpha: 0.35),

              borderRadius: BorderRadius.circular(14),

              // 细描边
              border: Border.all(
                color: enabled
                    ? Colors.white.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.10),
                width: 1,
              ),

              // 轻微内外发光
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: GameTheme.accentPink.withValues(alpha: 0.25),
                        blurRadius: 18,
                        spreadRadius: 1,
                      )
                    ]
                  : [],
            ),
            child: Icon(
              icon,
              size: 20,
              color: enabled
                  ? Colors.white.withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.35),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        btn(Icons.settings, onSettings),
        btn(Icons.edit, onEdit),
        btn(Icons.history, onLog),
      ],
    );
  }
}