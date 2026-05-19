  class AppConfig {
  static const String httpBase = "http://127.0.0.1:6667"; // 你的 getfriend.py 端口
  static const String wsUrl    = "ws://127.0.0.1:6666";   // 你的 ws.py 端口
  static const String token    = "inabameguru";             // ws.py / getfriend.py 都用这个
  static const int userId      = 0;                          // 你当前后端写死的单用户
}