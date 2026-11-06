import 'package:flutter/material.dart';

import '../core/match_stats.dart';
import '../services/match_history_service.dart';
import 'widgets/section_card.dart';

/// 数据统计：聚合本机最近对局，展示胜率、杆数、进球与难度表现。
class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  /// 为 null 表示仍在读取本机记录。
  MatchStats? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await MatchHistoryService.instance.load();
    if (!mounted) return;
    setState(() => _stats = MatchStats.fromRecords(records));
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    return Scaffold(
      appBar: AppBar(title: const Text('数据统计')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: stats == null
                ? const Center(child: CircularProgressIndicator())
                : stats.isEmpty
                ? const _EmptyStats()
                : _StatsBody(stats: stats),
          ),
        ),
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.stats});

  final MatchStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        SectionCard(
          title: '总览',
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
              child: _SummaryGrid(stats: stats),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: '人机难度',
          children: [
            if (stats.difficulties.isEmpty)
              const _SectionHint('还没有人机对局')
            else
              for (final difficulty in stats.difficulties)
                _DifficultyRow(difficulty: difficulty),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: '最近战绩',
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              child: stats.recentAiResults.isEmpty
                  ? const _SectionHint('完成人机对战后显示最近 5 场胜负')
                  : Row(
                      children: [
                        for (final win in stats.recentAiResults) ...[
                          _ResultChip(win: win),
                          const SizedBox(width: 8),
                        ],
                        const Spacer(),
                        Text(
                          '${stats.aiWins} 胜 ${stats.aiLosses} 负',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          '数据来自本机保存的最近对局，仅保存在本设备。',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.stats});

  final MatchStats stats;

  @override
  Widget build(BuildContext context) {
    final items = <({String label, String value})>[
      (label: '总场次', value: '${stats.matches}'),
      (
        label: '人机胜率',
        value: stats.aiMatches == 0
            ? '—'
            : '${(stats.aiWinRate * 100).round()}%',
      ),
      (label: '双人场次', value: '${stats.twoPlayerMatches}'),
      (label: '场均杆数', value: stats.averageShots.toStringAsFixed(1)),
      (label: '累计进球', value: '${stats.potted}'),
      (label: '进球率', value: '${(stats.potRate * 100).round()}%'),
      (label: '单杆最多', value: '${stats.bestShotPotted} 球'),
      (label: '连续进球', value: '${stats.bestStreak} 杆'),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 4 : 2;
        const spacing = 10.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _StatTile(label: item.label, value: item.value),
              ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyRow extends StatelessWidget {
  const _DifficultyRow({required this.difficulty});

  final DifficultyStats difficulty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final rate = difficulty.winRate;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(difficulty.label, style: theme.textTheme.bodyMedium),
              const Spacer(),
              Text(
                '${difficulty.wins} / ${difficulty.matches} 胜 · '
                '${(rate * 100).round()}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 5,
              backgroundColor: colors.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultChip extends StatelessWidget {
  const _ResultChip({required this.win});

  final bool win;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: win
            ? colors.primary.withValues(alpha: 0.16)
            : colors.error.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(
          color: win
              ? colors.primary.withValues(alpha: 0.4)
              : colors.error.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        win ? '胜' : '负',
        style: theme.textTheme.labelSmall?.copyWith(
          color: win ? colors.primary : colors.error,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionHint extends StatelessWidget {
  const _SectionHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _EmptyStats extends StatelessWidget {
  const _EmptyStats();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.query_stats_outlined,
              size: 46,
              color: colors.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 14),
            Text('还没有可统计的对局', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              '完成一局人机或双人对战后，这里会展示胜率、杆数与进球表现。',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
