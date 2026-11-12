import 'dart:ui' as ui;

import 'package:chinese_eight_ball/core/ball.dart';
import 'package:chinese_eight_ball/core/table_geometry.dart';
import 'package:chinese_eight_ball/core/vec.dart';
import 'package:chinese_eight_ball/flame/painting/ball_painter.dart';
import 'package:chinese_eight_ball/flame/table_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 花色球必须是白色球身 + 彩色球带，全色球通体着色。
/// 采样球体上沿（球身）与球带中线（球带）两个像素做区分。
Future<ui.Image> renderBall(BallState ball) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..translate(50, 50);
  BallPainter().paintShape(canvas, ball, 40);
  return recorder.endRecording().toImage(100, 100);
}

/// 按球台尺寸绘制一颗球，用于验证缓存显示列表会缩放到实际球径。
Future<ui.Image> renderAtSize(double width) async {
  final height = width / TableLayout.aspectRatio;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final layout = TableLayout(Size(width, height));
  final ball = BallState(spec: BallSpec.fromId(0), position: TableGeometry.center);
  BallPainter().paintBall(canvas, layout, ball);
  return recorder.endRecording().toImage(width.round(), height.round());
}

Future<int> alphaAt(ui.Image image, Offset point) async {
  final data = await image.toByteData();
  final offset = (point.dy.round() * image.width + point.dx.round()) * 4 + 3;
  return data!.getUint8(offset);
}

Future<Color> pixelAt(ui.Image image, int x, int y) async {
  final data = await image.toByteData();
  final offset = (y * image.width + x) * 4;
  return Color.fromARGB(
    data!.getUint8(offset + 3),
    data.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
  );
}

BallState ballOf(int id, BallKind? kind) {
  final spec = BallSpec.fromId(id);
  return BallState(
    spec: kind == null || kind == spec.kind ? spec : BallSpec(id, kind),
    position: Vec2.zero,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('花色球用白色球身，球带保留花色', () async {
    final stripe = await renderBall(ballOf(9, null));
    final solid = await renderBall(ballOf(9, BallKind.solid));

    // 球体上沿离球心 34 像素，落在球带上方的白色球身处。
    final stripeBody = await pixelAt(stripe, 50, 16);
    final solidBody = await pixelAt(solid, 50, 16);
    expect(stripeBody.b * 255, greaterThan(180), reason: '花色球球身应为白色');
    expect(solidBody.b * 255, lessThan(140), reason: '全色球球身应保留球色');

    // 球带中线离球心 19 像素，花色球的球带要保留球色，与白色球身区分开。
    final stripeBand = await pixelAt(stripe, 50, 31);
    expect(stripeBand.b * 255, lessThan(140), reason: '花色球球带应着色');

    final imageBytes = await stripe.toByteData();
    expect(imageBytes, isNotNull);
    stripe.dispose();
    solid.dispose();
  });

  test('母球与黑八的配色保持原样', () async {
    final cue = await renderBall(ballOf(0, null));
    final eight = await renderBall(ballOf(8, null));
    final cueCenter = await pixelAt(cue, 50, 50);
    final eightBody = await pixelAt(eight, 50, 16);
    expect(cueCenter.r * 255, greaterThan(200), reason: '母球应接近白色');
    expect(eightBody.r * 255, lessThan(120), reason: '黑八应接近黑色');
    cue.dispose();
    eight.dispose();
  });

  test('缓存的球体显示列表按实际球径缩放', () async {
    for (final width in [840.0, 1260.0]) {
      final image = await renderAtSize(width);
      final layout = TableLayout(Size(width, width / TableLayout.aspectRatio));
      final center = layout.toCanvas(TableGeometry.center);
      final radius = layout.ballRadius;

      expect(await alphaAt(image, center), greaterThan(200), reason: '球心应被绘制');
      expect(
        await alphaAt(image, center + Offset(radius * 0.6, 0)),
        greaterThan(200),
        reason: '球体内部（0.6 倍球径）应被绘制',
      );
      expect(
        await alphaAt(image, center + Offset(radius * 1.4, 0)),
        0,
        reason: '球体外部（1.4 倍球径）不应有多余像素',
      );
      image.dispose();
    }
  });
}
