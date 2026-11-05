import 'package:flutter/foundation.dart';

import 'ball.dart';
import 'match_record.dart';
import 'physics.dart';
import 'table_geometry.dart';

/// 回放播放器内部的阶段：装载球局、推进物理、停稳停顿与终局。
enum _ReplayState { idle, running, settling, ended }

/// 回放播放器：按记录的出杆参数重演物理，负责进度、播放与逐杆跳转。
///
/// 每一杆都从记录下的球局开始重演，落点偏差不会跨杆累积；播放时与实时
/// 对局共用 [ShotSimulation]，因此走位与落袋表现与当时一致。
class ReplayPlayer extends ChangeNotifier {
  ReplayPlayer(this.record) : _simulation = _snapshot(record, 0);

  /// 一杆停稳后留给观众的停顿。
  static const double shotPause = 0.75;

  final MatchRecord record;

  late ShotSimulation _simulation;
  int _index = 0;
  bool _playing = false;
  _ReplayState _state = _ReplayState.idle;
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

  ReplayShot? get activeShot =>
      record.shots.isEmpty ? null : record.shots[atEnd ? total - 1 : _index];

  /// 0~1 的播放进度，供滑杆展示。
  double get progress => total == 0 ? 0 : (atEnd ? 1.0 : _index / total);

  /// 第几杆（1 起），终局时等于总杆数。
  int get displayIndex => total == 0 ? 0 : (atEnd ? total : _index + 1);

  void togglePlay() => _playing ? pause() : play();

  /// 开始或继续播放：终局时从第一杆重放，暂停在停顿时继续倒计时。
  void play() {
    if (!canPlay) return;
    if (atEnd) {
      _index = 0;
      _startShot();
    } else if (_state == _ReplayState.idle) {
      _startShot();
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
    _pauseLeft = 0;
    _index = index.clamp(0, total);
    _clearEffects();
    if (atEnd) {
      _simulation = _finishedSimulation();
      _state = _ReplayState.ended;
    } else {
      _simulation = _snapshot(record, _index);
      _state = _ReplayState.idle;
    }
    notifyListeners();
  }

  void next() => seek(atEnd ? total : _index + 1);

  void previous() => seek(_index - 1);

  /// Flame 每帧调用：推进当前杆，停稳后停顿再自动进入下一杆。
  void tick(double dt) {
    if (!_playing || dt <= 0) return;
    switch (_state) {
      case _ReplayState.running:
        _simulation.step(dt);
        _collectEffects();
        if (_simulation.settled) {
          _state = _ReplayState.settling;
          _pauseLeft = shotPause;
        }
      case _ReplayState.settling:
        _pauseLeft -= dt;
        if (_pauseLeft <= 0) _advance();
      case _ReplayState.idle:
      case _ReplayState.ended:
        break;
    }
  }

  void _startShot() {
    final shot = record.shots[_index];
    _clearEffects();
    _simulation = _snapshot(record, _index)..strike(shot.angle, shot.power);
    _state = _ReplayState.running;
    _pauseLeft = shotPause;
  }

  void _advance() {
    _index++;
    if (_index >= total) {
      _playing = false;
      _state = _ReplayState.ended;
      _clearEffects();
      notifyListeners();
      return;
    }
    _startShot();
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

  static ShotSimulation _snapshot(MatchRecord record, int index) {
    if (record.shots.isEmpty) {
      return ShotSimulation(balls: TableGeometry.rackBalls());
    }
    return ShotSimulation(balls: record.shots[index].balls);
  }

  /// 直接跳到最后时，快速推演最后一杆得到终局球局。
  ShotSimulation _finishedSimulation() {
    if (record.shots.isEmpty) return _snapshot(record, 0);
    final last = record.shots.last;
    return _snapshot(record, total - 1)
      ..strike(last.angle, last.power)
      ..simulateToRest();
  }
}
