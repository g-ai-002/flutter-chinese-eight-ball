import 'package:flutter/material.dart';

import '../core/match_stats.dart';
import '../services/match_history_service.dart';
import 'widgets/section_card.dart';
import 'widgets/stats_daily.dart';
import 'widgets/stats_difficulty_list.dart';
import 'widgets/stats_empty.dart';
import 'widgets/stats_recent_form.dart';
import 'widgets/stats_summary_grid.dart';
import 'widgets/stats_trend.dart';

/// 数据统计：聚合本机最近对局，展示胜率、杆数、进球与难度表现。
class StatsPage extends StatefulWidget {
  const StatsPage({super.key, this.now});

  /// 统计「近 7 天」的基准时间，为空时取当前时间；测试可注入固定时间。
  final DateTime? now;

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
    setState(() => _stats = MatchStats.fromRecords(records, now: widget.now));
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
                ? const StatsEmpty()
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
    Widget card(String title, Widget child) => SectionCard(title: title, children: [child]);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        card(
          '总览',
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: StatsSummaryGrid(stats: stats),
          ),
        ),
        const SizedBox(height: 12),
        card('近期走势', StatsTrend(trend: stats.trend)),
        const SizedBox(height: 12),
        card('近 7 天', StatsDaily(trend: stats.daily)),
        const SizedBox(height: 12),
        card('人机难度', StatsDifficultyList(difficulties: stats.difficulties)),
        const SizedBox(height: 12),
        card(
          '最近战绩',
          StatsRecentForm(
            results: stats.recentAiResults,
            wins: stats.aiWins,
            losses: stats.aiLosses,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          '数据来自本机保存的最近对局，仅保存在本设备。',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
