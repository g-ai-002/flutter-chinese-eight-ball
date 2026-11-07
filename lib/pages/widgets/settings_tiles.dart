import 'package:flutter/material.dart';

import '../../theme/table_skin.dart';

/// 设置项统一的次要说明文字。
Text _settingsSubtitle(BuildContext context, String text) => Text(
  text,
  style: Theme.of(context).textTheme.bodySmall
      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
);

/// 设置页的开关行。
class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
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
      subtitle: _settingsSubtitle(context, subtitle),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      dense: true,
    );
  }
}

/// 设置页的单选分组，例如 AI 难度与开球先后。
class SettingsChipTile<T> extends StatelessWidget {
  const SettingsChipTile({
    super.key,
    required this.label,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.avatarOf,
    this.hint,
  });

  final String label;
  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onSelected;
  final Widget Function(T value)? avatarOf;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          if (hint != null) ...[
            const SizedBox(height: 2),
            _settingsSubtitle(context, hint!),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final value in values)
                ChoiceChip(
                  avatar: avatarOf?.call(value),
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

/// 球台配色单选，色点与台呢颜色保持一致。
Widget settingsSkinTile({
  required TableSkin selected,
  required ValueChanged<TableSkin> onSelected,
}) => SettingsChipTile<TableSkin>(
  label: '球台配色',
  values: kTableSkins,
  selected: selected,
  labelOf: (skin) => skin.name,
  avatarOf: _skinAvatar,
  onSelected: onSelected,
);

Widget _skinAvatar(TableSkin skin) => Container(
  width: 14,
  height: 14,
  decoration: BoxDecoration(
    color: skin.cloth,
    shape: BoxShape.circle,
    border: Border.all(color: skin.diamond.withValues(alpha: 0.7)),
  ),
);

/// 点击后进入下一页或打开对话框的设置行。
class SettingsLinkTile extends StatelessWidget {
  const SettingsLinkTile({
    super.key,
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
      subtitle: _settingsSubtitle(context, subtitle),
      trailing: const Icon(Icons.chevron_right, size: 20),
    );
  }
}
