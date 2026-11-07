import 'package:flutter/material.dart';

/// 出杆控制：力度滑杆、瞄准微调与击球按钮。
///
/// 宽屏单行排布，窄屏两行排布；拖动滑杆只刷新控件自身，力度变化直接写入
/// 控制器，避免整页重建。
class PowerControl extends StatefulWidget {
  const PowerControl({
    super.key,
    required this.power,
    required this.onPowerChanged,
    required this.onAimLeft,
    required this.onAimRight,
    required this.onShoot,
    required this.canShoot,
    this.singleRow = false,
  });

  final double power;
  final ValueChanged<double> onPowerChanged;
  final VoidCallback? onAimLeft;
  final VoidCallback? onAimRight;
  final VoidCallback onShoot;
  final bool canShoot;
  final bool singleRow;

  @override
  State<PowerControl> createState() => _PowerControlState();
}

class _PowerControlState extends State<PowerControl> {
  late double _power = widget.power;

  @override
  void didUpdateWidget(covariant PowerControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.power != widget.power) _power = widget.power;
  }

  void _onPowerChanged(double value) {
    setState(() => _power = value);
    widget.onPowerChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final slider = Row(
      children: [
        Text('力度', style: theme.textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant)),
        const SizedBox(width: 6),
        Expanded(
          child: SizedBox(
            height: 40,
            child: Slider(
              value: _power,
              min: 0.05,
              onChanged: widget.canShoot ? _onPowerChanged : null,
              activeColor: colors.primary,
            ),
          ),
        ),
        SizedBox(
          width: 38,
          child: Text(
            '${(_power * 100).round()}%',
            textAlign: TextAlign.end,
            style: theme.textTheme.labelMedium,
          ),
        ),
      ],
    );
    final shoot = FilledButton.icon(
      onPressed: widget.canShoot ? widget.onShoot : null,
      icon: const Icon(Icons.sports_bar_outlined, size: 19),
      label: const Text('击 球'),
    );
    final aimLeft = AimButton(icon: Icons.rotate_left, onTap: widget.onAimLeft);
    final aimRight = AimButton(icon: Icons.rotate_right, onTap: widget.onAimRight);

    if (widget.singleRow) {
      return Row(
        children: [
          Expanded(child: slider),
          const SizedBox(width: 12),
          aimLeft,
          const SizedBox(width: 6),
          aimRight,
          const SizedBox(width: 10),
          SizedBox(width: 108, child: shoot),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        slider,
        const SizedBox(height: 2),
        Row(
          children: [
            aimLeft,
            const SizedBox(width: 6),
            aimRight,
            const SizedBox(width: 10),
            Expanded(child: shoot),
          ],
        ),
      ],
    );
  }
}

/// 瞄准微调按钮，左右对称的方形描边按钮。
class AimButton extends StatelessWidget {
  const AimButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(38, 38),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        child: Icon(icon, size: 19),
      ),
    );
  }
}
