import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../stores/game_notice_store.dart';
import '../home/game_theme.dart';

//组件
import 'notice_avatar_glitch.dart';

class GlobalNoticeHost extends StatelessWidget {
  const GlobalNoticeHost({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameNoticeStore>(
      builder: (context, store, _) {
        final notice = store.current;
        final visible = store.visible && notice != null;

        return Stack(
          children: [
            child,

            // 全屏变暗
            IgnorePointer(
              ignoring: !visible,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: visible ? 1 : 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: visible ? store.dismiss : null,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.56),
                  ),
                ),
              ),
            ),

            // 左上角消息框
            IgnorePointer(
              ignoring: !visible,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      offset: visible ? Offset.zero : const Offset(-0.04, -0.08),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: visible ? 1 : 0,
                        child: notice == null
                            ? const SizedBox.shrink()
                            : _NeonNoticeRow(
                                notice: notice,
                                onDismiss: store.dismiss,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NeonNoticeRow extends StatelessWidget {
  const _NeonNoticeRow({
    required this.notice,
    required this.onDismiss,
  });

  final GameNoticeData notice;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final avatarPath = notice.avatarPath.trim();

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 760,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AvatarNeonBox(
            child: NoticeAvatarGlitch(
              avatarPath: avatarPath,
              accent: GameTheme.accentBlue,
              fallbackLabel: '■■■',
              width: 88,
              height: 88,
              radius: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _TextNeonBox(
              speaker: notice.speaker,
              message: notice.message,
              onDismiss: onDismiss,
            ),
          ),
        ],
      ),
    );
  }
}
class _AvatarNeonBox extends StatelessWidget {
  const _AvatarNeonBox({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _NeonFrame(
      width: 88,
      height: 88,
      radius: 22,
      padding: const EdgeInsets.all(6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}

class _TextNeonBox extends StatelessWidget {
  const _TextNeonBox({
    required this.speaker,
    required this.message,
    required this.onDismiss,
  });

  final String speaker;
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _NeonFrame(
          radius: 20,
          padding: const EdgeInsets.all(3),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 88),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  GameTheme.accentBlue,
                  GameTheme.accentPink,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.98),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black.withValues(alpha: 0.28),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: onDismiss,
                    child: Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.96),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),

        // 名字插进框体
        Positioned(
          left: 22,
          top: -10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: const Color(0xFFF6F7FF),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.92),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: GameTheme.accentBlue.withValues(alpha: 0.30),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: GameTheme.accentPink.withValues(alpha: 0.22),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            //渐变色的名字
            /*child: ShaderMask(
              shaderCallback: (rect) {
                return const LinearGradient(
                  colors: [
                    GameTheme.accentBlue,
                    GameTheme.accentPink,
                  ],
                ).createShader(rect);
              },
              child: Text(
                speaker,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),*/
            //纯黑色名字
            child: Text(
              speaker,
              style: TextStyle(
                color: const Color.fromARGB(255, 21, 20, 21), // 或直接 Colors.white
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                shadows: [
                  Shadow(
                    blurRadius: 8,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NeonFrame extends StatelessWidget {
  const _NeonFrame({
    this.width,
    this.height,
    required this.radius,
    required this.padding,
    required this.child,
  });

  final double? width;
  final double? height;
  final double radius;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFA6F0FF),
            Color(0xFFFFA6D5),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: GameTheme.accentBlue.withValues(alpha: 0.32),
            blurRadius: 20,
            spreadRadius: 1.5,
          ),
          BoxShadow(
            color: GameTheme.accentPink.withValues(alpha: 0.26),
            blurRadius: 24,
            spreadRadius: 1.5,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius - 6),
          color: Colors.white.withValues(alpha: 0.10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.72),
            width: 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 6),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: child,
          ),
        ),
      ),
    );
  }
}