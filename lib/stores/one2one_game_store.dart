import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';

import '../api/ws_client.dart';
import '../config.dart';
import '../widgets/one2one/one2one_save_state_store.dart';
import '../widgets/one2one/one2one_asset_store.dart';
import 'game_notice_store.dart';
import '../widgets/game_scene/actions/actor_motion_runtime.dart';
import '../widgets/game_scene/actions/actor_motion_translator.dart';

class One2OneGameStore extends ChangeNotifier {
  final WsClient ws;
  final String roleId;
  final GameNoticeStore notice;

  late Map<String, Map<String, List<String>>> _spriteIndex; // outfit -> emotion -> files
  late Map<String, String> _bgIndex;           //key = “教室-晚上”，value = 对应 variant.file
  bool _assetsReady = false;
  //动作
  late final ActorMotionRuntime motion = ActorMotionRuntime(
    onChanged: notifyListeners,
  );
  //暴露给页面读取的 getter
  double get actorBaseX => motion.baseX;
  double get actorBaseY => motion.baseY;
  double get actorBaseScale => motion.baseScale;
  double get actorBaseRotation => motion.baseRotation;
  double get actorBaseOpacity => motion.baseOpacity;
  double get actorBaseDownShiftFactor => motion.baseDownShiftFactor;

  double get actorActionX => motion.actionX;
  double get actorActionY => motion.actionY;
  double get actorActionScale => motion.actionScale;
  double get actorActionRotation => motion.actionRotation;
  double get actorActionOpacity => motion.actionOpacity;

  String get actorPosture => motion.currentPosture;
  //等待界面用，判断是否为首回合
  bool _waitingOpeningReply = false;
  int _openingRetryCount = 0;
  static const int _maxOpeningRetry = 3;
  //给play用的，判断是否是开局对话
  bool get isWaitingOpeningReply => _waitingOpeningReply;
  bool get isReadyForScene {
    if (!loaded) return false;
    if (_waitingOpeningReply) return false;
    return true;
  }
  //用于输入框锁定
  bool _waitingReply = false;
  bool get isWaitingReply => _waitingReply;

  StreamSubscription? _sub;

  //默认状态：
  Map<String, dynamic> runtime = {
    "bgPath": "",
    "spritePath": "",
    "outfit": "",
    "emotion": "",
    "vars": {"affection": 0},
    "cursor": {"lastMsgId": 0},
    "historyTail": <Map<String, dynamic>>[],
    "gameTime": {
      "year": 2026,
      "month": 5,
      "day": 20,
      "hour": 13,
      "minute": 14,
    },
  };
  bool loaded = false;

  final _rng = Random();

  One2OneGameStore(this.ws, this.roleId, this.notice);

  //ai开启第一句话时才设置这个默认状态
  Map<String, dynamic> _buildRuntimeFromAssets() {
    String bg = '';
    String sp = '';
    String outfit = '';
    String emotion = '';

    if (_bgIndex.isNotEmpty) {
      bg = _bgIndex.values.first;
    }

    for (final outfitEntry in _spriteIndex.entries) {
      for (final emotionEntry in outfitEntry.value.entries) {
        if (emotionEntry.value.isNotEmpty) {
          outfit = outfitEntry.key;
          emotion = emotionEntry.key;
          sp = emotionEntry.value.first;
          break;
        }
      }
      if (sp.isNotEmpty) break;
    }

    return {
      "bgPath": bg,
      "spritePath": sp,
      "outfit": outfit,
      "emotion": emotion,
      "vars": {"affection": 0},
      "cursor": {"lastMsgId": 0},
      "historyTail": <Map<String, dynamic>>[],
      "gameTime": {
        "year": 2026,
        "month": 3,
        "day": 18,
        "hour": 20,
        "minute": 0,
      },
    };
  }
  //根据命名约定解析资源路径的函数
  String _pickSprite({
    required String outfit,
    required String emotion,
    String? fallbackRel,
  }) {
    final o = outfit.trim();
    final e = emotion.trim();
    final byEmotion = _spriteIndex[o];
    final list = byEmotion?[e];
    if (list == null || list.isEmpty) return fallbackRel ?? '';
    return list[_rng.nextInt(list.length)];
  }

  Future<void> applyPostureCommand(String? posture) async {
    final spec = ActorMotionTranslator.translatePosture(posture);
    if (spec == null) return;
    await motion.applyPose(spec, postureName: posture?.trim().isNotEmpty == true ? posture!.trim() : '正常');
  }

  Future<void> playActionCommand(String? action) async {
    final spec = ActorMotionTranslator.translateAction(action);
    if (spec == null) return;
    await motion.playAction(spec);
  }
  //最后一个消息id
  int get lastMsgId {
    final v = runtime["cursor"]?["lastMsgId"];
    return (v is int) ? v : 0;
  }
  //开始游戏
  Future<void> start({String mode = "auto"}) async {
    await _loadAssetIndex();

    final save = await One2OneSaveStateStore.load(roleId);
    final canResume = One2OneSaveStateStore.hasEstablishedGamingSnapshot(save);

    final effectiveMode = switch (mode) {
      "fresh" => "fresh",
      "resume" => "resume",
      _ => (canResume ? "resume" : "fresh"),
    };

    _sub?.cancel();
    _sub = ws.stream.listen(_onWsMsg);

    if (effectiveMode == "resume") {
      runtime =
          (await One2OneSaveStateStore.loadRuntimeState(roleId)) ??
              _buildRuntimeFromAssets();
      runtime = _upgradeLegacyRuntime(runtime);
      runtime = _repairRuntimeAssets(runtime);

      // 读取posture并应用
      final savedPosture = (runtime["posture"] ?? "正常").toString();
      await applyPostureCommand(savedPosture);
      //读取action并应用，这里默认不开放
      /*final savedAction = (runtime["action"] ?? "").toString().trim();
      if (savedAction.isNotEmpty && savedAction != '无') {
        unawaited(playActionCommand(savedAction));
      }*/
      
      _waitingOpeningReply = false;
      _openingRetryCount = 0;
      loaded = true;
      notifyListeners();
      return;
    }

    _waitingOpeningReply = true;
    _openingRetryCount = 0;
    loaded = true;
    notifyListeners(); // 这里通知的是“进入加载页”

    _sendOpeningProbe();
  }

  //首发对话
  void _sendOpeningProbe() {
    final probeId = lastMsgId + 1;

    ws.sendText(
      toAiId: int.tryParse(roleId) ?? 0,
      fromUserId: AppConfig.userId,
      content: "（当前为第一回合对话，请先开始开场白）",
      lastMsgId: probeId,
      type: "one2one",
    );
  }
  //首回合校验
  bool _isOpeningReplyValid(Map<String, dynamic> content) {
    final text = (content["text"] ?? "").toString().trim();
    return text.isNotEmpty;
  }
  //首回合失败重开
  Future<void> _retryOpeningIfNeeded() async {
    if (!_waitingOpeningReply) return;

    _openingRetryCount++;
    if (_openingRetryCount > _maxOpeningRetry) {
      _waitingOpeningReply = false;
      notice.error(
        "首回合加载失败，请返回重试",
        avatarPath: 'assets/■■■/■■■.png',
      );
      notifyListeners();
      return;
    }

    _sendOpeningProbe();
  }

  //修复函数：gaming状态下资源缺失提示
  bool _bgExists(String rel) => rel.isNotEmpty && _bgIndex.values.contains(rel);

  bool _spriteExists(String rel) {
    if (rel.isEmpty) return false;

    for (final byEmotion in _spriteIndex.values) {
      for (final files in byEmotion.values) {
        if (files.contains(rel)) return true;
      }
    }
    return false;
  }
  //丢失资源后自动替换其他可选项，已弃用
  /*String? _firstAvailableBg() {
    if (_bgIndex.isEmpty) return null;
    return _bgIndex.values.first;
  }

  String? _firstAvailableSprite() {
    for (final list in _spriteIndex.values) {
      if (list.isNotEmpty) return list.first;
    }
    return null;
  }*/


  Map<String, dynamic> _repairRuntimeAssets(Map<String, dynamic> rt) {
    final fixed = Map<String, dynamic>.from(rt);

    final bg = (fixed["bgPath"] ?? "").toString();
    final sp = (fixed["spritePath"] ?? "").toString();

    if (!_bgExists(bg)) {
      fixed["bgPath"] = "";
      if (bg.isNotEmpty) {
        notice.warning(
          "当前快照背景资源缺失",
          avatarPath: 'assets/■■■/■■■.png',
        );
      }
    }
    if (!_spriteExists(sp)) {
      fixed["spritePath"] = "";
      if (sp.isNotEmpty) {
        notice.warning(
          "当前快照立绘资源缺失",
          avatarPath: 'assets/■■■/■■■.png',
        );
      }
    }

    return fixed;
  }

  void disposeStore() {
    motion.dispose();
    _sub?.cancel();
    _sub = null;
  }

  void _onWsMsg(Map<String, dynamic> msg) async {
    final t = (msg["type"] ?? "").toString();
    if (t != "one2one") return;

    final aiId = msg["ai_id"];
    if (aiId == null) return;
    if (aiId.toString() != roleId) return; // roleId 就是 ai_id 字符串

    // content 可能是 Map 或 JSON String（你们之前就遇到过）
    final raw = msg["content"];
    Map<String, dynamic>? content;
    if (raw is Map<String, dynamic>) {
      content = raw;
    } else if (raw is String) {
      try {
        final obj = jsonDecode(raw);
        if (obj is Map<String, dynamic>) content = obj;
      } catch (_) {}
    }
    //错误格式重新回复
    if (content == null) {
      //这里也要解锁输入框
      if (!_waitingOpeningReply) {
        _waitingReply = false;
        notifyListeners();
      }
      await _retryOpeningIfNeeded();
      return;
    }

    if (_waitingOpeningReply && !_isOpeningReplyValid(content)) {
      await _retryOpeningIfNeeded();
      return;
    }

    final name = (content["name"] ?? "AI").toString();
    final text = (content["text"] ?? "").toString();
    final emotion = (content["emotion"] ?? "").toString();
    final outfit = (content["outfit"] ?? "").toString();
    final background = (content["background"] ?? "").toString();
    final action = (content["action"] ?? "").toString();
    final posture = (content["posture"] ?? "").toString();

    Map<String, dynamic>? gameTime;
    final rawTime = content["time"];
    if (rawTime is Map) {
      gameTime = rawTime.cast<String, dynamic>();
    }

    final nowTs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final msgId = (msg["msgId"] is int) ? (msg["msgId"] as int) : (lastMsgId + 1);

    // 收到当前回合回复，解锁输入
    _waitingReply = false;

    // 收到 AI 回复，更新 runtime 并存盘
    _applyAssistantReply(
      name: name,
      text: text,
      outfit: outfit,
      emotion: emotion,
      background: background,
      posture: posture,
      action: action,
      gameTime: gameTime,
      msgId: msgId,
      ts: nowTs,
    );
  }

  // 发送用户消息：先更新 historyTail，再发 ws
  Future<void> sendUserText(String text) async {
    final s = text.trim();
    if (s.isEmpty) return;

    final nowTs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final msgId = lastMsgId + 1;

    // 等回复期间，不允许再次发送
    if (_waitingReply || _waitingOpeningReply) return;

    runtime = {
      ...runtime,
      "cursor": {"lastMsgId": msgId},
      "historyTail": [
        {"role": "user", "text": s, "ts": nowTs, "msgId": msgId}
      ],
    };
    
    //构造完成，锁住输入框
    _waitingReply = true;
    
    notifyListeners();
    await One2OneSaveStateStore.saveGamingSnapshot(roleId, runtime);

    try {
      ws.sendText(
        toAiId: int.tryParse(roleId) ?? 0,
        fromUserId: AppConfig.userId,
        content: s,
        lastMsgId: msgId,
        type: "one2one",
      );
    } catch (e) {
      notice.error(
        "连接丢失，消息发送失败",
        avatarPath: 'assets/■■■/■■■.png',
      );
      _waitingReply = false;
      //rethrow;
    }
  }
  // 下面是一些基于命名约定的资源解析方法，以及对 AI 回复的处理逻辑
  String _resolveBackground(String background, {String? fallbackRel}) {
    final raw = background.trim();
    if (raw.isEmpty) return fallbackRel ?? '';

    // 去扩展名
    final key = raw.replaceAll(RegExp(r'\.(jpg|png|webp)$', caseSensitive: false), '').trim();

    // 1) 精确
    final exact = _bgIndex[key];
    if (exact != null) return exact;

    // 2) 模糊：包含/被包含
    for (final k in _bgIndex.keys) {
      if (k.contains(key) || key.contains(k)) return _bgIndex[k]!;
    }

    return fallbackRel ?? '';
  }

  //兼容旧存档的情绪解析方法
  String _pickSpriteByEmotionLegacy(String emotion, {String? fallbackRel}) {
    final e = emotion.trim();
    if (e.isEmpty) return fallbackRel ?? '';

    for (final byEmotion in _spriteIndex.values) {
      final list = byEmotion[e];
      if (list != null && list.isNotEmpty) {
        return list[_rng.nextInt(list.length)];
      }
    }
    return fallbackRel ?? '';
  }

  //基于命名的资源读取
  Future<void> _loadAssetIndex() async {
    final loaded = await One2OneAssetStore.loadAssets(roleId);
    _spriteIndex = {};
    _bgIndex = {};

    if (loaded == null) {
      _assetsReady = false;
      return;
    }

    for (final cell in loaded.sprites) {
      final outfit = cell.outfit.trim();
      final emotion = cell.emotion.trim();

      final files = <String>[];
      for (final v in cell.variants) {
        final rel = (v.file ?? '').trim();
        if (rel.isNotEmpty) files.add(rel);
      }
      if (outfit.isEmpty || emotion.isEmpty || files.isEmpty) continue;
      _spriteIndex.putIfAbsent(outfit, () => {});
      _spriteIndex[outfit]![emotion] = files;
    }
    for (final folder in loaded.backgrounds) {
      for (final v in folder.variants) {
        final k = v.title.trim();
        final rel = (v.file ?? '').trim();
        if (k.isNotEmpty && rel.isNotEmpty) _bgIndex[k] = rel;
      }
    }
    _assetsReady = true;
  }

  //兼容旧存档
  Map<String, dynamic> _upgradeLegacyRuntime(Map<String, dynamic> rt) {
    String bg = (rt["bgPath"] ?? "").toString();
    String sp = (rt["spritePath"] ?? "").toString();

    if (!_isRelAssetPath(bg)) {
      final key = bg
          .replaceAll(RegExp(r'\.(jpg|png|webp)$', caseSensitive: false), '')
          .trim();
      final mapped = _bgIndex[key];
      if (mapped != null) bg = mapped;
    }

    if (!_isRelAssetPath(sp)) {
      final m = RegExp(
        r'^(.+?)-\d+\.(png|jpg|webp)$',
        caseSensitive: false,
      ).firstMatch(sp.trim());

      final emotion = m?.group(1)?.trim() ?? "";
      if (emotion.isNotEmpty) {
        sp = _pickSpriteByEmotionLegacy(emotion, fallbackRel: sp);
      }
    }

    final fixed = {
      ...rt,
      "bgPath": bg,
      "spritePath": sp,
    };

    if ((fixed["outfit"] ?? "").toString().trim().isEmpty) {
      fixed["outfit"] = "默认";
    }
    if ((fixed["emotion"] ?? "").toString().trim().isEmpty) {
      final m = RegExp(
        r'^(.+?)-\d+\.(png|jpg|webp)$',
        caseSensitive: false,
      ).firstMatch(sp.trim());
      fixed["emotion"] = m?.group(1)?.trim() ?? "";
    }

    return fixed;
  }
  bool _isRelAssetPath(String s) => s.trim().startsWith("assets/");

  //更新 AI 回复：根据消息内容更新 runtime 中的 bgPath、spritePath、historyTail 等字段，并存盘
  void _applyAssistantReply({
    required String name,
    required String text,
    required String outfit,
    required String emotion,
    required String background,
    required String posture,
    required String action,
    required Map<String, dynamic>? gameTime,
    required int msgId,
    required int ts,
  }) async {
    final String bgRel = _assetsReady
        ? _resolveBackground(background, fallbackRel: runtime["bgPath"]?.toString())
        : (runtime["bgPath"]?.toString() ?? "");

    final String spRel = _assetsReady
        ? _pickSprite(
            outfit: outfit,
            emotion: emotion,
            fallbackRel: runtime["spritePath"]?.toString(),
          )
        : (runtime["spritePath"]?.toString() ?? "");

    final List tail = (runtime["historyTail"] as List?) ?? const [];
    Map<String, dynamic>? lastUser;
    if (tail.isNotEmpty) {
      final last = tail.last;
      if (last is Map && last["role"] == "user") {
        lastUser = last.cast<String, dynamic>();
      }
    }

    final assistant = {
      "role": "assistant",
      "name": name,
      "text": text,
      "ts": ts,
      "msgId": msgId,
      "emotion": emotion,
      "background": background,
    };

    runtime = {
      ...runtime,
      if (bgRel.isNotEmpty) "bgPath": bgRel,
      if (spRel.isNotEmpty) "spritePath": spRel,
      "outfit": outfit.isNotEmpty ? outfit : (runtime["outfit"] ?? ""),
      "emotion": emotion.isNotEmpty ? emotion : (runtime["emotion"] ?? ""),
      "posture": posture.isNotEmpty ? posture : (runtime["posture"] ?? "正常"),
      "action": action.isNotEmpty ? action : (runtime["action"] ?? "无"),
      if (gameTime != null) "gameTime": {
        "year": (gameTime["year"] as num?)?.toInt() ?? 2026,
        "month": (gameTime["month"] as num?)?.toInt() ?? 1,
        "day": (gameTime["day"] as num?)?.toInt() ?? 1,
        "hour": (gameTime["hour"] as num?)?.toInt() ?? 0,
        "minute": (gameTime["minute"] as num?)?.toInt() ?? 0,
      },
      "cursor": {"lastMsgId": msgId},
      "historyTail": [
        if (lastUser != null) lastUser,
        {
          ...assistant,
          if (gameTime != null) "time": gameTime,
        },
      ],
    };
    runtime = _repairRuntimeAssets(runtime);
    notifyListeners();
    if (posture.trim().isNotEmpty) {
      await applyPostureCommand(posture);
    }

    if (action.trim().isNotEmpty) {
      unawaited(playActionCommand(action));
    }
    if (_waitingOpeningReply) {
      _waitingOpeningReply = false;
      _openingRetryCount = 0;
      await One2OneSaveStateStore.promoteToGaming(roleId, runtime);
    } else {
      await One2OneSaveStateStore.saveGamingSnapshot(roleId, runtime);
    }
  }
}
