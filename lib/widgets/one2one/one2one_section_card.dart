import 'package:flutter/material.dart';
import '../home/game_theme.dart';

//通用的“分区卡片” UI
class One2OneSectionCard extends StatelessWidget {
  const One2OneSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GameTheme.blur(
      radius: 22,
      sigma: 14,
      child: Container(
        decoration: GameTheme.card(radius: 22, opacity: 0.60),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: GameTheme.h2(context)),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
