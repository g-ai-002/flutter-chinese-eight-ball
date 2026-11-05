import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// 对局结束弹窗：展示胜负、终局原因与杆数。
class GameOverDialog extends StatelessWidget {
  const GameOverDialog({
    super.key,
    required this.title,
    required this.playerWin,
    required this.reason,
    required this.shots,
    required this.onHome,
    required this.onRestart,
    this.onReplay,
  });

  final String title;
  final bool playerWin;
  final String reason;
  final int shots;
  final VoidCallback onHome;
  final VoidCallback onRestart;

  /// 有逐杆记录时提供回放入口，练习模式为 null。
  final VoidCallback? onReplay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      icon: Icon(
        playerWin ? Icons.emoji_events_outlined : Icons.sports_bar_outlined,
        color: playerWin ? appGold : theme.colorScheme.primary,
        size: 30,
      ),
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            reason,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          Text(
            '共 $shots 杆',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: onHome, child: const Text('返回首页')),
        if (onReplay != null)
          OutlinedButton.icon(
            onPressed: onReplay,
            icon: const Icon(Icons.movie_filter_outlined, size: 18),
            label: const Text('查看回放'),
          ),
        FilledButton(onPressed: onRestart, child: const Text('再来一局')),
      ],
    );
  }
}
