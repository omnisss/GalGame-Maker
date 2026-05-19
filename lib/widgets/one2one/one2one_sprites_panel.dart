import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../home/game_theme.dart';
import 'one2one_assets_shared.dart';
import 'one2one_input_dialog.dart';
import 'one2one_models.dart';
import 'one2one_section_card.dart';
import '../../stores/game_notice_store.dart';

const double _axisColWidth = 180; //上表头宽
const double _headerHeight = 60; //上表头高
const double _cellWidth = 180; //单元格宽
const double _rowHeight = 260; //单元格/左表头行高
const double _headerWidth = 150; //左表头宽
const double _gridGap = 10; //微调用

class One2OneSpritesPanel extends StatelessWidget {
  const One2OneSpritesPanel({
    super.key,
    required this.spriteCells,
    required this.onChanged,
    required this.roleRootPath,
  });

  final List<SpriteCell> spriteCells;
  final VoidCallback onChanged;
  final String? roleRootPath;

  @override
  Widget build(BuildContext context) {
    final outfits = _collectOutfits(spriteCells);
    final emotions = _collectEmotions(spriteCells);

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        One2OneSectionCard(
          title: '立绘资源',
          trailing: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                style: GameTheme.one2oneSoftButtonStyle(),
                onPressed: () => _addOutfit(context),
                icon: const Icon(Icons.checkroom_outlined),
                label: const Text('新增服装'),
              ),
              OutlinedButton.icon(
                style: GameTheme.one2oneSoftButtonStyle(),
                onPressed: () => _addEmotion(context),
                icon: const Icon(Icons.emoji_emotions_outlined),
                label: const Text('新增表情'),
              ),
              OutlinedButton.icon(
                style: GameTheme.one2oneSoftButtonStyle(),
                onPressed: () {
                  _ensureMatrixComplete(spriteCells);
                  onChanged();
                },
                icon: const Icon(Icons.grid_view_rounded),
                label: const Text('补齐矩阵'),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              hint(
                context,
                '目录格式：assets/sprites/<服装>/<表情>/<差分文件>\nAI只会选择服装(outfit)和表情(emotion)，差分由前端随机选择。',
              ),
              const SizedBox(height: 12),
              if (outfits.isEmpty || emotions.isEmpty)
                _EmptyMatrixHint(
                  hasOutfits: outfits.isNotEmpty,
                  hasEmotions: emotions.isNotEmpty,
                )
              else
                _SpriteMatrix(
                  outfits: outfits,
                  emotions: emotions,
                  spriteCells: spriteCells,
                  roleRootPath: roleRootPath,
                  onChanged: onChanged,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _addOutfit(BuildContext context) async {
    final value = await one2oneInputDialog(
      context,
      title: '新增服装',
      hintText: '例如：校服 / 私服 / 泳装',
    );
    if (value == null || value.trim().isEmpty) return;

    final outfit = value.trim();
    final outfits = _collectOutfits(spriteCells);
    if (outfits.contains(outfit)) {
      _warn(context, '服装「$outfit」已存在');
      return;
    }

    final emotions = _collectEmotions(spriteCells);
    if (emotions.isEmpty) {
      spriteCells.add(
        const SpriteCell(
          outfit: '',
          emotion: '',
          variants: [],
        ),
      );
      final idx = spriteCells.length - 1;
      spriteCells[idx] = SpriteCell(
        outfit: outfit,
        emotion: '默认',
        variants: const [],
      );
    } else {
      for (final emotion in emotions) {
        spriteCells.add(
          SpriteCell(
            outfit: outfit,
            emotion: emotion,
            variants: const [],
          ),
        );
      }
    }

    onChanged();
  }

  Future<void> _addEmotion(BuildContext context) async {
    final value = await one2oneInputDialog(
      context,
      title: '新增表情',
      hintText: '例如：高兴 / 难过 / 惊讶',
    );
    if (value == null || value.trim().isEmpty) return;

    final emotion = value.trim();
    final emotions = _collectEmotions(spriteCells);
    if (emotions.contains(emotion)) {
      _warn(context, '表情「$emotion」已存在');
      return;
    }

    final outfits = _collectOutfits(spriteCells);
    if (outfits.isEmpty) {
      spriteCells.add(
        SpriteCell(
          outfit: '默认',
          emotion: emotion,
          variants: const [],
        ),
      );
    } else {
      for (final outfit in outfits) {
        spriteCells.add(
          SpriteCell(
            outfit: outfit,
            emotion: emotion,
            variants: const [],
          ),
        );
      }
    }

    onChanged();
  }
  //重复名称提示
  void _warn(BuildContext context, String text) {
    context.read<GameNoticeStore>().warning(
      text,
      avatarPath: 'assets/■■■/■■■.png',
    );
  }
}

class _EmptyMatrixHint extends StatelessWidget {
  const _EmptyMatrixHint({
    required this.hasOutfits,
    required this.hasEmotions,
  });

  final bool hasOutfits;
  final bool hasEmotions;

  @override
  Widget build(BuildContext context) {
    String text;
    if (!hasOutfits && !hasEmotions) {
      text = '先创建至少一个服装和一个表情。';
    } else if (!hasOutfits) {
      text = '请先创建至少一个服装。';
    } else {
      text = '请先创建至少一个表情。';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Text(
        text,
        style: GameTheme.body(context),
      ),
    );
  }
}

//矩阵主体
class _SpriteMatrix extends StatefulWidget {
  const _SpriteMatrix({
    required this.outfits,
    required this.emotions,
    required this.spriteCells,
    required this.roleRootPath,
    required this.onChanged,
  });

  final List<String> outfits;
  final List<String> emotions;
  final List<SpriteCell> spriteCells;
  final String? roleRootPath;
  final VoidCallback onChanged;

  @override
  State<_SpriteMatrix> createState() => _SpriteMatrixState();
}

class _SpriteMatrixState extends State<_SpriteMatrix> {
  late final ScrollController _hCtrl;

  @override
  void initState() {
    super.initState();
    _hCtrl = ScrollController();
  }

  @override
  void dispose() {
    _hCtrl.dispose();
    super.dispose();
  }
  //编辑表情
  Future<void> _editEmotion(String emotion) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _AxisPropertyDialog(
        title: '修改属性',
        initialValue: emotion,
        attributeLabel: '表情名称',
        deleteLabel: '删除该表情',
        onConfirm: (nextName) {
          _renameEmotion(emotion, nextName);
        },
        onDelete: () async {
          final ok = await _confirmDelete(
            title: '删除表情',
            content: '确认删除表情「$emotion」吗？这会删除对应整列单元格。',
          );
          if (ok) {
            _deleteEmotion(emotion);
          }
        },
      ),
    );
  }
  void _renameEmotion(String oldEmotion, String newEmotion) {
    final next = newEmotion.trim();
    if (next.isEmpty) {
      context.read<GameNoticeStore>().warning(
        '表情名称不能为空',
        avatarPath: 'assets/■■■/■■■.png',
      );
      return;
    }
    if (next == oldEmotion) return;

    final exists = widget.spriteCells.any((c) => c.emotion == next);
    if (exists) {
      context.read<GameNoticeStore>().warning(
        '表情「$next」已存在，无法重命名',
        avatarPath: 'assets/■■■/■■■.png',
      );
      return;
    }

    for (var i = 0; i < widget.spriteCells.length; i++) {
      final cell = widget.spriteCells[i];
      if (cell.emotion == oldEmotion) {
        widget.spriteCells[i] = cell.copyWith(emotion: next);
      }
    }

    widget.onChanged();
    setState(() {});
  }
  void _deleteEmotion(String emotion) {
    widget.spriteCells.removeWhere((c) => c.emotion == emotion);
    widget.onChanged();
    setState(() {});
  }
  //编辑服装
  Future<void> _editOutfit(String outfit) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _AxisPropertyDialog(
        title: '修改属性',
        initialValue: outfit,
        attributeLabel: '服装名称',
        deleteLabel: '删除该服装',
        onConfirm: (nextName) {
          _renameOutfit(outfit, nextName);
        },
        onDelete: () async {
          final ok = await _confirmDelete(
            title: '删除服装',
            content: '确认删除服装「$outfit」吗？这会删除对应整行单元格。',
          );
          if (ok) {
            _deleteOutfit(outfit);
          }
        },
      ),
    );
  }
  void _renameOutfit(String oldOutfit, String newOutfit) {
    final next = newOutfit.trim();
    if (next.isEmpty) {
      context.read<GameNoticeStore>().warning(
        '服装名称不能为空',
        avatarPath: 'assets/■■■/■■■.png',
      );
      return;
    }
    if (next == oldOutfit) return;

    final exists = widget.spriteCells.any((c) => c.outfit == next);
    if (exists) {
      context.read<GameNoticeStore>().warning(
        '服装「$next」已存在，无法重命名',
        avatarPath: 'assets/■■■/■■■.png',
      );
      return;
    }

    for (var i = 0; i < widget.spriteCells.length; i++) {
      final cell = widget.spriteCells[i];
      if (cell.outfit == oldOutfit) {
        widget.spriteCells[i] = cell.copyWith(outfit: next);
      }
    }

    widget.onChanged();
    setState(() {});
  }
  void _deleteOutfit(String outfit) {
    widget.spriteCells.removeWhere((c) => c.outfit == outfit);
    widget.onChanged();
    setState(() {});
  }
  //删除的二次确认
  Future<bool> _confirmDelete({
    required String title,
    required String content,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: GameTheme.accentPink.withValues(alpha: 0.94),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.16),
            ),
          ),
          title: Text(
            title,
            style: GameTheme.h2(context).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            content,
            style: GameTheme.body(context).copyWith(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
              ),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red.withValues(alpha: 0.22),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.red.withValues(alpha: 0.30),
                  ),
                ),
              ),
              child: const Text(
                '确认删除',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result == true;
  }
  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _hCtrl,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _hCtrl,
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth:  _axisColWidth + widget.emotions.length * (_cellWidth + _gridGap),
          ),
          child: Column(
            children: [
              _MatrixHeaderRow(
                emotions: widget.emotions,
                onTapEmotion: _editEmotion,
              ),
              const SizedBox(height: 10),
              for (final outfit in widget.outfits) ...[
                _MatrixOutfitRow(
                  outfit: outfit,
                  emotions: widget.emotions,
                  spriteCells: widget.spriteCells,
                  roleRootPath: widget.roleRootPath,
                  onChanged: widget.onChanged,
                  onTapOutfit: _editOutfit,
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AxisPropertyDialog extends StatefulWidget {
  const _AxisPropertyDialog({
    required this.title,
    required this.initialValue,
    required this.attributeLabel,
    required this.deleteLabel,
    required this.onConfirm,
    required this.onDelete,
  });

  final String title;
  final String initialValue;
  final String attributeLabel;
  final String deleteLabel;
  final ValueChanged<String> onConfirm;
  final Future<void> Function() onDelete;

  @override
  State<_AxisPropertyDialog> createState() => _AxisPropertyDialogState();
}
//编辑表头属性的对话框，支持修改名称和删除行/列
class _AxisPropertyDialogState extends State<_AxisPropertyDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: GameTheme.accentPink.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.16),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 28,
              spreadRadius: 2,
              color: Colors.black.withValues(alpha: 0.32),
            ),
            BoxShadow(
              blurRadius: 18,
              spreadRadius: 1,
              color: GameTheme.accentPink.withValues(alpha: 0.22),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: GameTheme.h2(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                labelText: widget.attributeLabel,
                labelStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.20),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.88),
                    width: 1.6,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () async {
                    await widget.onDelete();
                    if (!mounted) return;
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: Text(widget.deleteLabel),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red.withValues(alpha: 0.22),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: Colors.red.withValues(alpha: 0.32),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                  ),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    final v = _ctrl.text.trim();
                    if (v.isEmpty) return;
                    widget.onConfirm(v);
                    Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.30),
                      ),
                    ),
                  ),
                  child: const Text('确定'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MatrixHeaderRow extends StatelessWidget {
  const _MatrixHeaderRow({
    required this.emotions,
    required this.onTapEmotion,
  });

  final List<String> emotions;
  final ValueChanged<String> onTapEmotion;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _AxisTitleCard(
          width: _headerWidth,
          height: _headerHeight,
          title: '服装 \\ 表情',
          icon: Icons.grid_3x3_rounded,

        ),
        const SizedBox(width: 10),
        for (final emotion in emotions) ...[
          _AxisTitleCard(
            width: _axisColWidth,
            height: _headerHeight,
            title: emotion,
            icon: Icons.sentiment_satisfied_alt_outlined,
            onTap: () => onTapEmotion(emotion),
          ),
          const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _MatrixOutfitRow extends StatelessWidget {
  const _MatrixOutfitRow({
    required this.outfit,
    required this.emotions,
    required this.spriteCells,
    required this.roleRootPath,
    required this.onChanged,
    required this.onTapOutfit,
  });

  final String outfit;
  final List<String> emotions;
  final List<SpriteCell> spriteCells;
  final String? roleRootPath;
  final VoidCallback onChanged;
  final ValueChanged<String> onTapOutfit;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AxisTitleCard(
          width: _headerWidth,
          height: _rowHeight,
          title: outfit,
          icon: Icons.checkroom_outlined,
          isCorner: true,
          onTap: () => onTapOutfit(outfit),
        ),
        const SizedBox(width: 10),
        for (final emotion in emotions) ...[
          _SpriteCellCard(
            cell: _findCell(spriteCells, outfit, emotion),
            outfit: outfit,
            emotion: emotion,
            spriteCells: spriteCells,
            roleRootPath: roleRootPath,
            onChanged: onChanged,
          ),
          const SizedBox(width: 10),
        ],
      ],
    );
  }
}
//表头卡片，显示属性名称，点击可编辑属性或删除整行/列
class _AxisTitleCard extends StatelessWidget {
  const _AxisTitleCard({
    required this.width,
    required this.height,
    required this.title,
    required this.icon,
    this.isCorner = false,
    this.onTap,
  });

  final double width;
  final double height;
  final String title;
  final IconData icon;
  final bool isCorner;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: GameTheme.accentPink.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            spreadRadius: 1,
            color: GameTheme.accentPink.withValues(alpha: 0.18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
          if (onTap != null)
            Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.edit_outlined,
                size: 16,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 1, 12, 1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: isCorner ? 18 : 20,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GameTheme.h2(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

//矩阵单元格，显示差分预览，点击打开管理对话框
class _SpriteCellCard extends StatelessWidget {
  const _SpriteCellCard({
    required this.cell,
    required this.outfit,
    required this.emotion,
    required this.spriteCells,
    required this.roleRootPath,
    required this.onChanged,
  });

  final SpriteCell? cell;
  final String outfit;
  final String emotion;
  final List<SpriteCell> spriteCells;
  final String? roleRootPath;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final variants = cell?.variants ?? const <SpriteVariant>[];
    final preview = variants.isNotEmpty ? variants.first : null;
    final thumbPath = preview == null
        ? null
        : (preview.pickedPath ?? _abs(roleRootPath, preview.file));

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _openManager(context),
      child: Container(
        width: _cellWidth,
        height: _rowHeight,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.30)),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              color: GameTheme.accentPink.withValues(alpha: 0.30),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _SpriteThumbPreview(
                thumbPath: thumbPath,
                label: variants.isEmpty ? '空格' : '${variants.length}张差分',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$outfit / $emotion',
              style: GameTheme.h2(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              variants.isEmpty ? '点击添加差分' : '点击管理差分',
              style: GameTheme.tiny(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openManager(BuildContext context) async {
    final target = _getOrCreateCell(spriteCells, outfit, emotion);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return _SpriteCellManagerDialog(
          cell: target,
          spriteCells: spriteCells,
          roleRootPath: roleRootPath,
          onChanged: onChanged,
        );
      },
    );
  }
}

//差分预览，优先显示已选的文件，没有则显示占位文本
class _SpriteThumbPreview extends StatelessWidget {
  const _SpriteThumbPreview({
    required this.thumbPath,
    required this.label,
  });

  final String? thumbPath;
  final String label;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        thumbPath != null &&
        thumbPath!.trim().isNotEmpty &&
        File(thumbPath!).existsSync();

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.30)),
        color: Colors.white.withValues(alpha: 0.05),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: hasImage
            ? Align(
                alignment: Alignment.topCenter,
                child: Image.file(
                  File(thumbPath!),
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topCenter,
                ),
              )
            : Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.72),
                    fontSize: 12,
                  ),
                ),
              ),
      ),
    );
  }
}

class _SpriteCellManagerDialog extends StatefulWidget {
  const _SpriteCellManagerDialog({
    required this.cell,
    required this.spriteCells,
    required this.roleRootPath,
    required this.onChanged,
  });

  final SpriteCell cell;
  final List<SpriteCell> spriteCells;
  final String? roleRootPath;
  final VoidCallback onChanged;

  @override
  State<_SpriteCellManagerDialog> createState() => _SpriteCellManagerDialogState();
}

class _SpriteCellManagerDialogState extends State<_SpriteCellManagerDialog> {
  //实时取当前cell
  SpriteCell get _currentCell {
    final idx = widget.spriteCells.indexWhere(
      (c) => c.outfit == widget.cell.outfit && c.emotion == widget.cell.emotion,
    );
    if (idx < 0) return widget.cell;
    return widget.spriteCells[idx];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 720,
        constraints: const BoxConstraints(maxHeight: 720),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: GameTheme.accentPink.withValues(alpha: 0.9),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          boxShadow: [
            BoxShadow(
              blurRadius: 28,
              spreadRadius: 2,
              color: Colors.black.withValues(alpha: 0.36),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '立绘差分：${_currentCell.outfit} / ${_currentCell.emotion}',
                    style: GameTheme.h2(context),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  ..._currentCell.variants.map(
                    (variant) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _VariantRow(
                        cell: _currentCell,
                        spriteCells: widget.spriteCells,
                        variant: variant,
                        roleRootPath: widget.roleRootPath,
                        onChanged: widget.onChanged,
                        refreshDialog: () => setState(() {}),
                      ),
                    ),
                  ),
                  if (_currentCell.variants.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white.withValues(alpha: 0.06),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Text(
                        '当前单元格还没有差分，点击下方按钮添加。',
                        style: GameTheme.body(context),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  style: GameTheme.one2oneSoftButtonStyle(),
                  onPressed: () => _addSingleVariant(context),
                  icon: const Icon(Icons.add),
                  label: const Text('添加差分'),
                ),
                OutlinedButton.icon(
                  style: GameTheme.one2oneSoftButtonStyle(),
                  onPressed: () => _batchAddVariants(context),
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('批量添加'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  // 添加一个差分，编号自动 +1
  Future<void> _addSingleVariant(BuildContext context) async {
    final current = _currentCell;
    final nextNo = _nextVariantNo(current.variants);

    final list = List<SpriteVariant>.from(current.variants)
      ..add(
        SpriteVariant(
          variant: '$nextNo',
          note: '未绑定文件',
        ),
      );

    _replaceCell(current.copyWith(variants: list));
    widget.onChanged();
    setState(() {});
  }
  int _nextVariantNo(List<SpriteVariant> variants) {
    int maxNo = 0;
    for (final v in variants) {
      final n = int.tryParse(v.variant.trim());
      if (n != null && n > maxNo) maxNo = n;
    }
    return maxNo + 1;
  }

  // 批量添加差分，从文件名自动识别编号，避免重复
  Future<void> _batchAddVariants(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    final files = result?.files
            .map((e) => e.path)
            .whereType<String>()
            .toList() ??
        [];

    if (files.isEmpty) return;
    
    final current = _currentCell;
    final list = List<SpriteVariant>.from(current.variants);
    var nextNo = _nextVariantNo(list);

    for (final path in files) {
      final fileName = p.basename(path);
      list.add(
        SpriteVariant(
          variant: '${nextNo++}',
          pickedPath: path,
          note: '待保存：$fileName',
        ),
      );
    }
    _replaceCell(current.copyWith(variants: list));
    widget.onChanged();
    setState(() {});
  }

  void _replaceCell(SpriteCell next) {
    final idx = widget.spriteCells.indexWhere(
      (c) => c.outfit == widget.cell.outfit && c.emotion == widget.cell.emotion,
    );
    if (idx < 0) return;

    widget.spriteCells[idx] = next;
  }
}

class _VariantRow extends StatelessWidget {
  const _VariantRow({
    required this.cell,
    required this.spriteCells,
    required this.variant,
    required this.roleRootPath,
    required this.onChanged,
    required this.refreshDialog,
  });

  final SpriteCell cell;
  final List<SpriteCell> spriteCells;
  final SpriteVariant variant;
  final String? roleRootPath;
  final VoidCallback onChanged;
  final VoidCallback refreshDialog;

  @override
  Widget build(BuildContext context) {
    final thumbPath = variant.pickedPath ?? _abs(roleRootPath, variant.file);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 96,
            child: _SpriteThumbPreview(
              thumbPath: thumbPath,
              label: variant.variant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '差分 ${variant.variant}',
                  style: GameTheme.h2(context),
                ),
                const SizedBox(height: 4),
                Text(
                  variant.pickedPath != null
                      ? (variant.note ?? '待保存')
                      : (variant.file != null
                          ? '已绑定：${variant.file}'
                          : (variant.note ?? '未设置')),
                  style: GameTheme.tiny(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              IconButton(
                tooltip: '上传',
                onPressed: () async {
                  final r = await FilePicker.platform.pickFiles(
                    type: FileType.image,
                    allowMultiple: false,
                  );
                  final path = r?.files.single.path;
                  if (path == null) return;

                  final fileName = p.basename(path);
                  _updateVariant(
                    variant.copyWith(
                      pickedPath: path,
                      note: '待保存：$fileName',
                    ),
                  );
                  refreshDialog();
                },
                icon: const Icon(Icons.upload_rounded),
              ),
              IconButton(
                tooltip: '编辑编号',
                onPressed: () async {
                  final value = await one2oneInputDialog(
                    context,
                    title: '编辑差分编号',
                    initialValue: variant.variant,
                  );
                  if (value == null || value.trim().isEmpty) return;
                  _updateVariant(
                    variant.copyWith(
                      variant: value.trim(),
                    ),
                  );
                  refreshDialog();
                },
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: '删除',
                onPressed: () {
                  final list = List<SpriteVariant>.from(cell.variants)
                    ..remove(variant);
                  _replaceCell(cell.copyWith(variants: list));
                  onChanged();
                  refreshDialog();
                },
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateVariant(SpriteVariant next) {
    final list = List<SpriteVariant>.from(cell.variants);
    final idx = list.indexOf(variant);
    if (idx < 0) return;
    list[idx] = next;
    _replaceCell(cell.copyWith(variants: list));
    onChanged();
  }

  void _replaceCell(SpriteCell next) {
    final idx = spriteCells.indexWhere(
      (c) => c.outfit == cell.outfit && c.emotion == cell.emotion,
    );
    if (idx < 0) return;
    spriteCells[idx] = next;
  }
}

List<String> _collectOutfits(List<SpriteCell> cells) {
  final set = <String>{};
  for (final c in cells) {
    final v = c.outfit.trim();
    if (v.isNotEmpty) set.add(v);
  }
  final list = set.toList()..sort();
  return list;
}

List<String> _collectEmotions(List<SpriteCell> cells) {
  final set = <String>{};
  for (final c in cells) {
    final v = c.emotion.trim();
    if (v.isNotEmpty) set.add(v);
  }
  final list = set.toList()..sort();
  return list;
}

void _ensureMatrixComplete(List<SpriteCell> cells) {
  final outfits = _collectOutfits(cells);
  final emotions = _collectEmotions(cells);

  for (final outfit in outfits) {
    for (final emotion in emotions) {
      final exists = cells.any(
        (c) => c.outfit == outfit && c.emotion == emotion,
      );
      if (!exists) {
        cells.add(
          SpriteCell(
            outfit: outfit,
            emotion: emotion,
            variants: const [],
          ),
        );
      }
    }
  }
}

SpriteCell? _findCell(List<SpriteCell> cells, String outfit, String emotion) {
  for (final c in cells) {
    if (c.outfit == outfit && c.emotion == emotion) {
      return c;
    }
  }
  return null;
}

SpriteCell _getOrCreateCell(
  List<SpriteCell> cells,
  String outfit,
  String emotion,
) {
  final found = _findCell(cells, outfit, emotion);
  if (found != null) return found;

  final created = SpriteCell(
    outfit: outfit,
    emotion: emotion,
    variants: const [],
  );
  cells.add(created);
  return created;
}

String? _abs(String? root, String? rel) {
  if (root == null || rel == null || rel.trim().isEmpty) return null;
  return p.join(root, rel);
}
