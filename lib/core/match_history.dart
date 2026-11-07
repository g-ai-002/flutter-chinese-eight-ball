import 'dart:convert';

import 'match_record.dart';

/// 对局记录的本地编码：按时间倒序排列，只保留最近 [maxRecords] 场。
class MatchHistory {
  MatchHistory._();

  static const int maxRecords = 10;

  /// 统一排序与裁剪，读写两侧共用同一规则。
  static List<MatchRecord> normalize(Iterable<MatchRecord> records) {
    final sorted = [...records]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(sorted.take(maxRecords));
  }

  /// 解析失败、结构损坏或没有有效杆次的记录整条丢弃。
  static List<MatchRecord> decode(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    Object? parsed;
    try {
      parsed = jsonDecode(raw);
    } catch (_) {
      return const [];
    }
    if (parsed is! List) return const [];
    final records = <MatchRecord>[];
    for (final item in parsed) {
      final record = MatchRecord.fromJson(item);
      if (record != null) records.add(record);
    }
    return normalize(records);
  }

  static String encode(Iterable<MatchRecord> records) =>
      jsonEncode([for (final record in normalize(records)) record.toJson()]);
}
