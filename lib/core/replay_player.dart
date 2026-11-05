import 'package:flutter/foundation.dart';

import 'ball.dart';
import 'match_record.dart';
import 'physics.dart';
import 'table_geometry.dart';

/// 回放播放器：按记录的出杆参数重演物理，负责进度、播放与逐杆跳转。
///
/// 每一杆都从记录下的球局开始重演，落点偏差不会跨杆累积；播放时与实时
/// 对局共用 [ShotSimulation]，因此走位与落袋表现与当时一致。
class ReplayPlayer extends ChangeNotifier {
  ReplayPlayer(this.record)
    : _simulation = ShotSimulation(
        balls: record.shots.isEmpty
            ? TableGeometry.rackBalls()
            : record.shots.first.balls,
      );

  /// 一杆停稳后留给观众的停顿。
  static const double shotPause = 0.75;

  final MatchRecord record;

  late ShotSimulation _simulation;
  int _index = 0;
  bool _playing = false;
  bool _shotInProgress = false;
  double _pauseLeft = 0;
  int _effectCursor = 0;

  /// 供球台组件取用的撞击与落袋事件。
  final List<ShotEvent> pendingEffects = [];

  List<BallState> get balls => _simulation.balls;

  int get index => _index;

  int get total => record.shots.length;

  bool get isPlaying => _playing;

  /// 是否停在终局画面（最后一杆已结束）。
  bool get atEnd => _index >= total;

  bool get canPlay => total > 0;

  ReplayShot? get activeShot => record.shots.isEmpty
      ? null
      : record.shots[atEnd ? total - 1 : _index];

  /// 0~1 的播放进度，供滑杆展示。
  double get progress => total == 0
      ? 0
      : (atEnd ? 1.0 : _index / total);

  /// 第几杆（1 起），终局时等于总杆数。
  int get displayIndex => total == 0
      ? 0
      : (atEnd ? total : _index + 1);

  void togglePlay() => _playing ? pause() : play();

  void play() {
    if (total == 0) return;
    if (atEnd) {
      _index = 0;
      _beginShot();
    } else if (!_shotInProgress) {
      _beginShot();
    }
    _playing = true;
    notifyListeners();
  }

  void pause() {
    if (!_playing) return;
    _playing = false;
    notifyListeners();
  }

  /// 跳到第 [index] 杆开始前；[index] 等于总杆数时展示终局球局。
  void seek(int index) {
    _playing = false;
    _shotInProgress = false;
    _pauseLeft = 0;
    _index = index.clamp(0, total);
    _clearEffects();
    _simulation = atEnd
        ? _finishedSimulation()
        : ShotSimulation(balls: record.shots[_index].balls);
    notifyListeners();
  }

  void next() => seek(atEnd ? total : _index + 1);

  void previous() => seek(_index - 1);

  /// Flame 每帧调用：推进当前杆，停稳后停顿再自动进入下一杆。
  void tick(double dt) {
    if (!_playing || dt <= 0) return;
    if (_simulation.settled) {
      _pauseLeft -= dt;
      if (_pauseLeft <= 0) _advance();
      return;
    }
    _simulation.step(dt);
    _collectEffects();
    if (_simulation.settled) _pauseLeft = shotPause;
  }

  void _beginShot() {
    final shot = record.shots[_index];
    _clearEffects();
    _simulation = ShotSimulation(balls: shot.balls)..strike(shot.angle, shot.power);
    _shotInProgress = true;
    _pauseLeft = shotPause;
  }

  void _advance() {
    _index++;
    if (_index >= total) {
      _playing = false;
      _shotInProgress = false;
      _clearEffects();
      notifyListeners();
      return;
    }
    _beginShot();
    notifyListeners();
  }

  void _clearEffects() {
    pendingEffects.clear();
    _effectCursor = 0;
  }

  void _collectEffects() {
    while (_effectCursor < _simulation.events.length) {
      pendingEffects.add(_simulation.events[_effectCursor]);
      _effectCursor++;
    }
  }

  /// 直接跳到最后时，快速推演最后一杆得到终局球局。
  ShotSimulation _finishedSimulation() {
    if (record.shots.isEmpty) return ShotSimulation(balls: TableGeometry.rackBalls());
    final last = record.shots.last;
    final simulation = ShotSimulation(balls: last.balls)
      ..strike(last.angle, last.power);
    simulation.simulateToRest();
    return simulation;
  }
}
