import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class One2OneIdStore {
  static const String kStartId = "10001";

  /// 基础目录：
  /// - 桌面端：<exe>/data/
  /// - 移动端：Documents/
  static Future<Directory> _baseDir() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final cwd = Directory.current.path;
      final dir = Directory(p.join(cwd, 'data'));
      if (!dir.existsSync()) dir.createSync(recursive: true);
      return dir;
    }
    return await getApplicationDocumentsDirectory();
  }

  /// one2one 根目录（用于扫描已有角色 id）
  static Future<Directory> _one2oneDir() async {
    final base = await _baseDir();
    final dir = Directory(p.join(base.path, 'one2one'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  static Future<File> _indexFile() async {
    final base = await _baseDir();
    if (!base.existsSync()) base.createSync(recursive: true);
    return File(p.join(base.path, '_index.json'));
  }

  static int _parseIdOrNeg(String s) => int.tryParse(s) ?? -1;

  /// 扫描本地已有 one2one/<id>/，计算下一个安全 id
  static Future<int> _computeNextIdFromDisk() async {
    final one2one = await _one2oneDir();
    int maxId = -1;

    for (final ent in one2one.listSync(followLinks: false)) {
      if (ent is Directory) {
        final name = p.basename(ent.path);
        final v = _parseIdOrNeg(name);
        if (v > maxId) maxId = v;
      }
    }

    final start = int.parse(kStartId);
    final next = (maxId >= start) ? (maxId + 1) : start;
    return next;
  }

  static Future<void> _writeNextId(File f, int next) async {
    final tmp = File(f.path + '.tmp');
    await tmp.writeAsString(
      const JsonEncoder.withIndent('  ').convert({'nextId': next.toString()}),
      flush: true,
    );
    if (await f.exists()) await f.delete();
    await tmp.rename(f.path);
  }

  /// 分配一个新的 String id（自愈 index 丢失/损坏，并避免撞目录）
  static Future<String> allocate() async {
    final f = await _indexFile();
    final one2one = await _one2oneDir();
    final startInt = int.parse(kStartId);

    int nextInt;

    // 1) 优先读 index
    if (await f.exists()) {
      try {
        final obj = jsonDecode(await f.readAsString());
        final s = (obj is Map) ? obj['nextId'] : null;
        nextInt = _parseIdOrNeg(s?.toString() ?? '');
      } catch (_) {
        nextInt = -1;
      }
    } else {
      nextInt = -1;
    }

    // 2) index 不存在/损坏/小于起始值 => 从磁盘扫描自愈
    if (nextInt < startInt) {
      nextInt = await _computeNextIdFromDisk();
      await _writeNextId(f, nextInt); // 立即修复 index
    }

    // 3) 防撞：如果 one2one/<id> 已存在，就继续加直到找到空位
    while (Directory(p.join(one2one.path, nextInt.toString())).existsSync()) {
      nextInt += 1;
    }

    // 4) 写回 index（下一次可用）
    await _writeNextId(f, nextInt + 1);

    return nextInt.toString();
  }
}