import 'package:flutter/material.dart';

/// 统计页柱状图的一根柱子：柱高比例、可选的顶部圆点与上下标注。
class StatsBar {
  const StatsBar({
    required this.heightFactor,
    required this.bottomLabel,
    this.topLabel,
    this.marker,
    this.muted = false,
  });

  final double heightFactor;
  final String bottomLabel;
  final String? topLabel;

  /// 柱子顶部的圆点颜色，为空时不绘制圆点。
  final Color? marker;

  /// 无数据的日期使用浅灰柱，与有效数据区分。
  final bool muted;
}

/// 统计页共用柱状图：走势与近 7 天趋势共享柱宽、圆角、最小高度与标注样式。
class StatsBars extends StatelessWidget {
  const StatsBars({
    super.key,
    required this.bars,
    this.height = 96,
    this.minFactor = 0.06,
  });

  final List<StatsBar> bars;
  final double height;
  final double minFactor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final labelStyle = theme.textTheme.labelSmall;
    Widget label(String text, double size, Color color) => Text(
      text,
      style: labelStyle?.copyWith(fontSize: size, color: color),
    );
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final bar in bars)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (bar.marker != null) ...[
                    Icon(Icons.circle, size: 6, color: bar.marker),
                    const SizedBox(height: 4),
                  ],
                  Expanded(
                    child: FractionallySizedBox(
                      alignment: Alignment.bottomCenter,
                      heightFactor: bar.heightFactor
                          .clamp(minFactor, 1)
                          .toDouble(),
                      widthFactor: 0.5,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: bar.muted
                              ? colors.outlineVariant.withValues(alpha: 0.4)
                              : colors.primary.withValues(alpha: 0.35),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (bar.topLabel != null) ...[
                    const SizedBox(height: 4),
                    label(bar.topLabel!, 8.5, colors.onSurfaceVariant),
                  ],
                  const SizedBox(height: 4),
                  label(bar.bottomLabel, 8, colors.outline),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
