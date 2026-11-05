import 'package:chinese_eight_ball/core/ball.dart';
import 'package:chinese_eight_ball/core/practice_session.dart';
import 'package:chinese_eight_ball/core/table_geometry.dart';
import 'package:chinese_eight_ball/core/vec.dart';
import 'package:flutter_test/flutter_test.dart';

BallState ball(int id, Vec2 position) => BallState(
  spec: BallSpec(id, id == 0 ? BallKind.cue : BallKind.solid),
  position: position,
);

void main() {
  test('捕获快照后原球局变化不影响快照', () {
    final session = PracticeSession();
    final balls = [
      ball(0, const Vec2(0.2, 0.2)),
      ball(1, TableGeometry.center),
    ];

    session
      ..beginEdit()
      ..capture(balls);
    balls.first.position = const Vec2(0.9, 0.9);

    expect(session.editing, isFalse);
    final restore = session.restoreShot();
    expect(restore, isNotNull);
    expect(restore!.first.position, const Vec2(0.2, 0.2));
  });

  test('重打只退一杆，再次重打无效', () {
    final session = PracticeSession();
    final balls = [ball(0, const Vec2(0.3, 0.3))];

    session.capture(balls);
    session.recordShot();

    expect(session.shots, 1);
    expect(session.canUndo, isTrue);
    expect(session.restoreShot(), isNotNull);
    expect(session.shots, 0);
    expect(session.canUndo, isFalse);
    expect(session.restoreShot(), isNull);
  });

  test('重置清空杆数、摆球状态与快照', () {
    final session = PracticeSession();
    session
      ..beginEdit()
      ..capture([ball(0, const Vec2(0.3, 0.3))])
      ..recordShot()
      ..reset();

    expect(session.editing, isFalse);
    expect(session.shots, 0);
    expect(session.canUndo, isFalse);
    expect(session.restoreShot(), isNull);
  });
}
