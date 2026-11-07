import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/ai.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import 'help_page.dart';
import 'widgets/ai_preset_section.dart';
import 'widgets/ai_strength_row.dart';
import 'widgets/log_dialog.dart';
import 'widgets/section_card.dart';
import 'widgets/settings_tiles.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final sections = <(String, List<Widget>)>[
      (
        '对局',
        [
          SettingsChipTile<AiDifficulty>(
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
          AiPresetSection(settings: settings),
          SettingsChipTile<int>(
            label: '开球先后',
            values: const [0, 1],
            selected: settings.humanSide,
            labelOf: (value) => value == 0 ? '先手开球' : '后手开球',
            onSelected: settings.setHumanSide,
          ),
          const SizedBox(height: 8),
        ],
      ),
      (
        '显示',
        [
          SettingsSwitchTile(
            title: '深色模式',
            subtitle: '夜间或暗光环境下使用深色界面',
            value: settings.darkMode,
            onChanged: settings.setDarkMode,
          ),
          SettingsSwitchTile(
            title: '瞄准辅助线',
            subtitle: '显示母球撞击点与目标球去向',
            value: settings.showAimGuide,
            onChanged: settings.setShowAimGuide,
          ),
          settingsSkinTile(
            selected: settings.tableSkin,
            onSelected: settings.setTableSkin,
          ),
          const SizedBox(height: 10),
        ],
      ),
      (
        '声音与反馈',
        [
          SettingsSwitchTile(
            title: '音效',
            subtitle: '出杆、撞击、落袋与终局提示音',
            value: settings.soundEnabled,
            onChanged: settings.setSoundEnabled,
          ),
          SettingsSwitchTile(
            title: '背景音乐',
            subtitle: '运行时合成的舒缓五声音阶循环',
            value: settings.musicEnabled,
            onChanged: settings.setMusicEnabled,
          ),
          SettingsSwitchTile(
            title: '震动反馈',
            subtitle: '落袋与犯规时的触感提示',
            value: settings.hapticsEnabled,
            onChanged: settings.setHapticsEnabled,
          ),
        ],
      ),
      (
        '关于',
        [
          SettingsLinkTile(
            title: '玩法规则',
            subtitle: '中式黑八规则与操作说明',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const HelpPage())),
          ),
          SettingsLinkTile(
            title: '运行日志',
            subtitle: '查看最近的运行日志与存放位置',
            onTap: () => showLogDialog(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Text(
              '${AppConstants.appName} v${AppConstants.version} · 本地运行 · 无需联网',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                for (final (title, children) in sections) ...[
                  SectionCard(title: title, children: children),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
