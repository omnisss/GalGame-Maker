import 'package:flutter/material.dart';
import 'chat_view.dart';

class ChatPage extends StatelessWidget {
  final int friendId;
  final String title;

  /// true: 放在 PhoneFrame 内，不要 Scaffold/AppBar
  final bool embedded;

  /// embedded=true 时用的返回回调（不走 Navigator）
  final VoidCallback? onBack;

  const ChatPage({
    super.key,
    required this.friendId,
    required this.title,
    this.embedded = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    if (embedded) {
      // 手机内嵌：用 ChatView 自己的 Header
      return ChatView(
        friendId: friendId,
        title: title,
        showHeader: false, //手机外面已经有标题了
        onBack: onBack,
      );
    }

    // 全屏：走系统 AppBar
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ChatView(
        friendId: friendId,
        title: title,
        showHeader: false,
      ),
    );
  }
}
