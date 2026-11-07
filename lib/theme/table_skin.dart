import 'package:flutter/material.dart';

/// 球台配色：台呢、木质边框、袋口与刻度线。
class TableSkin {
  const TableSkin({
    required this.id,
    required this.name,
    required this.cloth,
    required this.clothLight,
    required this.clothDark,
    required this.rail,
    required this.railEdge,
    required this.marking,
    required this.diamond,
    required this.pocket,
  });

  final String id;
  final String name;
  final Color cloth;
  final Color clothLight;
  final Color clothDark;
  final Color rail;
  final Color railEdge;
  final Color marking;
  final Color diamond;
  final Color pocket;
}

const List<TableSkin> kTableSkins = [
  TableSkin(
    id: 'emerald',
    name: '翡翠台呢',
    cloth: Color(0xFF0F5132),
    clothLight: Color(0xFF1B6B45),
    clothDark: Color(0xFF093523),
    rail: Color(0xFF5A3A22),
    railEdge: Color(0xFF3A2413),
    marking: Color(0x33F2E8D0),
    diamond: Color(0xFFE8D6A8),
    pocket: Color(0xFF14110D),
  ),
  TableSkin(
    id: 'midnight',
    name: '午夜蓝',
    cloth: Color(0xFF153A5B),
    clothLight: Color(0xFF21507A),
    clothDark: Color(0xFF0C2438),
    rail: Color(0xFF2E2118),
    railEdge: Color(0xFF1B130D),
    marking: Color(0x33DCE9F5),
    diamond: Color(0xFFCBD9E6),
    pocket: Color(0xFF0B0F14),
  ),
  TableSkin(
    id: 'wine',
    name: '酒红呢',
    cloth: Color(0xFF5A1F26),
    clothLight: Color(0xFF7A2C34),
    clothDark: Color(0xFF3A1218),
    rail: Color(0xFF3B2A1C),
    railEdge: Color(0xFF24170D),
    marking: Color(0x33F5E4D2),
    diamond: Color(0xFFE5C9A8),
    pocket: Color(0xFF120A08),
  ),
];

TableSkin tableSkinOf(String? id) =>
    kTableSkins.firstWhere((skin) => skin.id == id, orElse: () => kTableSkins.first);

/// 球色按中式黑八标准配色，9-15 号沿用对应全色球的颜色。
Color ballColorOf(int id) {
  const colors = <int, Color>{
    1: Color(0xFFF2C230),
    2: Color(0xFF2159A8),
    3: Color(0xFFC0392B),
    4: Color(0xFF6C3E97),
    5: Color(0xFFE07A2E),
    6: Color(0xFF2E7D4F),
    7: Color(0xFF8C2F39),
    8: Color(0xFF17181A),
    9: Color(0xFFF2C230),
    10: Color(0xFF2159A8),
    11: Color(0xFFC0392B),
    12: Color(0xFF6C3E97),
    13: Color(0xFFE07A2E),
    14: Color(0xFF2E7D4F),
    15: Color(0xFF8C2F39),
  };
  return colors[id] ?? const Color(0xFFF7F3E8);
}
