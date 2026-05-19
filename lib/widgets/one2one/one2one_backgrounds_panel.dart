import 'package:flutter/material.dart';
import '../home/game_theme.dart';
import 'one2one_assets_shared.dart';
import 'one2one_input_dialog.dart';
import 'one2one_models.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'one2one_section_card.dart';


//右侧：背景面板
class One2OneBackgroundsPanel extends StatelessWidget {
  const One2OneBackgroundsPanel({
    super.key,
    required this.backgroundFolders,
    required this.onChanged,
    required this.roleRootPath, 
  });

  final List<BackgroundFolder> backgroundFolders;
  final VoidCallback onChanged;
  final String? roleRootPath;

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
                  //final id = slug(name);

                  // 默认 3 条变体
                  const defaults = ['白天', '黄昏', '晚上'];
                  final variants = List.generate(
                    3,
                    (i) => BackgroundVariant(
                      title:'$name-${defaults[i]}',
                      note: '未绑定文件',
                    ),
                  );

                  backgroundFolders.add(BackgroundFolder(title: name, variants: variants));
                  onChanged();
                },
                icon: const Icon(Icons.create_new_folder_outlined),
                label: const Text('创建分类'),
              ),
            ],
          ),
          child: Column(
            children: [
              hint(context, '对应目录：assets/backgrounds/<分类文件夹>/<变体文件>'),
              const SizedBox(height: 12),
              ...backgroundFolders.map((folder) => _BackgroundFolderTile(
                    folder: folder,
                    onChanged: onChanged,
                    roleRootPath: roleRootPath,
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
                      final v = await one2oneBgVariantDialog(
                        context,
                        title: '添加变体',
                        defaultPlace: folder.title, // 默认地点=分类名
                      );
                      if (v == null || v.trim().isEmpty) return;

                      final idx = backgroundFolders.indexOf(folder);
                      final next = List<BackgroundVariant>.from(folder.variants)
                        ..add(BackgroundVariant(
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
                      final items = splitBatch(v);
                      if (items.isEmpty) return;

                      final idx = backgroundFolders.indexOf(folder);
                      final next = List<BackgroundVariant>.from(folder.variants);
                      for (final t in items) {
                        next.add(BackgroundVariant(
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

// 分类（文件夹）条目 UI
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
    required this.roleRootPath,
  });

  final BackgroundFolder folder;
  final VoidCallback onChanged;
  final String? roleRootPath;

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
              ...folder.variants.map((v) => SmallAssetRow(
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
                    thumbPath: v.pickedPath ?? _abs(roleRootPath, v.file),
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
                      final nv = await one2oneBgVariantDialog(
                        context,
                        title: '编辑变体（地点-时间）',
                        defaultPlace: folder.title,
                        initialValue: v.title, // 回填并拆分
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

// 资源文件绝对路径拼接
String? _abs(String? root, String? rel) {
  if (root == null || rel == null || rel.trim().isEmpty) return null;
  return p.join(root, rel);
}