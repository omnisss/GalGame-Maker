import 'package:flutter/material.dart';
import 'package:galgame/widgets/home/game_theme.dart';

class PhoneHelpPage extends StatelessWidget {
  const PhoneHelpPage();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: SingleChildScrollView(
        child: Text(
          "【说明】\n\n"
          "1. 手机聊天模式：以“分类->好友->聊天”的方式工作。\n"
          "2. 目前分类有三种：\n"
          "       1.故事模式中的角色\n"
          "       2.一对一模式中的角色\n"
          "       3.自定义分类的角色\n"
          "3. 该模式是一种模拟线上聊天的方式进行的，所以除去自定义分类的角色，记忆将与故事模式或一对一模式中的对应角色共享\n",
          style: TextStyle(
            height: 1.6,
            color: Colors.black.withValues(alpha: 0.85),
            fontWeight: FontWeight.w600,
            fontSize: GameTheme.fontH(context, 0.01, min: 20, max: 50),
          ),
        ),
      ),
    );
  }
}
