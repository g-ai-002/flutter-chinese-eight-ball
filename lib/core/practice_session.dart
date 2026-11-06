import 'ball.dart';

import 'practice_preset.dart';

/// 自由练习的独立状态：摆球开关、杆数、当前球型与上一杆快照。
///
/// 练习模式不参与回合与犯规裁定，把这类状态从 [MatchController] 中拆出，
/// 避免对局流程与练习流程互相干扰。
class PracticeSession {
  PracticeSession({PracticePreset? preset}) {
    _preset = preset;
  }

  bool _editing = false;
  int _shots = 0;
  List<BallState>? _restore;
  PracticePreset? _preset;

  bool get editing => _editing;

  int get shots => _shots;

  bool get canUndo => _restore != null;

  /// 当前球型；手动摆球或未选择模板时为 null。
  PracticePreset? get preset => _preset;

  void beginEdit() {
    _editing = true;
    _preset = null;
  }

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

  /// 重置练习状态；[preset] 非空时同时把当前球型标记为该模板。
  void reset({PracticePreset? preset}) {
    _editing = false;
    _shots = 0;
    _restore = null;
    _preset = preset;
  }
}
