import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../api/ws_client.dart';
import '../config.dart';

class ChatItem {
  final bool isMe;
  final String text;
  final int ts;
  ChatItem({required this.isMe, required this.text, required this.ts});
}

class ChatStore extends ChangeNotifier {
  final ApiClient api;
  final WsClient ws;

  final List<ChatItem> items = [];
  StreamSubscription? _sub;

  int _lastMsgId = 1;
  int? currentFriendId;

  bool _loadingMore = false;
  bool hasMore = true;
  int? _oldestTs; // 当前列表里最早的 create_at

  ChatStore(this.api, this.ws);

  Future<void> openChat(int friendId, {String type = "one2one"}) async {
    currentFriendId = friendId;
    items.clear();
    hasMore = true;
    _oldestTs = null;

    // 1) 首次拉取历史：允许失败（新后端没有接口）

    try {
      final res = await api.fetchPrivateHistory(
        friendId,
        beforeTime: 0,
        type: "one2one", //后续要修改为“phone”
      );

      _appendHistoryRows(res.rows, atHead: false);
      // 后端直接写出还有没有更多
      hasMore = res.hasMore;
      //hasMore = true;

    } catch (e, st) {
      debugPrint("[ChatStore] fetchPrivateHistory failed: $e");
      debugPrint("$st");
      hasMore = false;
    }

    // 2) 订阅 WS
    _sub?.cancel();
    _sub = ws.stream.listen((msg) {
      // 1) type 过滤：兼容后端 type 为空 / phone
      final t = (msg["type"] ?? "").toString();
      final isPhone = (t.isEmpty || t == "phone");
      if (!isPhone) return;

      // 2) 会话过滤：只收当前 friendId 对应的 ai_id
      final aiId = msg["ai_id"];
      if (aiId != friendId) return;

      // 3) content 提取
      final content = (msg["content"] ?? "").toString();
      if (content.isEmpty) return;

      String text;
      try {
        final obj = jsonDecode(content);
        text = obj["text"] ?? content;
      } catch (_) {
        text = content; // 如果不是 JSON，就当普通文本
      }

      // 4) 用 role 判断是谁发的
      /*final role = (msg["role"] ?? "").toString(); // "user" / "ai"
      final isMe = role == "user"; // 如果后端回显用户消息也走 WS，这里就正确

      final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      items.add(ChatItem(isMe: isMe, text: text, ts: ts));
      notifyListeners();*/

      final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      items.add(ChatItem(isMe: false, text: text, ts: ts));
      notifyListeners();
    });
    
    //清空缓存，防止切换好友时闪现之前的消息
    notifyListeners();

  }

  /// rows: 后端返回倒序（新->旧）
  void _appendHistoryRows(List<dynamic> rows, {required bool atHead}) {
    if (rows.isEmpty) return;

    final parsed = rows.map((r) {
      final m = (r as Map).cast<String, dynamic>();
      final role = (m["role"] ?? "").toString(); // user / assistant
      final content = (m["content"] ?? "").toString();
      final ts = (m["time_stamp"] is int)
          ? (m["time_stamp"] as int)
          : int.tryParse((m["time_stamp"] ?? "0").toString()) ?? 0;

      final isMe = role == "user";
      return ChatItem(isMe: isMe, text: content, ts: ts);
    }).where((m) => m.text.isNotEmpty && m.ts > 0).toList();

    if (parsed.isEmpty) return;

    // 防止后端顺序变动：统一按时间升序（旧->新）
    parsed.sort((a, b) => a.ts.compareTo(b.ts));

    // 更新最早时间戳（用于 before_time）
    final oldest = parsed.first.ts;
    _oldestTs = (_oldestTs == null) ? oldest : (_oldestTs! < oldest ? _oldestTs : oldest);

    if (atHead) {
      // 加载更多：插到头部（这些本来就是更旧的）
      items.insertAll(0, parsed);
    } else {
      items.addAll(parsed);
    }
  }

  // 加载更多（滚动到顶部时触发）
  Future<int> loadMore({String type = "one2one"}) async { //后续要修改为“phone”
    final fid = currentFriendId;
    if (fid == null) return 0;
    if (!hasMore || _loadingMore) return 0;
    if (_oldestTs == null) return 0;

    _loadingMore = true;
    try {
      final before = _oldestTs!;
      final res = await api.fetchPrivateHistory(
        fid,
        beforeTime: before,
        type: type,
      );
      print("beforeTime: $before  type=${before.runtimeType}");

      final beforeCount = items.length;
      _appendHistoryRows(res.rows, atHead: true);
      final added = items.length - beforeCount;

      hasMore = res.hasMore;

      if (added > 0) notifyListeners();
      return added;
    } finally {
      _loadingMore = false;
    }
  }

  void closeChat() {
    _sub?.cancel();
    _sub = null;
    currentFriendId = null;
  }

  void send(String text) {
    final fid = currentFriendId;
    if (fid == null) return;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    items.add(ChatItem(isMe: true, text: text, ts: now));
    notifyListeners();

    ws.sendText(
      toAiId: fid,
      fromUserId: AppConfig.userId,
      content: text,
      lastMsgId: _lastMsgId++,
      type: "one2one",
    );
  }
}
