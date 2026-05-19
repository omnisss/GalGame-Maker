import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'one2one_models.dart';

class One2OneAssetStore {
  /// 基础目录：
  /// - 桌面端：<exe>/data/
  /// - 移动端：Documents/
  static Future<Directory> _baseDir() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Directory.current 由启动方式决定（IDE/快捷方式可能改变）
      final cwd = Directory.current.path;
      final dir = Directory(p.join(cwd, 'data'));
      if (!dir.existsSync()) dir.createSync(recursive: true);
      return dir;
    }
    // Android / iOS：系统推荐的可写目录
    return await getApplicationDocumentsDirectory();
  }

  /// 列出本地已有的一对一角色目录（roleId 列表）。
  /// 用于主界面“读取存档”网格。
  static Future<List<String>> listRoleIds() async {
    final base = await _baseDir();
    final one2oneDir = Directory(p.join(base.path, 'one2one'));
    if (!one2oneDir.existsSync()) return <String>[];

    final ids = <String>[];
    for (final e in one2oneDir.listSync(followLinks: false)) {
      if (e is Directory) {
        ids.add(p.basename(e.path));
      }
    }
    ids.sort((a, b) {
      final ia = int.tryParse(a) ?? 0;
      final ib = int.tryParse(b) ?? 0;
      return ia.compareTo(ib);
    });
    return ids;
  }

  /// 返回：<base>/one2one/<roleId>/
  static Future<Directory> roleRoot(String roleId) async {
    final base = await _baseDir();
    final dir = Directory(p.join(base.path, 'one2one', roleId));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  /// 方便调试：输出保存根路径
  static Future<String> debugRoleRootPath(String roleId) async {
    final root = await roleRoot(roleId);
    return root.path;
  }

  /// 保存所有 pickedPath 到最终目录，并写 manifest.json
  static Future<void> saveAssets({
    required String roleId,
    required List<SpriteCell> spriteCells,
    required List<BackgroundFolder> backgroundFolders,
  }) async {
    final root = await roleRoot(roleId);

    final assetsDir = Directory(p.join(root.path, 'assets'));
    if (!assetsDir.existsSync()) assetsDir.createSync(recursive: true);

    // 目标根：assets/sprites 和 assets/backgrounds
    final spritesRoot = Directory(p.join(assetsDir.path, 'sprites'));
    final bgsRoot = Directory(p.join(assetsDir.path, 'backgrounds'));
    spritesRoot.createSync(recursive: true);
    bgsRoot.createSync(recursive: true);

    // 1) 复制 sprites
    for (final cell in spriteCells) {
      final cellDir = Directory(
        p.join(spritesRoot.path, cell.outfit, cell.emotion),
      );
      cellDir.createSync(recursive: true);

      for (final variant in cell.variants) {
        if (variant.pickedPath == null) continue;

        final src = File(variant.pickedPath!);
        if (!src.existsSync()) continue;

        final ext = p.extension(src.path).toLowerCase();
        final safeName =
            _safeFileName(variant.variant) + (ext.isEmpty ? '.png' : ext);
        final dst = File(p.join(cellDir.path, safeName));

        await src.copy(dst.path);
      }
    }

    // 2) 复制 backgrounds
    for (final folder in backgroundFolders) {
      final folderDir = Directory(p.join(bgsRoot.path, folder.title));
      folderDir.createSync(recursive: true);

      for (final v in folder.variants) {
        if (v.pickedPath == null) continue;

        final src = File(v.pickedPath!);
        if (!src.existsSync()) continue;

        final ext = p.extension(src.path).toLowerCase();
        final safeName =
            _safeFileName(v.title) + (ext.isEmpty ? '.jpg' : ext);
        final dst = File(p.join(folderDir.path, safeName));

        await src.copy(dst.path);
      }
    }

    // 3) 写 manifest（保存“相对路径索引”，供运行时/预览使用）
    final manifest = <String, dynamic>{
      'schema': 2,
      'roleId': roleId,
      'sprites': [
        for (final cell in spriteCells)
          {
            'outfit': cell.outfit,
            'emotion': cell.emotion,
            'variants': [
              for (final v in cell.variants)
                {
                  'variant': v.variant,
                  'file': v.file,
                }
            ]
          }
      ],
      'backgrounds': [
        for (final folder in backgroundFolders)
          {
            'title': folder.title,
            'variants': [
              for (final v in folder.variants)
                {
                  'title': v.title,
                  'file': v.file,
                }
            ]
          }
      ],
      'updatedAt': DateTime.now().toIso8601String(),
    };

    final mf = File(p.join(assetsDir.path, 'manifest.json'));
    await mf.writeAsString(const JsonEncoder.withIndent('  ').convert(manifest));
  }

  // 安全文件名：去除非法字符，避免不同系统间的兼容问题
  static String _safeFileName(String raw) {
    return raw.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  // 读取 manifest.json，返回已绑定资源列表（包含相对路径）。如果没有或格式错误，返回 null。
  static Future<({List<SpriteCell> sprites, List<BackgroundFolder> backgrounds})?> loadAssets(
    String roleId,
  ) async {
    final root = await roleRoot(roleId);
    final mf = File(p.join(root.path, 'assets', 'manifest.json'));
    if (!await mf.exists()) return null;

    final obj = jsonDecode(await mf.readAsString());
    if (obj is! Map<String, dynamic>) return null;

    final sprites = <SpriteCell>[];
    final bgs = <BackgroundFolder>[];

    final spriteList = (obj['sprites'] as List?) ?? const [];
    for (final sf in spriteList) {
      final m = sf as Map<String, dynamic>;
      final variants = <SpriteVariant>[];
      final variantList = (m['variants'] as List?) ?? const [];
      for (final v in variantList) {
        final vm = v as Map<String, dynamic>;
        variants.add(
          SpriteVariant(
            variant: (vm['variant'] ?? '') as String,
            file: vm['file'] as String?,
            note: '已绑定',
          ),
        );
      }
      sprites.add(
        SpriteCell(
          outfit: (m['outfit'] ?? '') as String,
          emotion: (m['emotion'] ?? '') as String,
          variants: variants,
        ),
      );
    }

    final bgList = (obj['backgrounds'] as List?) ?? const [];
    for (final bf in bgList) {
      final m = bf as Map<String, dynamic>;
      final vars = <BackgroundVariant>[];
      final varList = (m['variants'] as List?) ?? const [];
      for (final v in varList) {
        final vm = v as Map<String, dynamic>;
        vars.add(BackgroundVariant(
          title: (vm['title'] ?? '') as String,
          file: (vm['file'] as String?), // 读回 file
          note: '已绑定',
        ));
      }
      bgs.add(BackgroundFolder(
        title: (m['title'] ?? '') as String,
        variants: vars,
      ));
    }

    return (sprites: sprites, backgrounds: bgs);
  }
}
