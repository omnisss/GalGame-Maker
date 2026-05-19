import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../config.dart';

enum WsState { disconnected, connecting, connected }

class WsClient {
  WebSocketChannel? _ch;

  final _incoming = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get stream => _incoming.stream;

  final _state = ValueNotifier<WsState>(WsState.disconnected);
  ValueListenable<WsState> get stateListenable => _state;

  WsState get state => _state.value;
  bool get isConnected => state == WsState.connected;

  Timer? _reconnectTimer;

  void connect({bool autoRetry = true}) {
    // 避免重复连接
    if (state == WsState.connecting || state == WsState.connected) return;

    _state.value = WsState.connecting;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    try {
      _ch = IOWebSocketChannel.connect(
        Uri.parse("${AppConfig.wsUrl}/v1/ws"),
        headers: {"Authorization": "Bearer ${AppConfig.token}"},
      );

      // 等握手成功后再标记 connected
      _ch!.ready.then((_) {
        _state.value = WsState.connected;
      }).catchError((_) {
        _markDisconnected();
        if (autoRetry) _scheduleReconnect();
      });

      _ch!.stream.listen(
        (e) {
          try {
            final obj = jsonDecode(e as String);
            if (obj is Map<String, dynamic>) _incoming.add(obj);
          } catch (_) {}
        },
        onDone: () {
          _markDisconnected();
          if (autoRetry) _scheduleReconnect();
        },
        onError: (_) {
          _markDisconnected();
          if (autoRetry) _scheduleReconnect();
        },
      );
    } catch (_) {
      _markDisconnected();
      if (autoRetry) _scheduleReconnect();
    }
  }

  void _markDisconnected() {
    try { _ch?.sink.close(); } catch (_) {}
    _ch = null;
    _state.value = WsState.disconnected;
  }

  void _scheduleReconnect() {
    if (_reconnectTimer != null) return;
    _reconnectTimer = Timer(const Duration(seconds: 2), () {
      _reconnectTimer = null;
      connect(autoRetry: true);
    });
  }

  void close() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _markDisconnected();
  }

  void sendText({
    required int toAiId,
    required int fromUserId,
    required String content,
    required int lastMsgId,
    required String type, 
  }) {
    if (!isConnected) {
      // 你也可以在这里 connect() 一下再 throw，让用户“发一次自动重连”
      connect(autoRetry: true);
      throw Exception("连接丢失");
    }

    final payload = {
      "type": type,
      //"route_type": "private",
      //"msg_type": "text",
      "user_id": fromUserId,
      "ai_id": toAiId,
      //"group_id": 0,
      "content": content,
      "last_msg_id": lastMsgId,
      //"role": "user",
    };

    _ch!.sink.add(jsonEncode(payload));
  }
}
