import 'package:flutter/material.dart';

import '../../theme/table_skin.dart';

/// 迷你球图标：与台面球体配色一致，花色球白色球身配彩色球带。
///
/// 号码白底缩到球径的 43%，球带占球径的 54% 且边缘清晰，缩小到 18 像素时
/// 仍能一眼区分花色球与全色球。
class BallChip extends StatelessWidget {
  const BallChip({super.key, required this.id, this.size = 20});

  final int id;
  final double size;

  static const Color _ivory = Color(0xFFF8F4E8);

  @override
  Widget build(BuildContext context) {
    final base = ballColorOf(id);
    final isStripe = id >= 9 && id <= 15;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
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
            ? RadialGradient(
                center: const Alignment(-0.35, -0.4),
                radius: 1.1,
                colors: [_ivory, _ivory, Color.lerp(_ivory, Colors.black, 0.18)!],
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
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isStripe)
              Center(
                child: FractionallySizedBox(
                  heightFactor: 0.54,
                  widthFactor: 1.0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(base, Colors.white, 0.35)!,
                          base,
                          Color.lerp(base, Colors.black, 0.35)!,
                        ],
                        stops: const [0, 0.55, 1],
                      ),
                    ),
                  ),
                ),
              ),
            Center(
              child: Container(
                width: size * 0.43,
                height: size * 0.43,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _ivory,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black.withValues(alpha: 0.12), width: 0.5),
                ),
                child: Text(
                  '$id',
                  style: TextStyle(
                    fontSize: size * 0.28,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B1B1B),
                  ),
                ),
              ),
            ),
          ],
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
