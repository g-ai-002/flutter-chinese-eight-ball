import 'ball.dart';

/// 自由练习的独立状态：摆球开关、杆数与上一杆快照。
///
/// 练习模式不参与回合与犯规裁定，把这类状态从 [MatchController] 中拆出，
/// 避免对局流程与练习流程互相干扰。
class PracticeSession {
  bool _editing = false;
  int _shots = 0;
  List<BallState>? _restore;

  bool get editing => _editing;

  int get shots => _shots;

  bool get canUndo => _restore != null;

  void beginEdit() => _editing = true;

  void endEdit() => _editing = false;

  /// 记录出杆前的完整球局，并退出摆球模式。
  void capture(Iterable<BallState> balls) {
    _restore = BallState.cloneAll(balls);
    _editing = false;
  }

  void recordShot() => _shots++;

  /// 取出上一杆的快照；成功后清空快照并退回一杆。
  List<BallState>? restoreShot() {
    final snapshot = _restore;
    if (snapshot == null) return null;
    _restore = null;
    _editing = false;
    if (_shots > 0) _shots--;
    return snapshot;
  }

  void reset() {
    _editing = false;
    _shots = 0;
    _restore = null;
  }
}
