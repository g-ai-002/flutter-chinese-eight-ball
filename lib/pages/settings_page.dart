import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/ai.dart';
import '../providers/settings_provider.dart';
import '../services/file_system_service.dart';
import '../services/log_service.dart';
import '../theme/table_skin.dart';
import '../utils/constants.dart';
import 'help_page.dart';
import 'widgets/ai_strength_row.dart';
import 'widgets/section_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                SectionCard(
                  title: '对局',
                  children: [
                    _ChipRow<AiDifficulty>(
                      label: 'AI 难度',
                      values: AiDifficulty.values,
                      selected: settings.difficulty,
                      labelOf: (value) => value.label,
                      onSelected: settings.setDifficulty,
                    ),
                    if (settings.difficulty == AiDifficulty.custom)
                      AiStrengthRow(
                        value: settings.aiStrength,
                        onChanged: settings.setAiStrength,
                      ),
                    _ChipRow<int>(
                      label: '开球先后',
                      values: const [0, 1],
                      selected: settings.humanSide,
                      labelOf: (value) => value == 0 ? '先手开球' : '后手开球',
                      onSelected: settings.setHumanSide,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
                const SizedBox(height: 14),
                SectionCard(
                  title: '显示',
                  children: [
                    _SwitchRow(
                      title: '深色模式',
                      subtitle: '夜间或暗光环境下使用深色界面',
                      value: settings.darkMode,
                      onChanged: settings.setDarkMode,
                    ),
                    _SwitchRow(
                      title: '瞄准辅助线',
                      subtitle: '显示母球撞击点与目标球去向',
                      value: settings.showAimGuide,
                      onChanged: settings.setShowAimGuide,
                    ),
                    _SkinRow(
                      selected: settings.tableSkin,
                      onSelected: settings.setTableSkin,
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
                const SizedBox(height: 14),
                SectionCard(
                  title: '声音与反馈',
                  children: [
                    _SwitchRow(
                      title: '音效',
                      subtitle: '出杆、撞击、落袋与终局提示音',
                      value: settings.soundEnabled,
                      onChanged: settings.setSoundEnabled,
                    ),
                    _SwitchRow(
                      title: '背景音乐',
                      subtitle: '运行时合成的舒缓五声音阶循环',
                      value: settings.musicEnabled,
                      onChanged: settings.setMusicEnabled,
                    ),
                    _SwitchRow(
                      title: '震动反馈',
                      subtitle: '落袋与犯规时的触感提示',
                      value: settings.hapticsEnabled,
                      onChanged: settings.setHapticsEnabled,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SectionCard(
                  title: '关于',
                  children: [
                    _LinkRow(
                      title: '玩法规则',
                      subtitle: '中式黑八规则与操作说明',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const HelpPage(),
                        ),
                      ),
                    ),
                    _LinkRow(
                      title: '运行日志',
                      subtitle: '查看最近的运行日志与存放位置',
                      onTap: () => _showLogs(context),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      child: Row(
                        children: [
                          Text(
                            '${AppConstants.appName} v${AppConstants.version}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '本地运行 · 无需联网',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showLogs(BuildContext context) async {
    final path = await FileSystemService.instance.getLogRootPath();
    if (!context.mounted) return;
    final lines = LogService.getRecentLogs(240);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('运行日志'),
        content: SizedBox(
          width: 520,
          height: 380,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                path.isEmpty ? 'Web 端日志仅保存在内存中' : '目录：$path',
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(dialogContext)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(8),
                    child: SelectableText(
                      lines.isEmpty ? '暂无日志' : lines.join('\n'),
                      style: const TextStyle(fontSize: 11, height: 1.4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title, style: theme.textTheme.bodyMedium),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      dense: true,
    );
  }
}

class _ChipRow<T> extends StatelessWidget {
  const _ChipRow({
    required this.label,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final String label;
  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final value in values)
                ChoiceChip(
                  label: Text(labelOf(value)),
                  selected: value == selected,
                  onSelected: (_) => onSelected(value),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkinRow extends StatelessWidget {
  const _SkinRow({required this.selected, required this.onSelected});

  final TableSkin selected;
  final ValueChanged<TableSkin> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('球台配色', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final skin in kTableSkins)
                ChoiceChip(
                  avatar: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: skin.cloth,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: skin.diamond.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  label: Text(skin.name),
                  selected: skin.id == selected.id,
                  onSelected: (_) => onSelected(skin),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      dense: true,
      title: Text(title, style: theme.textTheme.bodyMedium),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
    );
  }
}
