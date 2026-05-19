// 立绘和背景的管理面板,废弃了
/*import 'package:flutter/material.dart';
import '../home/game_theme.dart';
import 'one2one_input_dialog.dart';
import 'one2one_models.dart';
import 'one2one_section_card.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

/// =========================
/// 左侧：立绘面板
/// =========================
class One2OneSpritesPanel extends StatelessWidget {
  const One2OneSpritesPanel({
    super.key,
    required this.spriteFolders,
    required this.onChanged,
  });

  final List<SpriteFolder> spriteFolders;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        One2OneSectionCard(
          title: '立绘（按文件夹分类）',
          trailing: Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                style: GameTheme.one2oneSoftButtonStyle(),
                onPressed: () async {
                  final folderName = await one2oneInputDialog(
                    context,
                    title: '创建立绘分类（文件夹）',
                    hintText: '例如：高兴 / 难过 / 害羞',
                  );
                  if (folderName == null || folderName.trim().isEmpty) return;

                  final name = folderName.trim();
                  final id = _slug(name);

                  // 默认 3 条差分
                  final frames = List.generate(
                    3,
                    (i) => SpriteFrame(
                      id: '${id}_${i + 1}',
                      title: '$name-${i + 1}',
                      note: '未绑定文件',
                    ),
                  );

                  spriteFolders.add(SpriteFolder(id: id, title: name, frames: frames));
                  onChanged();
                },
                icon: const Icon(Icons.create_new_folder_outlined),
                label: const Text('创建分类'),
              ),
            ],
          ),
          child: Column(
            children: [
              _hint(context, '对应目录：assets/sprites/<分类文件夹>/<差分文件>'),
              const SizedBox(height: 12),
              ...spriteFolders.map((folder) => _SpriteFolderTile(
                    folder: folder,
                    onChanged: onChanged,
                    onRenameFolder: () async {
                      final v = await one2oneInputDialog(
                        context,
                        title: '重命名分类',
                        initialValue: folder.title,
                      );
                      if (v == null || v.trim().isEmpty) return;
                      final idx = spriteFolders.indexOf(folder);
                      spriteFolders[idx] = folder.copyWith(title: v.trim());
                      onChanged();
                    },
                    onDeleteFolder: () {
                      spriteFolders.remove(folder);
                      onChanged();
                    },
                    onAddSingle: () async {
                      final v = await one2oneInputDialog(
                        context,
                        title: '添加差分',
                        hintText: '例如：高兴-4',
                      );
                      if (v == null || v.trim().isEmpty) return;
                      final idx = spriteFolders.indexOf(folder);
                      final next = List<SpriteFrame>.from(folder.frames)
                        ..add(SpriteFrame(
                          id: '${folder.id}_${folder.frames.length + 1}',
                          title: v.trim(),
                          note: '未绑定文件',
                        ));
                      spriteFolders[idx] = folder.copyWith(frames: next);
                      onChanged();
                    },
                    onBatchAdd: () async {
                      final v = await one2oneInputDialog(
                        context,
                        title: '批量添加差分',
                        hintText: '用逗号或换行分隔，例如：\n高兴-4, 高兴-5\n高兴-6',
                      );
                      if (v == null || v.trim().isEmpty) return;
                      final items = _splitBatch(v);
                      if (items.isEmpty) return;

                      final idx = spriteFolders.indexOf(folder);
                      final next = List<SpriteFrame>.from(folder.frames);
                      for (final t in items) {
                        next.add(SpriteFrame(
                          id: '${folder.id}_${next.length + 1}',
                          title: t,
                          note: '未绑定文件',
                        ));
                      }
                      spriteFolders[idx] = folder.copyWith(frames: next);
                      onChanged();
                    },
                    onUpdateFrame: (frame, newFrame) {
                      final folderIdx = spriteFolders.indexOf(folder);
                      final frames = List<SpriteFrame>.from(folder.frames);
                      final fi = frames.indexOf(frame);
                      frames[fi] = newFrame;
                      spriteFolders[folderIdx] = folder.copyWith(frames: frames);
                      onChanged();
                    },
                    onDeleteFrame: (frame) {
                      final folderIdx = spriteFolders.indexOf(folder);
                      final frames = List<SpriteFrame>.from(folder.frames)..remove(frame);
                      spriteFolders[folderIdx] = folder.copyWith(frames: frames);
                      onChanged();
                    },
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

/// =========================
/// 右侧：背景面板
/// =========================
class One2OneBackgroundsPanel extends StatelessWidget {
  const One2OneBackgroundsPanel({
    super.key,
    required this.backgroundFolders,
    required this.onChanged,
  });

  final List<BackgroundFolder> backgroundFolders;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        One2OneSectionCard(
          title: '背景（按文件夹分类）',
          trailing: Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                style: GameTheme.one2oneSoftButtonStyle(),
                onPressed: () async {
                  final folderName = await one2oneInputDialog(
                    context,
                    title: '创建背景分类（文件夹）',
                    hintText: '例如：教室 / 天台 / 客厅',
                  );
                  if (folderName == null || folderName.trim().isEmpty) return;

                  final name = folderName.trim();
                  final id = _slug(name);

                  // 默认 3 条变体
                  const defaults = ['白天', '黄昏', '晚上'];
                  final variants = List.generate(
                    3,
                    (i) => BackgroundVariant(
                      id: '${id}_${i + 1}',
                      title: defaults[i],
                      note: '未绑定文件',
                    ),
                  );

                  backgroundFolders.add(BackgroundFolder(id: id, title: name, variants: variants));
                  onChanged();
                },
                icon: const Icon(Icons.create_new_folder_outlined),
                label: const Text('创建分类'),
              ),
            ],
          ),
          child: Column(
            children: [
              _hint(context, '对应目录：assets/backgrounds/<分类文件夹>/<变体文件>'),
              const SizedBox(height: 12),
              ...backgroundFolders.map((folder) => _BackgroundFolderTile(
                    folder: folder,
                    onChanged: onChanged,
                    onRenameFolder: () async {
                      final v = await one2oneInputDialog(
                        context,
                        title: '重命名分类',
                        initialValue: folder.title,
                      );
                      if (v == null || v.trim().isEmpty) return;
                      final idx = backgroundFolders.indexOf(folder);
                      backgroundFolders[idx] = folder.copyWith(title: v.trim());
                      onChanged();
                    },
                    onDeleteFolder: () {
                      backgroundFolders.remove(folder);
                      onChanged();
                    },
                    onAddSingle: () async {
                      final v = await one2oneInputDialog(
                        context,
                        title: '添加变体（单个）',
                        hintText: '例如：雨天 / 夜晚-灯光 / 白天-阴天',
                      );
                      if (v == null || v.trim().isEmpty) return;
                      final idx = backgroundFolders.indexOf(folder);
                      final next = List<BackgroundVariant>.from(folder.variants)
                        ..add(BackgroundVariant(
                          id: '${folder.id}_${folder.variants.length + 1}',
                          title: v.trim(),
                          note: '未绑定文件',
                        ));
                      backgroundFolders[idx] = folder.copyWith(variants: next);
                      onChanged();
                    },
                    onBatchAdd: () async {
                      final v = await one2oneInputDialog(
                        context,
                        title: '批量添加变体',
                        hintText: '用逗号或换行分隔，例如：\n雨天, 阴天\n夜晚-灯光',
                      );
                      if (v == null || v.trim().isEmpty) return;
                      final items = _splitBatch(v);
                      if (items.isEmpty) return;

                      final idx = backgroundFolders.indexOf(folder);
                      final next = List<BackgroundVariant>.from(folder.variants);
                      for (final t in items) {
                        next.add(BackgroundVariant(
                          id: '${folder.id}_${next.length + 1}',
                          title: t,
                          note: '未绑定文件',
                        ));
                      }
                      backgroundFolders[idx] = folder.copyWith(variants: next);
                      onChanged();
                    },
                    onUpdateVariant: (variant, newVariant) {
                      final folderIdx = backgroundFolders.indexOf(folder);
                      final list = List<BackgroundVariant>.from(folder.variants);
                      final vi = list.indexOf(variant);
                      list[vi] = newVariant;
                      backgroundFolders[folderIdx] = folder.copyWith(variants: list);
                      onChanged();
                    },
                    onDeleteVariant: (variant) {
                      final folderIdx = backgroundFolders.indexOf(folder);
                      final list = List<BackgroundVariant>.from(folder.variants)..remove(variant);
                      backgroundFolders[folderIdx] = folder.copyWith(variants: list);
                      onChanged();
                    },
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

/// ================= helpers （共用） =================

Widget _hint(BuildContext context, String text) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.info_outline, size: 16, color: GameTheme.muted(0.7)),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: GameTheme.tiny(context))),
    ],
  );
}

String _slug(String s) {
  // 先简单：中文也能当作id用（文件夹名可用），后续要严格再改
  return s.trim().toLowerCase().replaceAll(' ', '_');
}

List<String> _splitBatch(String raw) {
  return raw
      .split(RegExp(r'[,，\n\r]+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

/// ================== Sprite Folder Tile ==================

class _SpriteFolderTile extends StatelessWidget {
  const _SpriteFolderTile({
    required this.folder,
    required this.onChanged,
    required this.onRenameFolder,
    required this.onDeleteFolder,
    required this.onAddSingle,
    required this.onBatchAdd,
    required this.onUpdateFrame,
    required this.onDeleteFrame,
  });

  final SpriteFolder folder;
  final VoidCallback onChanged;

  final VoidCallback onRenameFolder;
  final VoidCallback onDeleteFolder;

  final VoidCallback onAddSingle;
  final VoidCallback onBatchAdd;

  final void Function(SpriteFrame frame, SpriteFrame newFrame) onUpdateFrame;
  final void Function(SpriteFrame frame) onDeleteFrame;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.45),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.35)),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: Row(
              children: [
                Expanded(child: Text(folder.title, style: GameTheme.h2(context))),
                Text('${folder.frames.length}项', style: GameTheme.tiny(context)),
              ],
            ),
            subtitle: Text('sprites/${folder.title}/', style: GameTheme.tiny(context)),
            trailing: Wrap(
              spacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // AI生成（分类级）
                GameTheme.one2oneGradientButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('占位：AI生成分类「${folder.title}」的立绘差分/建议')),
                    );
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_outlined, size: 18),
                      SizedBox(width: 6),
                      Text('AI生成'),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '重命名分类',
                  onPressed: onRenameFolder,
                  style: IconButton.styleFrom(
                    foregroundColor: GameTheme.accentPink,
                    overlayColor: GameTheme.accentPink.withOpacity(0.14),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
                IconButton(
                  tooltip: '删除分类',
                  onPressed: onDeleteFolder,
                  style: IconButton.styleFrom(
                    foregroundColor: GameTheme.accentPink,
                    overlayColor: GameTheme.accentPink.withOpacity(0.14),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 20),
                ),
              ],
            ),
            children: [
              ...folder.frames.map((f) => _SmallAssetRow(
                    kind: '差分',
                    title: f.title,
                    onAI: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('占位：AI生成差分「${folder.title}/${f.title}」')),
                      );
                    },
                    subtitle: f.pickedPath != null
                        ? (f.note ?? '待保存')
                        : (f.file != null ? '已绑定：${f.file}' : (f.note ?? '未设置')),
                    thumbPath: f.pickedPath,
                    onUpload: () async {
                      final r = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                        allowMultiple: false,
                      );
                      final path = r?.files.single.path;
                      if (path == null) return;

                      final fileName = p.basename(path);

                      onUpdateFrame(
                        f,
                        f.copyWith(
                          pickedPath: path,
                          note: '待保存：$fileName',
                        ),
                      );
                    },
                    onEdit: () async {
                      final v = await one2oneInputDialog(
                        context,
                        title: '编辑差分名称',
                        initialValue: f.title,
                      );
                      if (v == null || v.trim().isEmpty) return;
                      onUpdateFrame(f, f.copyWith(title: v.trim()));
                    },
                    onDelete: () => onDeleteFrame(f),
                  )),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    style: GameTheme.one2oneSoftButtonStyle(),
                    onPressed: onAddSingle,
                    icon: const Icon(Icons.add),
                    label: const Text('添加差分'),
                  ),
                  OutlinedButton.icon(
                    style: GameTheme.one2oneSoftButtonStyle(),
                    onPressed: onBatchAdd,
                    icon: const Icon(Icons.playlist_add),
                    label: const Text('批量添加'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ================== Background Folder Tile ==================

class _BackgroundFolderTile extends StatelessWidget {
  const _BackgroundFolderTile({
    required this.folder,
    required this.onChanged,
    required this.onRenameFolder,
    required this.onDeleteFolder,
    required this.onAddSingle,
    required this.onBatchAdd,
    required this.onUpdateVariant,
    required this.onDeleteVariant,
  });

  final BackgroundFolder folder;
  final VoidCallback onChanged;

  final VoidCallback onRenameFolder;
  final VoidCallback onDeleteFolder;

  final VoidCallback onAddSingle;
  final VoidCallback onBatchAdd;

  final void Function(BackgroundVariant v, BackgroundVariant newV) onUpdateVariant;
  final void Function(BackgroundVariant v) onDeleteVariant;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.45),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.35)),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: Row(
              children: [
                Expanded(child: Text(folder.title, style: GameTheme.h2(context))),
                Text('${folder.variants.length}项', style: GameTheme.tiny(context)),
              ],
            ),
            subtitle: Text('backgrounds/${folder.title}/', style: GameTheme.tiny(context)),
            trailing: Wrap(
              spacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                GameTheme.one2oneGradientButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('占位：AI生成分类「${folder.title}」的背景变体/建议')),
                    );
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_outlined, size: 18),
                      SizedBox(width: 6),
                      Text('AI生成'),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '重命名分类',
                  onPressed: onRenameFolder,
                  style: IconButton.styleFrom(
                    foregroundColor: GameTheme.accentPink,
                    overlayColor: GameTheme.accentPink.withOpacity(0.14),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
                IconButton(
                  tooltip: '删除分类',
                  onPressed: onDeleteFolder,
                  style: IconButton.styleFrom(
                    foregroundColor: GameTheme.accentPink,
                    overlayColor: GameTheme.accentPink.withOpacity(0.14),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 20),
                ),
              ],
            ),
            children: [
              ...folder.variants.map((v) => _SmallAssetRow(
                    kind: '变体',
                    title: v.title,
                    onAI: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('占位：AI生成变体「${folder.title}/${v.title}」的背景建议')),
                      );
                    },
                    subtitle: v.pickedPath != null
                        ? (v.note ?? '待保存')
                        : (v.file != null ? '已绑定：${v.file}' : (v.note ?? '未设置')),
                    thumbPath: v.pickedPath,
                    onUpload: () async {
                      final r = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                        allowMultiple: false,
                      );
                      final path = r?.files.single.path;
                      if (path == null) return;

                      final fileName = p.basename(path);

                      onUpdateVariant(
                        v,
                        v.copyWith(
                          pickedPath: path,
                          note: '待保存：$fileName',
                        ),
                      );
                    },
                    onEdit: () async {
                      final nv = await one2oneInputDialog(
                        context,
                        title: '编辑变体名称',
                        initialValue: v.title,
                      );
                      if (nv == null || nv.trim().isEmpty) return;
                      onUpdateVariant(v, v.copyWith(title: nv.trim()));
                    },
                    onDelete: () => onDeleteVariant(v),
                  )),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    style: GameTheme.one2oneSoftButtonStyle(),
                    onPressed: onAddSingle,
                    icon: const Icon(Icons.add),
                    label: const Text('添加变体'),
                  ),
                  OutlinedButton.icon(
                    style: GameTheme.one2oneSoftButtonStyle(),
                    onPressed: onBatchAdd,
                    icon: const Icon(Icons.playlist_add),
                    label: const Text('批量添加'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ================== Small Row （共用） ==================

class _SmallAssetRow extends StatelessWidget {
  const _SmallAssetRow({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.onAI,
    required this.onUpload,
    required this.onEdit,
    required this.onDelete,
    this.thumbPath,
  });

  final String kind;
  final String title;
  final String subtitle;
  final VoidCallback onAI;
  final VoidCallback onUpload;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  final String? thumbPath;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withOpacity(0.55),
                border: Border.all(color: Colors.white.withOpacity(0.35)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: (thumbPath != null && File(thumbPath!).existsSync())
                    ? Image.file(File(thumbPath!), fit: BoxFit.cover)
                    : Center(child: Text(kind, style: GameTheme.tiny(context))),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GameTheme.h2(context)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GameTheme.tiny(context)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GameTheme.one2oneGradientButton(
              onPressed: onAI,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_outlined, size: 18),
                  SizedBox(width: 6),
                  Text('AI生成'),
                ],
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: '上传',
              onPressed: onUpload,
              style: IconButton.styleFrom(
                foregroundColor: GameTheme.accentPink,
                overlayColor: GameTheme.accentPink.withOpacity(0.14),
              ),
              icon: const Icon(Icons.upload_file),
            ),
            IconButton(
              tooltip: '编辑',
              onPressed: onEdit,
              style: IconButton.styleFrom(
                foregroundColor: GameTheme.accentPink,
                overlayColor: GameTheme.accentPink.withOpacity(0.14),
              ),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: '删除',
              onPressed: onDelete,
              style: IconButton.styleFrom(
                foregroundColor: GameTheme.accentPink,
                overlayColor: GameTheme.accentPink.withOpacity(0.14),
              ),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}*/