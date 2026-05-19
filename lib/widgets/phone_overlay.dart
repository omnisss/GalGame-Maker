// phone_overlay.dart
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/friend.dart';
import 'phone_frame.dart';
import '../pages/friends_list_view.dart';
import '../pages/chat_page.dart';
import '../widgets/pendant/pendant_layer.dart';
import '../pages/phone/phone_help_page.dart';

enum PhonePage { home, friends, chat, help }

class PhoneOverlay extends StatefulWidget {
  final bool wsOk;
  final int rttMs;
  final VoidCallback onClose;
  final PhonePage initialPage;

  const PhoneOverlay({
    super.key,
    required this.wsOk,
    required this.rttMs,
    required this.onClose,
    this.initialPage = PhonePage.home,
  });

  @override
  State<PhoneOverlay> createState() => _PhoneOverlayState();
}

class _PhoneOverlayState extends State<PhoneOverlay> with SingleTickerProviderStateMixin {
  late PhonePage _page;
  Friend? _chatFriend;

  final _frameKey = GlobalKey();
  final ValueNotifier<Rect?> _frameRectVN = ValueNotifier<Rect?>(null);
  final ValueNotifier<Offset?> _anchorVN = ValueNotifier(null);

  late final AnimationController _ctrl;
  late final Animation<double> _curve;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage;

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);

    // 打开：从底部滑入
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _frameRectVN.dispose();
    _anchorVN.dispose();
    super.dispose();
  }

  void _close() {
    if (_closing) return;
    _closing = true;
    _ctrl.reverse().whenComplete(() {
      widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 注意：这个回调会在每一帧动画 tick 后触发 build -> postFrame -> 更新 rect
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _frameRectVN.value = _getFrameGlobalRect();
    });

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, c) {
          final screenW = c.maxWidth;
          final screenH = c.maxHeight;
          const aspect = 1400 / 2489;
          // 你原来的 maxWidth=520 保留；稍微给个边距更像游戏 UI
          final mq = MediaQuery.of(context);
          final padding = mq.padding; // 安全区（刘海/状态栏）
          //final availW = screenW;
          final availH = screenH - padding.top - padding.bottom;

          final maxWByW = screenW * 1.0;  //1.0可修改，越小边框越大
          final maxWByH = (availH * 1.0) * aspect; // 由高度反推宽度上限（避免 phoneH 超屏）

          final phoneW = math.min(520.0, math.min(maxWByW, maxWByH));
          final phoneH = phoneW / aspect;

          final endTop = padding.top + (availH - phoneH) / 2;     // 最终居中位置
          final startTop = screenH + 30;             // 起点：屏幕下方
          // 动画插值
          double lerp(double a, double b, double t) => a + (b - a) * t;

          return AnimatedBuilder(
            animation: _curve,
            builder: (context, _) {
              final t = _curve.value;
              final top = lerp(startTop, endTop, t);

              return Stack(
                children: [
                  // 1) 遮罩淡入淡出（跟随动画）
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _close,
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.25 * t),
                      ),
                    ),
                  ),

                  // 2) 手机本体：从下往上滑到中间（Positioned 会触发布局 -> onLayout 每帧刷新）
                  Positioned(
                    left: (screenW - phoneW) / 2,
                    top: top,
                    width: phoneW,
                    height: phoneH,
                    child: GestureDetector(
                      onTap: () {}, // 阻止点击穿透
                      child: PhoneFrame(
                        key: _frameKey,
                        designSize: const Size(1400, 2489),
                        designScreenPadding: const EdgeInsets.fromLTRB(120, 320, 150, 260),
                        aspectRatio: aspect,
                        onLayout: (layout) {
                          // 挂孔中心：你按 PNG 量过再改
                          const holeCenter = Offset(120, 120);
                          _anchorVN.value = layout.designToGlobal(holeCenter);
                        },
                        child: _PhoneScreen(
                          wsOk: widget.wsOk,
                          rttMs: widget.rttMs,
                          page: _page,
                          chatFriend: _chatFriend,
                          onClose: _close, // 用带动画的 close
                          onBack: _back,
                          onGoFriends: _goFriends,
                          onOpenChat: _openChat,
                          onGoHelp: _goHelp,
                        ),
                      ),
                    ),
                  ),

                  // 3) 挂坠层：仍然铺满屏幕，用“全局 anchor”来画，所以能精准贴住手机
                  Positioned.fill(
                    child: IgnorePointer(
                      // 你想要挂件可拖拽就去掉 IgnorePointer
                      ignoring: false,
                      child: PendantLayer(
                        phoneFrameRectListenable: _frameRectVN,
                        anchorPxListenable: _anchorVN,
                        fallbackAnchorPx: const Offset(36, 72),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _goFriends() => setState(() => _page = PhonePage.friends);
  void _goHelp() => setState(() => _page = PhonePage.help);

  void _openChat(Friend friend) {
    setState(() {
      _page = PhonePage.chat;
      _chatFriend = friend;
    });
  }

  void _back() {
    setState(() {
      if (_page == PhonePage.chat) {
        _page = PhonePage.friends;
      } else if (_page == PhonePage.friends) {
        _page = PhonePage.home;
      }else if (_page == PhonePage.help) {
        _page = PhonePage.home;
      }else {
        _close();
      }
    });
  }

  Rect? _getFrameGlobalRect() {
    final ctx = _frameKey.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero);
    return topLeft & box.size;
  }
}


class _PhoneScreen extends StatelessWidget {
  final bool wsOk;
  final int rttMs;
  final PhonePage page;
  final Friend? chatFriend;

  final VoidCallback onClose;
  final VoidCallback onBack;
  final VoidCallback onGoFriends;
  final VoidCallback onGoHelp;
  final void Function(Friend) onOpenChat;

  const _PhoneScreen({
    required this.wsOk,
    required this.rttMs,
    required this.page,
    required this.chatFriend,
    required this.onClose,
    required this.onBack,
    required this.onGoFriends,
    required this.onGoHelp,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    final title = switch (page) {
      PhonePage.home => "手机",
      PhonePage.friends => "好友",
      PhonePage.chat => (chatFriend?.displayName ?? "聊天"),
      PhonePage.help => "说明",
      
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset("assets/ui/phone_bg.png", fit: BoxFit.cover),
        if (page != PhonePage.chat) Container(color: Colors.white.withValues(alpha: 0.06)),

        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.black.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: _buildPage(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPage() {
    switch (page) {
      case PhonePage.home:
        return _PhoneHomePage(wsOk: wsOk, rttMs: rttMs, onOpenFriends: onGoFriends, onOpenHelp: onGoHelp);
      case PhonePage.friends:
        return FriendsListView(embedded: true, onSelect: onOpenChat);
      case PhonePage.chat:
        return ChatPage(
          friendId: chatFriend!.id,
          title: chatFriend!.displayName,
          embedded: true,
          onBack: onBack,
        );
      case PhonePage.help:
        return const PhoneHelpPage();  
    }
  }
}

class _PhoneHomePage extends StatelessWidget {
  final bool wsOk;
  final int rttMs;
  final VoidCallback onOpenFriends;
  final VoidCallback onOpenHelp;

  const _PhoneHomePage({
    required this.wsOk,
    required this.rttMs,
    required this.onOpenFriends,
    required this.onOpenHelp,
  });

  @override
  Widget build(BuildContext context) {
    final rttText = rttMs < 0 ? "--" : "${rttMs}ms";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: wsOk ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                wsOk ? "WS 已连接" : "WS 未连接",
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text("延迟 $rttText", style: TextStyle(color: Colors.black.withValues(alpha: 0.65))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onOpenFriends,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Icon(Icons.people_alt_rounded, color: Colors.black.withValues(alpha: 0.75)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text("好友", style: TextStyle(fontWeight: FontWeight.w900)),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.black.withValues(alpha: 0.35)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onOpenHelp,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.black.withValues(alpha: 0.75)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text("说明", style: TextStyle(fontWeight: FontWeight.w900)),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.black.withValues(alpha: 0.35)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}



