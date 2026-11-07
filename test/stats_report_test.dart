import 'package:chinese_eight_ball/core/stats_report.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/record_factory.dart';

void main() {
  test('报告汇总统计并按时间从新到旧列出对局', () {
    final report = buildMatchReport([
      testRecord(
        index: 1,
        shots: const [
          (0, [1, 2]),
        ],
      ),
      testRecord(
        index: 2,
        win: false,
        difficulty: '高手',
        shots: const [
          (0, [9]),
        ],
      ),
    ], now: DateTime(2026, 11, 7, 12));

    expect(report, contains('中式黑八 · 对局数据'));
    expect(report, contains('导出时间：2026-11-07 12:00'));
    expect(report, contains('对局 2 场 · 人机 2 场 · 人机胜率 50%'));
    expect(report, contains('总杆数 2 · 进球 3 · 进球率 150%'));
    expect(report, contains('单杆最多 2 球 · 最长连续进球 1 杆'));
    expect(report, contains('高手 · 电脑获胜'));
    expect(report.indexOf('电脑获胜'), lessThan(report.indexOf('你赢了')));
  });

  test('空记录给出明确提示', () {
    final report = buildMatchReport([], now: DateTime(2026, 11, 7));

    expect(report, contains('对局 0 场'));
    expect(report, contains('暂无对局记录'));
  });
}
