import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'one2one_asset_store.dart';

class One2OneSaveStateStore {
  static const _fileName = 'save_state.json';

  static Future<File> _file(String roleId) async {
    final root = await One2OneAssetStore.roleRoot(roleId);
    return File(p.join(root.path, _fileName));
  }

  static int _nowTs() =>
      DateTime.now().millisecondsSinceEpoch ~/ 1000;

  static Map<String, dynamic> _default() => <String, dynamic>{
        "schema": 1,
        "activeMode": "draft",
        "draftSnapshot": <String, dynamic>{
          "updatedAt": null,
        },
        "gamingSnapshot": <String, dynamic>{
          "updatedAt": null,
          "established": false,
          "runtimeState": null,
        }
      };

  static Future<Map<String, dynamic>> load(String roleId) async {
    final f = await _file(roleId);
    if (!await f.exists()) return _default();

    try {
      final obj = jsonDecode(await f.readAsString());
      if (obj is Map<String, dynamic>) {
        return {
          ..._default(),
          ...obj,
        };
      }
    } catch (_) {}
    return _default();
  }

  static Future<void> _write(String roleId, Map<String, dynamic> data) async {
    final f = await _file(roleId);
    final tmp = File(f.path + ".tmp");

    await tmp.writeAsString(
      const JsonEncoder.withIndent("  ").convert(data),
      flush: true,
    );

    if (await f.exists()) await f.delete();
    await tmp.rename(f.path);
  }

  /// ========= 草稿更新 =========
  static Future<void> saveDraft(String roleId) async {
    final cur = await load(roleId);
    cur["activeMode"] = "draft";
    cur["draftSnapshot"]["updatedAt"] = _nowTs();
    await _write(roleId, cur);
  }

  /// ========= 游戏状态保存 =========
  /*static Future<void> saveGamingState(
    String roleId,
    Map<String, dynamic> runtimeState,
  ) async {
    final cur = await load(roleId);

    cur["activeMode"] = "gaming";
    cur["gamingSnapshot"]["updatedAt"] = _nowTs();
    cur["gamingSnapshot"]["runtimeState"] = runtimeState;

    await _write(roleId, cur);
  }*/
  //首回合成功后，正式把入口切到 gaming，防止第一回合ai回复失败导致坏档
  static Future<void> promoteToGaming(
    String roleId,
    Map<String, dynamic> runtimeState,
  ) async {
    final cur = await load(roleId);
    cur["activeMode"] = "gaming";
    cur["gamingSnapshot"]["updatedAt"] = _nowTs();
    cur["gamingSnapshot"]["established"] = true;
    cur["gamingSnapshot"]["runtimeState"] = runtimeState;
    await _write(roleId, cur);
  }

  //只更新游戏快照，不改入口，负责后续回合正常更新
  static Future<void> saveGamingSnapshot(
    String roleId,
    Map<String, dynamic> runtimeState,
  ) async {
    final cur = await load(roleId);
    cur["gamingSnapshot"]["updatedAt"] = _nowTs();
    cur["gamingSnapshot"]["runtimeState"] = runtimeState;
    await _write(roleId, cur);
  }
  //只更新游戏状态
  static Future<void> activateGaming(String roleId) async {
    final cur = await load(roleId);
    cur["activeMode"] = "gaming";
    await _write(roleId, cur);
  }

  /// ========= 读取游戏运行态 =========
  static Future<Map<String, dynamic>?> loadRuntimeState(
      String roleId) async {
    final cur = await load(roleId);
    return cur["gamingSnapshot"]?["runtimeState"];
  }

  static String activeModeOf(Map<String, dynamic> state) {
    final m = state["activeMode"];
    if (m == "gaming" || m == "draft") return m;
    return "draft";
  }
  /// ========= 判断入口 =========
  static bool hasEstablishedGamingSnapshot(Map<String, dynamic> state) {
    final gaming = (state["gamingSnapshot"] as Map?)?.cast<String, dynamic>();
    if (gaming == null) return false;
    return gaming["established"] == true && gaming["runtimeState"] != null;
  }
}