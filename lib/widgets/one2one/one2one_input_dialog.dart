import 'package:flutter/material.dart';
import '../home/game_theme.dart';

// 通用输入对话框：单行文本
Future<String?> one2oneInputDialog(
  BuildContext context, {
  required String title,
  String? initialValue,
  String? hintText,
}) async {
  final ctrl = TextEditingController(text: initialValue ?? '');
  return showDialog<String>(
    
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        cursorColor: GameTheme.accentPink, // 光标颜色
        decoration: InputDecoration(
          hintText: hintText,
          //变浅一点
          hintStyle: TextStyle(
            color: Colors.black.withValues(alpha: 0.4), // 浅灰
            fontSize: 14,
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha:0.65),

          // 默认边框
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: GameTheme.accentPink.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),

          // 聚焦时边框
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: GameTheme.accentPink,
              width: 2,
            ),
          ),

          // 兜底
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      actions: [
        TextButton(
          style: GameTheme.one2oneTextButtonStyle(),
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('取消'),
        ),
        GameTheme.one2oneGradientButton(
          onPressed: () => Navigator.of(context).pop(ctrl.text),
          child: const Text('确定'),
        ),
      ],
    ),
  );
}


// 场景变体输入对话框：地点-时间（格式化）
Future<String?> one2oneBgVariantDialog(
  BuildContext context, {
  required String title,
  required String defaultPlace, // 默认地点=分类名
  String? initialValue,         // 用于编辑时回填 "教室-白天"
}) async {
  String place = defaultPlace;
  String time = '';

  if (initialValue != null && initialValue.contains('-')) {
    final idx = initialValue.lastIndexOf('-');
    place = initialValue.substring(0, idx);
    time = initialValue.substring(idx + 1);
  } else if (initialValue != null && initialValue.isNotEmpty) {
    // 没有 '-' 的情况就当做 time
    time = initialValue;
  }

  final placeCtrl = TextEditingController(text: place);
  final timeCtrl = TextEditingController(text: time);

  InputDecoration deco(String hint) => InputDecoration(
        hintText: hint,
        //变浅一点
        hintStyle: TextStyle(
          color: Colors.black.withValues(alpha: 0.4), // 浅灰
          fontSize: 14,
        ),

        filled: true,
        fillColor: Colors.white.withValues(alpha:0.65),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: GameTheme.accentPink.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: GameTheme.accentPink,
            width: 2,
          ),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      );

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: placeCtrl,
            autofocus: true,
            cursorColor: GameTheme.accentPink,
            decoration: deco('地点（默认为分类名）'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: timeCtrl,
            cursorColor: GameTheme.accentPink,
            decoration: deco('时间（例如：白天 / 黄昏 / 晚上 / 雨天）'),
          ),
        ],
      ),
      actions: [
        TextButton(
          style: GameTheme.one2oneTextButtonStyle(),
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('取消'),
        ),
        GameTheme.one2oneGradientButton(
          onPressed: () {
            final p = placeCtrl.text.trim();
            final t = timeCtrl.text.trim();
            if (p.isEmpty || t.isEmpty) {
              Navigator.of(context).pop(null);
              return;
            }
            Navigator.of(context).pop('$p-$t'); // ✅ 返回最终 title
          },
          child: const Text('确定'),
        ),
      ],
    ),
  );
}
