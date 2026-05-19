import 'package:flutter/material.dart';
import '../home/game_theme.dart';
import 'dart:io';


//生成一个“提示行 UI”
Widget hint(BuildContext context, String text) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.info_outline, size: 16, color: GameTheme.muted(0.7)),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: GameTheme.tiny(context))),
    ],
  );
}

//把用户输入的“分类名”转换成一个稳定的 id
String slug(String s) {
  // 先简单：中文也能当作id用（文件夹名可用），后续要严格再改
  return s.trim().toLowerCase().replaceAll(' ', '_');
}

//把“批量输入”拆分成一个列表。
List<String> splitBatch(String raw) {
  return raw
      .split(RegExp(r'[,，\n\r]+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

//单个资源条目 UI
class SmallAssetRow extends StatelessWidget {
  const SmallAssetRow({
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
}