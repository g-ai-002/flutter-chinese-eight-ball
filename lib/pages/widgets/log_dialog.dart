import 'package:flutter/material.dart';

import '../../services/file_system_service.dart';
import '../../services/log_service.dart';

/// 展示最近日志与落盘目录；Web 端只保留内存日志。
Future<void> showLogDialog(BuildContext context) async {
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
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(dialogContext)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
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
