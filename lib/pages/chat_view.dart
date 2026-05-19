import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../stores/chat_store.dart';

class ChatView extends StatefulWidget {
  final int friendId;
  final String title;

  /// 手机内用：是否显示顶部（如果你手机外面已经有顶栏，这里就 false）
  final bool showHeader;

  /// 手机内用：返回按钮回调（不走 Navigator）
  final VoidCallback? onBack;
  //类型
  final String type;

  const ChatView({
    super.key,
    required this.friendId,
    required this.title,
    this.type = "one2one", //后续要修改为“phone”
    this.showHeader = false,
    this.onBack,

  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  late final ChatStore _store;
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  bool _initialScrolled = false;
  int? _openedFriendId; // 记录当前已 open 的 friendId，防止重复 open

  @override
  void initState() {
    super.initState();
    _store = context.read<ChatStore>();
    _scroll.addListener(_onScroll);

    // 首次打开
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _openIfNeeded(widget.friendId);
    });
  }

  @override
  void didUpdateWidget(covariant ChatView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 手机内切换不同好友时，widget 可能不销毁，需要在这里重新 openChat
    if (oldWidget.friendId != widget.friendId) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _openIfNeeded(widget.friendId, force: true);
      });
    }
  }

  Future<void> _openIfNeeded(int friendId, {bool force = false}) async {
    if (!force && _openedFriendId == friendId) return;

    _initialScrolled = false;
    _openedFriendId = friendId;

    await _store.openChat(friendId, type: widget.type);

    // 打开后滚到底
    _scrollToBottom();
    _initialScrolled = true;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _onScroll() async {
    if (!_scroll.hasClients) return;

    // 到顶部触发加载更多
    if (_scroll.position.pixels <= 0) {
      if (!_store.hasMore) return;

      final oldPixels = _scroll.position.pixels;
      final oldMax = _scroll.position.maxScrollExtent;

      final added = await _store.loadMore(type: widget.type);
      if (added <= 0) return;

      // 保持视图不跳
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scroll.hasClients) return;
        final newMax = _scroll.position.maxScrollExtent;
        final delta = newMax - oldMax;
        _scroll.jumpTo(oldPixels + delta);
      });
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _store.closeChat();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ChatStore>();

    // 新消息来了，且用户在底部附近时自动跟随到底
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      if (!_initialScrolled) return;

      final distToBottom = _scroll.position.maxScrollExtent - _scroll.position.pixels;
      if (distToBottom < 120) {
        _scrollToBottom();
      }
    });

    return Column(
      children: [
        if (widget.showHeader) _Header(title: widget.title, onBack: widget.onBack),

        Expanded(
          child: ListView.builder(

            controller: _scroll,
            padding: const EdgeInsets.all(12),
            itemCount: store.items.length,
            itemBuilder: (_, i) {
              final m = store.items[i];
              final align = m.isMe ? Alignment.centerRight : Alignment.centerLeft;
              final color = m.isMe ? Colors.blue.withValues(alpha: 1.0) : const Color.fromARGB(255, 220, 219, 219).withValues(alpha: 1.0) ;
              return Align(
                alignment: align,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(m.text),
                ),
              );
            },
          ),
        ),

        // 手机里一般也要 SafeArea；如果你手机屏幕已经裁剪过，也没问题
        // 底部输入区：加白底“底板”，避免背景透出来
        AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            decoration: BoxDecoration(
              //color: Colors.white, // ✅ 不透明
              border: Border(
                top: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 16,
                  offset: const Offset(0, -6),
                  color: Colors.black.withValues(alpha: 0.08),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: InputDecoration(
                        hintText: "输入消息",
                        isDense: true,
                        filled: true, // ✅ 输入框内部也给底色
                        fillColor: const Color(0xFFF2F3F5),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.10)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.10)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.22)),
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 42,
                    width: 42,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _send,
                      child: const Icon(Icons.send, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

      ],
    );
  }

  void _send() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    _store.send(t);
    _ctrl.clear();
    _scrollToBottom();
  }
}

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  const _Header({required this.title, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 44), // 占位让标题居中
        ],
      ),
    );
  }
}
