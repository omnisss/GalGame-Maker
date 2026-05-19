import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../stores/connection_store.dart';

import '../widgets/phone_overlay.dart';
//import '../widgets/main_home.dart';
import '../widgets/phone_mini_badge.dart';
import '../stores/chat_store.dart';
import '../api/api_client.dart';
import '../api/ws_client.dart';
import 'main_home.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  bool _phoneOpen = false;


  
  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnectionStore>();
    final api = context.read<ApiClient>();
    final ws  = context.read<WsClient>();

    return Scaffold(
      body: Stack(
        children: [

          // ===== 主界面（纯展示）=====
          MainHome(
            wsOk: conn.wsConnected,
            rttMs: conn.httpRttMs,
          ),

          // ===== 右下角小胶囊 =====
          Positioned(
            right: 18,
            bottom: 18,
            child: GestureDetector(
              onTap: () => setState(() => _phoneOpen = true),
              child: PhoneMiniBadge(
                wsOk: conn.wsConnected,
                rttMs: conn.httpRttMs,
              ),
            ),
          ),

          // ===== 手机 Overlay（独立文件）=====
          if (_phoneOpen)
            ChangeNotifierProvider<ChatStore>(
              // 关键：ChatStore 只在手机打开时存在，关闭就 dispose
              create: (_) => ChatStore(api, ws),
              child: PhoneOverlay(
                wsOk: conn.wsConnected,
                rttMs: conn.httpRttMs,
                onClose: () => setState(() => _phoneOpen = false),
              ),
            ),
        ],
      ),
    );
  }
}
