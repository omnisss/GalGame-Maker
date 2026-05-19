import 'package:flutter/material.dart';
import '../home/game_theme.dart';
import 'one2one_section_card.dart';
import 'one2one_persona_store.dart';

class One2OnePersonaPanel extends StatelessWidget {
  const One2OnePersonaPanel({
    super.key,
    required this.roleId,
    required this.nameCtrl,
    required this.personaCtrl,
  });

  final String roleId;

  final TextEditingController nameCtrl;
  final TextEditingController personaCtrl;


  InputDecoration _dec(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white.withOpacity(0.65),
      hintStyle: TextStyle(
        color: GameTheme.accentPink.withOpacity(0.45),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: GameTheme.accentPink.withOpacity(0.35),
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: GameTheme.accentPink,
          width: 2,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      labelStyle: TextStyle(
        color: GameTheme.accentPink.withOpacity(0.9),
      ),
      floatingLabelStyle: const TextStyle(
        color: GameTheme.accentPink,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Future<void> _saveLocal(BuildContext context) async {
    try {
      await One2OnePersonaStore.savePersona(
        roleId,
        name: nameCtrl.text.trim(),
        persona: personaCtrl.text.trim(),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('人设已保存到本地')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('本地保存失败：$e')),
      );
    }
  }

  Future<void> _loadLocal(BuildContext context) async {
    try {
      final data = await One2OnePersonaStore.loadPersona(roleId);
      if (data == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('本地没有找到人设文件')),
        );
        return;
      }
      nameCtrl.text = (data['name'] ?? '') as String;
      personaCtrl.text = (data['persona'] ?? '') as String;

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已从本地读取人设')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('本地读取失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        One2OneSectionCard(
          title: '基础信息',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              /*GameTheme.one2oneGradientButton(
                onPressed: () => _loadLocal(context),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download_outlined, size: 18),
                    SizedBox(width: 6),
                    Text('读取'),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GameTheme.one2oneGradientButton(
                onPressed: () => _saveLocal(context),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.save_outlined, size: 18),
                    SizedBox(width: 6),
                    Text('本地保存'),
                  ],
                ),
              ),*/
            ],
          ),
          child: Column(
            children: [
              TextField(
                controller: nameCtrl,
                cursorColor: GameTheme.accentPink,
                decoration: _dec('角色名', hint: '例如：因幡巡'),
              ),
              const SizedBox(height: 12),
              /*TextField(
                controller: filenameCtrl,
                cursorColor: GameTheme.accentPink,
                decoration: _dec('文件名', hint: '请用英文或者拼音，不要用中文字符。用于保存。'),
              ),
              const SizedBox(height: 12),*/
            ],
          ),
        ),
        const SizedBox(height: 12),

        One2OneSectionCard(
          title: '人设（核心）',
          trailing: GameTheme.one2oneGradientButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('占位：AI润色/模板')),
              );
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_outlined, size: 18),
                SizedBox(width: 6),
                Text('AI润色'),
              ],
            ),
          ),
          child: TextField(
            controller: personaCtrl,
            cursorColor: GameTheme.accentPink,
            decoration: _dec('人设设定', hint: '性格、背景、关系、说话风格、喜欢/讨厌…'),
            minLines: 10,
            maxLines: 18,
          ),
        ),


        const SizedBox(height: 12),
        Text(
          '提示：后续接入后端时，这些内容会作为 One2One 的独立记忆/设定，不与故事模式互通。',
          style: GameTheme.tiny(context),
        ),
      ],
    );
  }
}

//设置页面（占位）
class One2OnePersonaSettingsPanel extends StatelessWidget {
  const One2OnePersonaSettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        One2OneSectionCard(
          title: '推理设置（占位）',
          child: Column(
            children: [
              _kvRow(context, 'Temperature', '0.7'),
              const SizedBox(height: 10),
              _kvRow(context, 'Max Tokens', '512'),
              const SizedBox(height: 10),
              _kvRow(context, 'Top P', '0.9'),
              const SizedBox(height: 10),
              _kvRow(context, '自定义 Key', '未设置'),
              const SizedBox(height: 10),
              Text(
                '这里后续可以接入：模型选择、采样参数、系统提示词、工具开关等。',
                style: GameTheme.tiny(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kvRow(BuildContext context, String k, String v) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(k, style: GameTheme.h2(context))),
          Text(v, style: GameTheme.tiny(context)),
        ],
      ),
    );
  }
}
