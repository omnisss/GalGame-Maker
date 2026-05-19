import 'dart:collection';
import 'package:flutter/material.dart';

enum GameNoticeType {
  info,
  success,
  warning,
  error,
}

class GameNoticeData {
  final String message;
  final String speaker;
  final String avatarPath;
  final GameNoticeType type;
  final bool dismissOnTap;

  const GameNoticeData({
    required this.message,
    this.speaker = '■■■',
    this.avatarPath = '',
    this.type = GameNoticeType.info,
    this.dismissOnTap = true,
  });
}

class GameNoticeStore extends ChangeNotifier {
  final Queue<GameNoticeData> _queue = Queue<GameNoticeData>();

  GameNoticeData? _current;
  bool _visible = false;

  GameNoticeData? get current => _current;
  bool get visible => _visible;

  void show(GameNoticeData data) {
    // 如果当前没有显示，立即显示
    if (!_visible || _current == null) {
      _current = data;
      _visible = true;
      notifyListeners();
      return;
    }

    // 有提示时入队
    _queue.addLast(data);
    notifyListeners();
  }

  void dismiss() {
    if (!_visible) return;

    if (_queue.isNotEmpty) {
      _current = _queue.removeFirst();
      _visible = true;
    } else {
      _current = null;
      _visible = false;
    }
    notifyListeners();
  }

  void clearAll() {
    _queue.clear();
    _current = null;
    _visible = false;
    notifyListeners();
  }

  void info(String text, {String avatarPath = ''}) {
    show(GameNoticeData(
      message: text,
      speaker: '■■■',
      avatarPath: avatarPath,
      type: GameNoticeType.info,
    ));
  }

  void success(String text, {String avatarPath = ''}) {
    show(GameNoticeData(
      message: text,
      speaker: '■■■',
      avatarPath: avatarPath,
      type: GameNoticeType.success,
    ));
  }

  void warning(String text, {String avatarPath = ''}) {
    show(GameNoticeData(
      message: text,
      speaker: '■■■',
      avatarPath: avatarPath,
      type: GameNoticeType.warning,
    ));
  }

  void error(String text, {String avatarPath = ''}) {
    show(GameNoticeData(
      message: text,
      speaker: '■■■',
      avatarPath: avatarPath,
      type: GameNoticeType.error,
    ));
  }
}