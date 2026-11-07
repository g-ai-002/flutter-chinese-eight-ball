import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ai_preset.dart';
import '../../providers/settings_provider.dart';
import 'floating_message.dart';
import 'settings_tiles.dart';

/// 设置页的 AI 配置码入口：复制当前设置，或粘贴配置码恢复。
class AiPresetSection extends StatelessWidget {
  const AiPresetSection({super.key, required this.settings});

  final SettingsProvider settings;

  Future<void> _share(BuildContext context) async {
    final code = AiPresetCode.encode(settings.difficulty, settings.aiStrength);
    await Clipboard.setData(ClipboardData(text: code));
    if (context.mounted) showFloatingMessage(context, '已复制配置码 $code');
  }

  Future<void> _import(BuildContext context) async {
    final preset = await showDialog<AiPreset>(
      context: context,
      builder: (_) => const _PresetImportDialog(),
    );
    if (preset == null) return;
    await settings.setDifficulty(preset.difficulty);
    await settings.setAiStrength(preset.strength);
    if (!context.mounted) return;
    showFloatingMessage(context, '已导入 ${preset.difficulty.label} 配置');
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SettingsLinkTile(
        title: 'AI 配置码',
        subtitle: '复制当前难度与强度，粘贴到另一台设备',
        onTap: () => _share(context),
      ),
      SettingsLinkTile(
        title: '导入 AI 配置',
        subtitle: '输入或粘贴配置码恢复 AI 设置',
        onTap: () => _import(context),
      ),
    ],
  );
}

class _PresetImportDialog extends StatefulWidget {
  const _PresetImportDialog();

  @override
  State<_PresetImportDialog> createState() => _PresetImportDialogState();
}

class _PresetImportDialogState extends State<_PresetImportDialog> {
  final TextEditingController _input = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _submit() {
    final value = AiPresetCode.decode(_input.text);
    if (value == null) {
      setState(() => _error = '配置码无效，请检查后重试');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('导入 AI 配置'),
      content: TextField(
        controller: _input,
        autofocus: true,
        decoration: InputDecoration(
          labelText: '配置码',
          hintText: '${AiPresetCode.prefix}-进阶-620',
          errorText: _error,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('取消')),
        FilledButton(onPressed: _submit, child: const Text('导入')),
      ],
    );
  }
}
