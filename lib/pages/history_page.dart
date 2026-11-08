import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/match_history.dart';
import '../core/match_record.dart';
import '../core/stats_report.dart';
import '../services/match_history_service.dart';
import 'replay_page.dart';
import 'stats_page.dart';
import 'widgets/floating_message.dart';
import 'widgets/empty_state.dart';
import 'widgets/history_card.dart';

/// 最近对局：展示本机保存的对局结果，点击进入逐杆回放。
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  /// 为 null 表示仍在读取本机记录。
  List<MatchRecord>? _records;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await MatchHistoryService.instance.load();
    if (!mounted) return;
    setState(() => _records = records);
  }

  Future<void> _remove(MatchRecord record) async {
    final records = await MatchHistoryService.instance.remove(record.id);
    if (!mounted) return;
    setState(() => _records = records);
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('清空对局记录？'),
        content: const Text('已保存的对局与回放将全部删除，且无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await MatchHistoryService.instance.clear();
    if (!mounted) return;
    setState(() => _records = const []);
  }

  void _openReplay(MatchRecord record) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ReplayPage(record: record)));
  }

  void _openStats() {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const StatsPage()));
  }

  Future<void> _export(List<MatchRecord> records) async {
    await Clipboard.setData(ClipboardData(text: buildMatchReport(records)));
    if (!mounted) return;
    showFloatingMessage(context, '对局数据已复制到剪贴板');
  }

  @override
  Widget build(BuildContext context) {
    final records = _records;
    return Scaffold(
      appBar: AppBar(
        title: const Text('最近对局'),
        actions: [
          IconButton(
            tooltip: '数据统计',
            onPressed: _openStats,
            icon: const Icon(Icons.query_stats_outlined, size: 22),
          ),
          if (records != null && records.isNotEmpty)
            IconButton(
              tooltip: '导出数据',
              onPressed: () => _export(records),
              icon: const Icon(Icons.ios_share, size: 22),
            ),
          if (records != null && records.isNotEmpty)
            IconButton(
              tooltip: '清空记录',
              onPressed: _clearAll,
              icon: const Icon(Icons.delete_sweep_outlined, size: 22),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: _buildBody(records),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<MatchRecord>? records) {
    if (records == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (records.isEmpty) {
      return const EmptyState(
        icon: Icons.movie_filter_outlined,
        title: '还没有对局记录',
        subtitle: '完成一局人机或双人对战后，会自动保存逐杆回放。',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: records.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == records.length) return const _HistoryFooter();
        final record = records[index];
        return HistoryCard(
          record: record,
          onTap: () => _openReplay(record),
          onDelete: () => _remove(record),
        );
      },
    );
  }
}

class _HistoryFooter extends StatelessWidget {
  const _HistoryFooter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        '最多保留最近 ${MatchHistory.maxRecords} 场对局，记录只保存在本机。',
        textAlign: TextAlign.center,
        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}
