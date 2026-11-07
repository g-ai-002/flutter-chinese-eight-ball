import 'dart:ui' as ui;

import 'package:chinese_eight_ball/core/ai_table.dart';
import 'package:chinese_eight_ball/core/ball.dart';
import 'package:chinese_eight_ball/core/table_geometry.dart';
import 'package:chinese_eight_ball/core/vec.dart';
import 'package:chinese_eight_ball/flame/table_layout.dart';
import 'package:chinese_eight_ball/flame/table_scene.dart';
import 'package:chinese_eight_ball/pages/widgets/power_control.dart';
import 'package:chinese_eight_ball/theme/table_skin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

BallState ball(int id, double x, double y) =>
    BallState(spec: BallSpec.fromId(id), position: Vec2(x, y));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('台面布局缓存半径与矩形', () {
    final layout = TableLayout(const Size(1000, 600));
    expect(identical(layout.surfaceRect, layout.surfaceRect), isTrue);
    expect(identical(layout.tableRect, layout.tableRect), isTrue);
    expect(layout.ballRadius, TableGeometry.ballRadius * layout.scale);
    expect(layout.pocketRadius, TableGeometry.pocketRadius * layout.scale);
  });

  test('线段距离平方覆盖落点与端点', () {
    const start = Vec2(0, 0);
    const end = Vec2(2, 0);
    expect(distanceSquaredToSegment(const Vec2(1, 0.5), start, end), closeTo(0.25, 1e-9));
    expect(distanceSquaredToSegment(const Vec2(-1, 0), start, end), closeTo(1, 1e-9));
    expect(distanceSquaredToSegment(const Vec2(2, 1), start, end), closeTo(1, 1e-9));
    expect(distanceSquaredToSegment(const Vec2(1, 0), start, start), closeTo(1, 1e-9));
  });

  test('阻挡判定按球号忽略目标球', () {
    final cue = ball(0, 0.5, 0.6);
    final target = ball(1, 1.2, 0.6);
    final blocker = ball(2, 0.9, 0.6);
    expect(
      AiTable.pathBlocked(from: cue.position, to: target.position, balls: [cue, target, blocker]),
      isTrue,
    );
    expect(
      AiTable.pathBlocked(
        from: cue.position,
        to: target.position,
        balls: [cue, target, blocker],
        ignoreA: 0,
        ignoreB: 1,
      ),
      isTrue,
    );
    expect(
      AiTable.pathBlocked(
        from: cue.position,
        to: target.position,
        balls: [target, blocker],
        ignoreA: 1,
        ignoreB: 2,
      ),
      isFalse,
    );
  });

  testWidgets('静态台面与球体显示列表可重复绘制', (tester) async {
    final scene = TableScene();
    final balls = TableGeometry.rackBalls();
    final layout = TableLayout(const Size(900, 500));
    final skin = kTableSkins.first;

    void paint(Canvas canvas) {
      scene.paintTable(canvas, layout, skin);
      scene.paintBalls(canvas, layout, balls);
    }

    for (var i = 0; i < 2; i++) {
      final recorder = ui.PictureRecorder();
      paint(Canvas(recorder));
      recorder.endRecording().dispose();
    }

    final resized = ui.PictureRecorder();
    paint(Canvas(resized));
    resized.endRecording().dispose();

    final otherLayout = TableLayout(const Size(700, 400));
    final resizedRecorder = ui.PictureRecorder();
    final canvas = Canvas(resizedRecorder);
    scene.paintTable(canvas, otherLayout, kTableSkins[1]);
    scene.paintBalls(canvas, otherLayout, balls);
    resizedRecorder.endRecording().dispose();
  });

  testWidgets('拖动力度滑杆只刷新控件自身', (tester) async {
    var parentBuilds = 0;
    double? changed;
    Widget build() => MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) {
            parentBuilds++;
            return PowerControl(
              power: 0.72,
              onPowerChanged: (value) => changed = value,
              onAimLeft: null,
              onAimRight: null,
              onShoot: () {},
              canShoot: true,
            );
          },
        ),
      ),
    );

    await tester.pumpWidget(build());
    final buildsBefore = parentBuilds;
    final slider = find.byType(Slider);
    await tester.tapAt(tester.getRect(slider).centerRight - const Offset(4, 0));
    await tester.pump();

    expect(changed, isNotNull);
    expect(changed, greaterThan(0.72));
    expect(parentBuilds, buildsBefore);
    expect(find.textContaining('%'), findsOneWidget);
  });
}
