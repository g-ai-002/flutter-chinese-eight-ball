import 'package:chinese_eight_ball/pages/widgets/stats_bars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpBars(WidgetTester tester, StatsBars bars) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: 320, height: 160, child: bars)),
      ),
    ),
  );
}

void main() {
  testWidgets('柱状图绘制标注、圆点与最小柱高', (tester) async {
    await pumpBars(
      tester,
      const StatsBars(
        height: 120,
        bars: [
          StatsBar(
            heightFactor: 0.5,
            topLabel: '50',
            bottomLabel: '11/6',
            marker: Colors.green,
          ),
          StatsBar(heightFactor: 0, bottomLabel: '11/7'),
        ],
      ),
    );

    expect(find.text('50'), findsOneWidget);
    expect(find.text('11/6'), findsOneWidget);
    expect(find.text('11/7'), findsOneWidget);

    final boxes = tester
        .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
        .toList();
    expect(boxes, hasLength(2));
    expect(boxes[0].heightFactor, 0.5);
    expect(boxes[1].heightFactor, 0.06);

    final dot = tester.widget<Icon>(find.byIcon(Icons.circle));
    expect(dot.color, Colors.green);
  });

  testWidgets('无数据柱支持更小的最小高度', (tester) async {
    await pumpBars(
      tester,
      const StatsBars(
        height: 80,
        minFactor: 0.04,
        bars: [StatsBar(heightFactor: 0, bottomLabel: '11/7', muted: true)],
      ),
    );

    final box = tester.widget<FractionallySizedBox>(
      find.byType(FractionallySizedBox),
    );
    expect(box.heightFactor, 0.04);
  });
}
