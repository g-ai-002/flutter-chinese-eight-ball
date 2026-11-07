import 'package:flutter/material.dart';

/// 统计分区内的浅色提示文案，用于空数据占位。
class StatsSectionHint extends StatelessWidget {
  const StatsSectionHint(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}
