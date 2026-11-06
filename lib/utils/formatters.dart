/// 全局时间格式化工具。
library;

String pad2(int value) => value.toString().padLeft(2, '0');

/// `yyyyMMdd`，用于日志文件名。
String formatDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}${pad2(date.month)}${pad2(date.day)}';

/// `yyyy-MM-dd HH:mm`。
String formatDateTime(DateTime time) =>
    '${time.year.toString().padLeft(4, '0')}-${pad2(time.month)}-${pad2(time.day)} '
    '${pad2(time.hour)}:${pad2(time.minute)}';

/// `HH:mm:ss.SSS`，日志行首时间戳。
String formatLogTimestamp(DateTime time) =>
    '${pad2(time.hour)}:${pad2(time.minute)}:${pad2(time.second)}.'
    '${time.millisecond.toString().padLeft(3, '0')}';

/// 角度转度数显示，供瞄准微调使用。
String formatAngle(double radians) {
  var degrees = radians * 180 / 3.141592653589793;
  degrees %= 360;
  if (degrees < 0) degrees += 360;
  return '${degrees.toStringAsFixed(1)}°';
}

/// 0~1 的比例显示为整数百分比，例如 `0.625` → `63%`。
String formatPercent(double ratio) => '${(ratio * 100).round()}%';

String formatLogLine(DateTime time, String level, String message) =>
    '[${formatLogTimestamp(time)}][$level] $message';
