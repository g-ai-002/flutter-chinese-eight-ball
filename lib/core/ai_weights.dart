/// AI 评分权重与阈值，按「进攻 / 走位 / 防守」分组集中管理。
///
/// 调整 AI 性格时只需改动这里，避免评分常量散落在评估逻辑中。
class AiWeights {
  AiWeights._();

  // ---------- 进攻 ----------
  static const List<double> powerLevels = [0.42, 0.62, 0.85];
  static const double scratchPenalty = 260;
  static const double ownPotBonus = 150;
  static const double opponentPotPenalty = 90;
  static const double eightWinBonus = 5000;
  static const double eightLossPenalty = 5000;
  static const double noContactPenalty = 420;
  static const double wrongGroupPenalty = 320;
  static const double eightContactPenalty = 380;

  // ---------- 走位 ----------
  static const double positionBaseBonus = 40;
  static const double positionLineScale = 12;
  static const double positionDistanceScale = 18;
  static const double railPenalty = 25;
  static const double pocketPenalty = 26;

  /// 母球距库边小于该值视为贴库。
  static const double railMargin = 0.06;

  // ---------- 进攻 / 防守取舍 ----------
  /// 进攻得分低于该值时，AI 会同时评估防守杆，避免硬打送机会。
  static const double attackConfidence = 90;
  static const double safetyGainMargin = 10;

  // ---------- 防守 ----------
  /// 防守杆的力度档位：只求轻碰与藏球，不追求走位距离。
  static const List<double> safetyPowers = [0.24, 0.36, 0.52];
  static const double safetyBase = 55;
  static const double safetyScratchPenalty = 240;
  static const double safetyWrongContactPenalty = 150;
  static const double safetyEightPotPenalty = 4000;
  static const double safetyEightContactPenalty = 110;
  static const double safetyOpponentPotPenalty = 80;
  static const double safetyRailBonus = 20;
  static const double safetyDistanceScale = 16;
  static const double safetyThreatPenalty = 8;
  static const double safetyHiddenBonus = 12;
  static const double safetyTargetRailBonus = 6;

  /// 找不到任何防守线路时的兜底力度，只求合法接触。
  static const double fallbackPower = 0.4;
}
