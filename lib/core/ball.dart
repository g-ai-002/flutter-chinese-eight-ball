import 'vec.dart';

/// 球的分组：1-7 全色，9-15 花色，8 号为黑八，0 号为母球。
enum BallKind { cue, solid, stripe, eight }

/// 球的静态信息，颜色由界面层按 id 决定。
class BallSpec {
  const BallSpec(this.id, this.kind);

  /// 按球号还原静态信息：0 母球、8 黑八、1-7 全色、9-15 花色。
  factory BallSpec.fromId(int id) {
    if (id == 0) return kCueBall;
    final kind = id == 8
        ? BallKind.eight
        : (id < 8 ? BallKind.solid : BallKind.stripe);
    return BallSpec(id, kind);
  }

  final int id;
  final BallKind kind;

  bool get isCue => kind == BallKind.cue;
  bool get isEight => kind == BallKind.eight;
}

const BallSpec kCueBall = BallSpec(0, BallKind.cue);

/// 台面上的一颗球：静态信息 + 可变的物理状态。
class BallState {
  BallState({required this.spec, required this.position, Vec2? velocity})
    : velocity = velocity ?? Vec2.zero;

  final BallSpec spec;
  Vec2 position;
  Vec2 velocity;

  /// 已落袋的球置为 false。
  bool active = true;

  int get id => spec.id;
  BallKind get kind => spec.kind;
  bool get isCue => spec.isCue;
  bool get isEight => spec.isEight;

  double get speed => velocity.length;

  BallState clone() =>
      BallState(spec: spec, position: position, velocity: velocity)
        ..active = active;

  static List<BallState> cloneAll(Iterable<BallState> balls) => [
    for (final ball in balls) ball.clone(),
  ];
}

/// 全色 / 花色分组。
enum PlayerGroup {
  solids(BallKind.solid, '全色'),
  stripes(BallKind.stripe, '花色');

  const PlayerGroup(this.kind, this.label);

  final BallKind kind;
  final String label;

  static PlayerGroup ofBall(BallKind kind) =>
      kind == BallKind.solid ? solids : stripes;
}
