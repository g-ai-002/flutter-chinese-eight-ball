import 'package:chinese_eight_ball/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('比例格式化为整数百分比', () {
    expect(formatPercent(0), '0%');
    expect(formatPercent(0.5), '50%');
    expect(formatPercent(0.625), '63%');
    expect(formatPercent(1), '100%');
  });

  test('日期时间统一补零', () {
    expect(formatDateTime(DateTime(2026, 1, 2, 3, 4)), '2026-01-02 03:04');
  });
}
