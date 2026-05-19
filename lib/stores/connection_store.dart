import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../api/ws_client.dart';
import 'game_notice_store.dart';

class ConnectionStore extends ChangeNotifier {
  final ApiClient api;
  final WsClient ws;
  final GameNoticeStore notice;

  bool wsConnected = false;
  int httpRttMs = -1;

  Timer? _timer;

  ConnectionStore(this.api, this.ws, this.notice);

  void start() {
    ws.connect();
    wsConnected = ws.isConnected;
    notifyListeners();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final prevWs = wsConnected;

      final sw = Stopwatch()..start();
      try {
        await api.fetchFriends();
        sw.stop();
        httpRttMs = sw.elapsedMilliseconds;
      } catch (_) {
        httpRttMs = -1;
      }

      wsConnected = ws.isConnected;

      if (prevWs && !wsConnected) {
        notice.error(
          '连接丢失，WS 当前未正常连接',
          avatarPath: 'assets/■■■/■■■.png',
        );
      } else if (!prevWs && wsConnected) {
        notice.success(
          'WS 已恢复连接',
          avatarPath: 'assets/■■■/■■■.png',
        );
      }

      notifyListeners();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    ws.close();
    wsConnected = false;
    notifyListeners();
  }
}