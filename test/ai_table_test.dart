import 'package:chinese_eight_ball/core/ai_table.dart';
import 'package:chinese_eight_ball/core/ball.dart';
import 'package:chinese_eight_ball/core/table_geometry.dart';
import 'package:chinese_eight_ball/core/vec.dart';
import 'package:flutter_test/flutter_test.dart';

BallState ball(int id, double x, double y) =>
    BallState(spec: BallSpec.fromId(id), position: Vec2(x, y));

List<int> ids(Iterable<BallState> balls) => [for (final ball in balls) ball.id];

void main() {
  group('目标球筛选', () {
    test('开放球台排除黑八与母球', () {
      final targets = AiTable.legalTargets(
        [
          ball(0, 0.5, 0.5),
          ball(1, 1.0, 0.5),
          ball(9, 1.3, 0.5),
          ball(8, 1.6, 0.5),
        ],
        null,
        false,
      );
      expect(ids(targets), [1, 9]);
    });

    test('已定组时只看本方花色', () {
      final targets = AiTable.legalTargets(
        [
          ball(0, 0.5, 0.5),
          ball(1, 1.0, 0.5),
          ball(9, 1.3, 0.5),
          ball(8, 1.6, 0.5),
        ],
        PlayerGroup.solids,
        false,
      );
      expect(ids(targets), [1]);
    });

    test('本方清台后目标切换为黑八', () {
      final targets = AiTable.legalTargets(
        [ball(0, 0.5, 0.5), ball(9, 1.3, 0.5), ball(8, 1.6, 0.5)],
        PlayerGroup.solids,
        false,
      );
      expect(ids(targets), [8]);
    });

    test('攻打黑八时只返回黑八', () {
      final targets = AiTable.legalTargets(
        [ball(0, 0.5, 0.5), ball(1, 1.0, 0.5), ball(8, 1.6, 0.5)],
        PlayerGroup.solids,
        true,
      );
      expect(ids(targets), [8]);
    });

    test('对手目标按相反花色计算，清台后为黑八', () {
      final balls = [ball(1, 1.0, 0.5), ball(9, 1.3, 0.5), ball(10, 1.6, 0.5)];
      expect(ids(AiTable.opponentTargets(balls, PlayerGroup.solids)), [9, 10]);
      expect(ids(AiTable.opponentTargets(balls, PlayerGroup.stripes)), [1]);

      final cleared = [ball(1, 1.0, 0.5), ball(8, 1.6, 0.5)];
      expect(ids(AiTable.opponentTargets(cleared, PlayerGroup.solids)), [8]);
    });
  });

  group('进球线路', () {
    test('正对中袋的线路可行', () {
      const cue = Vec2(1.27, 1.0);
      final target = ball(1, 1.27, 0.5);
      final line = AiTable.lineFor(cue, target, 1, [target]);
      expect(line, isNotNull);
      expect(line!.score, isPositive);
      expect(line.angle, closeTo(-1.5708, 0.05));
    });

    test('母球到幽灵球被挡时线路不可行', () {
      const cue = Vec2(1.27, 1.0);
      final target = ball(1, 1.27, 0.5);
      final blocker = ball(2, 1.27, 0.75);
      expect(AiTable.lineFor(cue, target, 1, [target, blocker]), isNull);
    });

    test('目标球到袋口被挡时线路不可行', () {
      const cue = Vec2(1.27, 1.0);
      final target = ball(1, 1.27, 0.5);
      final blocker = ball(2, 1.27, 0.3);
      expect(AiTable.lineFor(cue, target, 1, [target, blocker]), isNull);
    });

    test('袋口与目标球重合时返回 null', () {
      final pocket = TableGeometry.pockets[0];
      const cue = Vec2(1.27, 1.0);
      final target = ball(1, pocket.x, pocket.y);
      expect(AiTable.lineFor(cue, target, 0, [target]), isNull);
    });
  });

  group('台面距离与遮挡', () {
    test('库边距离取最近一侧', () {
      expect(AiTable.edgeDistance(const Vec2(1.27, 0.635)), closeTo(0.635, 1e-9));
      expect(AiTable.edgeDistance(const Vec2(0.1, 0.5)), closeTo(0.1, 1e-9));
    });

    test('袋口距离在袋口处为零', () {
      expect(
        AiTable.pocketDistance(TableGeometry.pockets.first),
        closeTo(0, 1e-9),
      );
      expect(AiTable.pocketDistance(const Vec2(1.27, 0.635)), greaterThan(0.3));
    });

    test('母球到目标球被挡判定为藏球', () {
      const cue = Vec2(1.27, 1.0);
      final target = ball(1, 1.27, 0.5);
      final blocker = ball(2, 1.27, 0.75);
      expect(AiTable.hiddenTargets(cue, [target], [target, blocker]), 1);
      expect(AiTable.hiddenTargets(cue, [target], [target]), 0);
    });

    test('没有目标球时对手威胁为零', () {
      expect(AiTable.opponentThreat(const Vec2(1.27, 1.0), const [], const []), 0);
    });
  });
}
