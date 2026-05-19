import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/friend.dart';

class ApiClient {
  Map<String, String> get _headers => {
    "Authorization": "Bearer ${AppConfig.token}",
    "Content-Type": "application/json",
  };
  

  // 获取好友列表
  Future<List<Friend>> fetchFriends() async {
    final uri = Uri.parse("${AppConfig.httpBase}/v1/friends");
    //final uri = Uri.parse("${AppConfig.httpBase}/user/friends");
    final resp = await http.get(uri, headers: _headers);

    if (resp.statusCode != 200) {
      throw Exception("friends http ${resp.statusCode}");
    }

    final obj = jsonDecode(resp.body);
    final data = obj["data"];

    if (data is! List) return const [];

    // 关键：这里把 Map -> Friend
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => Friend.fromJson(e))
        .toList();
  }

  // 获取与某个好友的聊天历史（旧版get请求）
  /*Future<List<dynamic>> fetchPrivateHistory(int friendId, {int? beforetime}) async {
    final uri = Uri.parse(
      beforetime == null
        ? "${AppConfig.httpBase}/v1/history?friendId=$friendId"
        : "${AppConfig.httpBase}/v1/history?friendId=$friendId&beforetime=$beforetime"
    );
    /*final uri = Uri.parse(
      beforetime == null
        ? "${AppConfig.httpBase}/user/privatehistory?friendId=$friendId"
        : "${AppConfig.httpBase}/user/privatehistory?friendId=$friendId&beforetime=$beforetime"
    );*/
    final resp = await http.get(uri, headers: _headers);

    if (resp.statusCode != 200) {
      throw Exception("history http ${resp.statusCode}");
    }

    final obj = jsonDecode(resp.body);

    final data = obj["data"];
    if (data is List) {
      return data;
    }

    return [];
  }*/

  // 获取与某个好友的聊天历史（POST版请求）
  Future<HistoryResult> fetchPrivateHistory(
    int aiId, {
    int beforeTime = 0,
    String type = "one2one",
  }) async {
    final uri = Uri.parse("${AppConfig.httpBase}/v1/history");

    final resp = await http.post(
      uri,
      headers: {
        ..._headers,
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "ai_id": aiId,
        "type": type,
        "before_time": beforeTime,
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception("history http ${resp.statusCode}");
    }

    final obj = jsonDecode(resp.body);

    final data = obj["data"];
    final rows = (data is List) ? data : <dynamic>[];

    final hasMore = (obj["has_more"] == true);

    return HistoryResult(rows: rows, hasMore: hasMore);
  }

  // 获取与某个好友的 AI 状态
  Future<Map<String, dynamic>> fetchAiStatus(int friendId) async {
    final uri = Uri.parse("${AppConfig.httpBase}/user/aistatus?friendId=$friendId");
    final resp = await http.get(uri, headers: _headers);
    if (resp.statusCode != 200) throw Exception("status http ${resp.statusCode}");
    final obj = jsonDecode(resp.body);
    final data = obj["data"];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return {};
  }

  /// 一对一：保存人设 + 资源索引
  Future<void> saveOne2OneProfile(Map<String, dynamic> payload) async {
    final uri = Uri.parse("${AppConfig.httpBase}/v1/save");

    final resp = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(payload),
    );

    if (resp.statusCode != 200) {
      throw Exception("one2one save http ${resp.statusCode}: ${resp.body}");
    }
  }
}

// 这个类用来封装 fetchPrivateHistory 的结果，包含 rows 和 hasMore 两个字段
class HistoryResult {
  final List<dynamic> rows;
  final bool hasMore;
  HistoryResult({required this.rows, required this.hasMore});
}
