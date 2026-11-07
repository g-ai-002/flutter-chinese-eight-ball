import '../utils/formatters.dart';
import 'match_record.dart';
import 'match_stats.dart';

/// 把本机对局与统计汇总为可复制的纯文本报告，不写文件、不上传。
String buildMatchReport(Iterable<MatchRecord> records, {DateTime? now}) {
  final all = [...records]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final stats = MatchStats.fromRecords(all, now: now);
  final lines = <String>[
    '中式黑八 · 对局数据',
    '导出时间：${formatDateTime(now ?? DateTime.now())}',
    '对局 ${stats.matches} 场 · 人机 ${stats.aiMatches} 场 · '
        '人机胜率 ${formatPercent(stats.aiWinRate)}',
    '总杆数 ${stats.shots} · 进球 ${stats.potted} · '
        '进球率 ${formatPercent(stats.potRate)}',
    '单杆最多 ${stats.bestShotPotted} 球 · 最长连续进球 ${stats.bestStreak} 杆',
    '',
    '最近对局（新 → 旧）',
    if (all.isEmpty) '暂无对局记录',
    for (final record in all.take(10))
      '${formatDateTime(record.createdAt)} · ${record.modeLabel}'
          '${record.isVersusAi ? ' · ${record.difficultyLabel}' : ''} · '
          '${record.title} · ${record.shotCount} 杆 · '
          '${record.pottedTargets} 球 · ${record.endReason}',
  ];
  return lines.join('\n');
}
