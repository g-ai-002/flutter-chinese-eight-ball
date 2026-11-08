import 'dart:ui' as ui;

import 'package:chinese_eight_ball/core/ball.dart';
import 'package:chinese_eight_ball/core/vec.dart';
import 'package:chinese_eight_ball/flame/painting/ball_painter.dart';
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
}
