import 'package:flutter/material.dart';

/// 首页入口卡片：图标、标题、说明与箭头。
class EntryTile extends StatelessWidget {
  const EntryTile({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.outline.withValues(alpha: 0.8)),
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// 入口卡片左侧的圆角图标。
class EntryBadge extends StatelessWidget {
  const EntryBadge({super.key, required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Icon(icon, size: 21, color: accent),
    );
  }
}
