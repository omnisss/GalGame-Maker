import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'one2one_asset_store.dart';

class One2OnePersonaStore {
  static Future<File> _personaFile(String roleId) async {
    // 复用资源存储根：桌面端 <exe>/data/ ，移动端 Documents/
    final root = await One2OneAssetStore.roleRoot(roleId);

    final profilesDir = Directory(p.join(root.path, 'profiles'));
    if (!profilesDir.existsSync()) profilesDir.createSync(recursive: true);

    return File(p.join(profilesDir.path, 'o2o_$roleId.json'));
  }

  /// 方便你确认：输出实际保存路径
  static Future<String> debugPersonaPath(String roleId) async {
    final f = await _personaFile(roleId);
    return f.path;
  }

  static Future<Map<String, dynamic>?> loadPersona(String roleId) async {
    final f = await _personaFile(roleId);
    if (!await f.exists()) return null;
    final txt = await f.readAsString();
    final obj = jsonDecode(txt);
    if (obj is Map<String, dynamic>) return obj;
    return null;
  }

  static Future<void> savePersona(
    String roleId, {
    required String name,
    required String persona,
  }) async {
    final f = await _personaFile(roleId);
    final obj = <String, dynamic>{
      'schema': 1,
      'roleId': roleId,
      'name': name,
      'persona': persona,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    await f.writeAsString(
      const JsonEncoder.withIndent('  ').convert(obj),
      flush: true,
    );
  }
}