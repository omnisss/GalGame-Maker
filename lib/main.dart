import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api/api_client.dart';
import 'api/ws_client.dart';
import 'stores/connection_store.dart';
import 'pages/main_shell_page.dart';
import 'pages/story_mode_page.dart';
import 'pages/one2one_edit_page.dart';
import 'pages/one2one_play_page.dart';
import 'widgets/global_notice/global_notice_host.dart';
import 'stores/game_notice_store.dart';

void main() {
  final api = ApiClient();
  final ws = WsClient();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameNoticeStore()),
        ChangeNotifierProxyProvider<GameNoticeStore, ConnectionStore>(
          create: (context) => ConnectionStore(
            api,
            ws,
            context.read<GameNoticeStore>(),
          )..start(),
          update: (context, notice, previous) =>
              previous ?? ConnectionStore(api, ws, notice)..start(),
        ),
        Provider.value(value: api),
        Provider.value(value: ws),
      ],
      
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'MyRounded',
      ),
      //消息层
      builder: (context, child) {
        return GlobalNoticeHost(
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const MainShellPage(),
      routes: {
        "/story": (_) => const StoryModePage(),
        "/one2one_play": (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          final roleId = (args?["roleId"] as String?) ?? "10001";
          final startMode = (args?["startMode"] as String?) ?? "auto";
          return One2OnePlayPage(
            roleId: roleId,
            startMode: startMode,
          );
        },
      },
      // 用它处理带参数的 /one2one
      onGenerateRoute: (settings) {
        if (settings.name == "/one2one") {
          final args = settings.arguments;
          final map = (args is Map) ? args : null;
          final roleId = (map?['roleId'] as String?)?.trim(); // 可能为 null

          return MaterialPageRoute(
            builder: (_) => One2OneEditPage(roleId: roleId), // 可空
            settings: settings,
          );
        }
        return null; // 交给默认处理
      },
    );
  }
}
