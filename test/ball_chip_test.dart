import 'dart:typed_data';

import 'package:chinese_eight_ball/pages/widgets/ball_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// 渲染单颗球型图标并返回 RGBA 像素，坐标原点在图标左上角。
Future<(Uint8List, int)> _renderChip(WidgetTester tester, int id, {double size = 100}) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: RepaintBoundary(
          key: key,
          child: BallChip(id: id, size: size),
        ),
      ),
    ),
  );
  await tester.pump();
  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  late Uint8List bytes;
  late int width;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    width = image.width;
    final data = await image.toByteData();
    bytes = data!.buffer.asUint8List();
    image.dispose();
  });
  return (bytes, width);
}

Color _pixel(Uint8List bytes, int width, int x, int y) {
  final offset = (y * width + x) * 4;
  return Color.fromARGB(bytes[offset + 3], bytes[offset], bytes[offset + 1], bytes[offset + 2]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('花色球图标为白色球身配彩色球带', (tester) async {
    final (bytes, width) = await _renderChip(tester, 9);
    // 球径 100：上沿 8% 处是白色球身，球带中线与球带上沿是花色。
    final body = _pixel(bytes, width, 50, 8);
    final band = _pixel(bytes, width, 10, 50);
    final bandTop = _pixel(bytes, width, 50, 26);

    expect(body.b * 255, greaterThan(215), reason: '花色球球身应为白色');
    expect(body.r * 255, greaterThan(230), reason: '花色球球身应为白色');
    expect(band.b * 255, lessThan(150), reason: '花色球带应保留花色');
    expect(bandTop.b * 255, lessThan(170), reason: '球带要盖过号码白底，不能被白底吞掉');
  });

  testWidgets('全色球图标通体着色，花色球球心仍是号码白底', (tester) async {
    final (solid, solidWidth) = await _renderChip(tester, 1);
    final (stripe, stripeWidth) = await _renderChip(tester, 9);

    expect(_pixel(solid, solidWidth, 50, 8).b * 255, lessThan(170), reason: '全色球球身应着色');
    expect(_pixel(solid, solidWidth, 10, 50).b * 255, lessThan(170), reason: '全色球球身应着色');
    expect(_pixel(stripe, stripeWidth, 34, 50).r * 255, greaterThan(200), reason: '球心仍是号码白底');
  });
}
