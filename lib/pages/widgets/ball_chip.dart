import 'package:flutter/material.dart';

import '../../theme/table_skin.dart';

/// 迷你球图标：与台面球体配色一致，花色球带白色横带。
class BallChip extends StatelessWidget {
  const BallChip({super.key, required this.id, this.size = 20});

  final int id;
  final double size;

  @override
  Widget build(BuildContext context) {
    final base = ballColorOf(id);
    final isStripe = id >= 9 && id <= 15;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isStripe ? const Color(0xFFF8F4E8) : base,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
        gradient: isStripe
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFF8F4E8),
                  base,
                  base,
                  const Color(0xFFF8F4E8),
                ],
                stops: const [0, 0.28, 0.72, 1],
              )
            : RadialGradient(
                center: const Alignment(-0.35, -0.4),
                radius: 1.1,
                colors: [
                  Color.lerp(base, Colors.white, 0.4)!,
                  base,
                  Color.lerp(base, Colors.black, 0.3)!,
                ],
              ),
      ),
      child: Container(
        width: size * 0.5,
        height: size * 0.5,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Color(0xFFF8F4E8),
          shape: BoxShape.circle,
        ),
        child: Text(
          '$id',
          style: TextStyle(
            fontSize: size * 0.3,
            height: 1,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1B1B1B),
          ),
        ),
      ),
    );
  }
}

/// 母球图标，用于自由球提示。
class CueBallChip extends StatelessWidget {
  const CueBallChip({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.35, -0.4),
          radius: 1.1,
          colors: [Colors.white, Color(0xFFF0EADA), Color(0xFFC9C1AE)],
        ),
        border: Border.all(color: Colors.black.withValues(alpha: 0.15)),
      ),
    );
  }
}
