import 'dart:ui' as ui;

import 'package:chinese_eight_ball/flame/painting/preview_painter.dart';
import 'package:chinese_eight_ball/flame/table_layout.dart';
import 'package:chinese_eight_ball/theme/table_skin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<ui.Image> renderPreview(PreviewPainter painter, double width) async {
  final height = width / TableLayout.aspectRatio;
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), Size(width, height), tableSkinOf('emerald'));
  return recorder.endRecording().toImage(width.round(), height.round());
}

Future<Color> pixelAt(ui.Image image, double x, double y) async {
  final data = await image.toByteData();
  final offset = (y.round() * image.width + x.round()) * 4;
  return Color.fromARGB(
    data!.getUint8(offset + 3),
    data.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('缩略图按配色只录制一次显示列表', () {
    final painter = PreviewPainter();
    final emerald = tableSkinOf('emerald');
    final wine = tableSkinOf('wine');

    expect(identical(painter.pictureFor(emerald), painter.pictureFor(emerald)), isTrue);
    expect(painter.pictureCount, 1);
    expect(identical(painter.pictureFor(emerald), painter.pictureFor(wine)), isFalse);
    expect(painter.pictureCount, 2);
  });

  test('同一份显示列表缩放到任意宽度', () async {
    final painter = PreviewPainter();
    final large = await renderPreview(painter, 480);
    final small = await renderPreview(painter, 240);

    // 台呢在两种尺寸下都落在相同相对位置，说明显示列表按宽度等比缩放。
    for (final image in [large, small]) {
      final cloth = await pixelAt(image, image.width * 0.5, image.height * 0.2);
      expect(cloth.g * 255, greaterThan(cloth.r * 255), reason: '台呢应为绿色');
      expect(cloth.g * 255, greaterThan(cloth.b * 255), reason: '台呢应为绿色');
      final center = await pixelAt(image, image.width * 0.5, image.height * 0.5);
      expect(center.a * 255, greaterThan(200), reason: '球台中心应被绘制');
    }
    expect(painter.pictureCount, 1);

    large.dispose();
    small.dispose();
  });

  test('空尺寸不绘制也不录制', () {
    final painter = PreviewPainter();
    final recorder = ui.PictureRecorder();
    painter.paint(Canvas(recorder), Size.zero, tableSkinOf('emerald'));
    expect(painter.pictureCount, 0);
    recorder.endRecording().dispose();
  });
}
