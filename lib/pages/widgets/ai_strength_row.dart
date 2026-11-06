import 'package:flutter/material.dart';

import '../../core/ai.dart';

/// 设置页的自定义 AI 强度滑杆：实时展示插值后的瞄准误差与候选线路。
class AiStrengthRow extends StatelessWidget {
  const AiStrengthRow({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tuning = AiTuning.custom(value);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('AI 强度', style: theme.textTheme.bodyMedium),
              const Spacer(),
              Text(
                tuning.accuracyLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            onChanged: onChanged,
            divisions: 20,
            label: '${(value * 100).round()}%',
          ),
        ],
      ),
    );
  }
}
