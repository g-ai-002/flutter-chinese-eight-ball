import 'package:chinese_eight_ball/core/ball.dart';
import 'package:chinese_eight_ball/core/table_geometry.dart';
import 'package:chinese_eight_ball/core/vec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('摆球', () {
    test('16 颗球齐全且 8 号在三角中心', () {
      final balls = TableGeometry.rackBalls();
      expect(balls, hasLength(16));
      expect(balls.map((ball) => ball.id).toSet(), hasLength(16));

      final eight = balls.firstWhere((ball) => ball.id == 8);
      final rowGap = TableGeometry.rackSpacing * 0.8660254;
      expect(eight.position.y, closeTo(TableGeometry.footSpot.y, 1e-6));
      expect(
        eight.position.x,
        closeTo(TableGeometry.footSpot.x + rowGap * 2, 1e-6),
      );
      final apex = balls.firstWhere((ball) => ball.id == 1);
      expect(apex.position.distanceTo(TableGeometry.footSpot), lessThan(1e-9));
      final cue = balls.firstWhere((ball) => ball.isCue);
      expect(cue.position.x, lessThanOrEqualTo(TableGeometry.headStringX));
    });

    test('球与球之间不重叠且在台面内', () {
      final balls = TableGeometry.rackBalls();
      for (var i = 0; i < balls.length; i++) {
        final a = balls[i];
        expect(a.position.x, inInclusiveRange(0, TableGeometry.width));
        expect(a.position.y, inInclusiveRange(0, TableGeometry.height));
        for (var j = i + 1; j < balls.length; j++) {
          expect(
            a.position.distanceTo(balls[j].position),
            greaterThanOrEqualTo(TableGeometry.ballRadius * 2),
          );
        }
      }
    });

    test('全色与花色各 7 颗', () {
      final balls = TableGeometry.rackBalls();
      expect(balls.where((ball) => ball.kind == BallKind.solid), hasLength(7));
      expect(balls.where((ball) => ball.kind == BallKind.stripe), hasLength(7));
    });

    test('三角形后排两角一全一花', () {
      final balls = TableGeometry.rackBalls();
      final backRow = balls
          .where(
            (ball) =>
                ball.position.x >
                TableGeometry.footSpot.x + TableGeometry.rackSpacing * 3,
          )
          .toList();
      expect(backRow, hasLength(5));
      backRow.sort((a, b) => a.position.y.compareTo(b.position.y));
      expect(backRow.first.isEight, isFalse);
      expect(backRow.last.isEight, isFalse);
      expect(backRow.first.kind, isNot(backRow.last.kind));
    });
  });

  group('母球摆放', () {
    test('台面中央合法，越界与袋口位置非法', () {
      expect(TableGeometry.isValidCuePlacement(TableGeometry.center), isTrue);
      expect(TableGeometry.isValidCuePlacement(const Vec2(-0.1, 0.6)), isFalse);
      expect(
        TableGeometry.isValidCuePlacement(const Vec2(0.02, 0.02)),
        isFalse,
      );
    });

    test('与其他球重叠时非法', () {
      final obstacles = [
        BallState(
          spec: const BallSpec(1, BallKind.solid),
          position: const Vec2(1.2, 0.6),
        ),
      ];
      expect(
        TableGeometry.isValidCuePlacement(
          const Vec2(1.2, 0.6),
          obstacles: obstacles,
        ),
        isFalse,
      );
      expect(
        TableGeometry.isValidCuePlacement(
          const Vec2(1.2, 0.8),
          obstacles: obstacles,
        ),
        isTrue,
      );
    });

    test('开球区限制在开球线左侧', () {
      expect(
        TableGeometry.isValidBreakPlacement(TableGeometry.headSpot),
        isTrue,
      );
      expect(
        TableGeometry.isValidBreakPlacement(const Vec2(1.6, 0.635)),
        isFalse,
      );
    });

    test('自动寻找最近的可摆放位置', () {
      final obstacles = [
        BallState(
          spec: const BallSpec(1, BallKind.solid),
          position: TableGeometry.headSpot,
        ),
      ];
      final spot = TableGeometry.nearestValidCueSpot(
        TableGeometry.headSpot,
        obstacles: obstacles,
        breakZone: true,
      );
      expect(spot, isNotNull);
      expect(
        TableGeometry.isValidCuePlacement(spot!, obstacles: obstacles),
        isTrue,
      );
    });
  });
}
