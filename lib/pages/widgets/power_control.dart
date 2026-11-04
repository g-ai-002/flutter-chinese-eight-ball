import 'package:flutter/material.dart';

/// 出杆控制：力度滑杆、瞄准微调与击球按钮。
class PowerControl extends StatelessWidget {
  const PowerControl({
    super.key,
    required this.power,
    required this.onPowerChanged,
    required this.onAimLeft,
    required this.onAimRight,
    required this.onShoot,
    required this.canShoot,
    required this.hint,
    this.compact = false,
  });

  final double power;
  final ValueChanged<double> onPowerChanged;
  final VoidCallback? onAimLeft;
  final VoidCallback? onAimRight;
  final VoidCallback onShoot;
  final bool canShoot;
  final String hint;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (compact && hint.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              hint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        Row(
          children: [
            Text(
              '力度',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Slider(
                value: power,
                min: 0.05,
                onChanged: canShoot ? onPowerChanged : null,
                activeColor: colors.primary,
              ),
            ),
            SizedBox(
              width: 40,
              child: Text(
                '${(power * 100).round()}%',
                textAlign: TextAlign.end,
                style: theme.textTheme.labelMedium,
              ),
            ),
          ],
        ),
        if (compact)
          Row(
            children: [
              _AimButton(icon: Icons.rotate_left, onTap: onAimLeft),
              const SizedBox(width: 6),
              _AimButton(icon: Icons.rotate_right, onTap: onAimRight),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: canShoot ? onShoot : null,
                  icon: const Icon(Icons.sports_bar_outlined, size: 20),
                  label: const Text('击 球'),
                ),
              ),
            ],
          )
        else ...[
          const SizedBox(height: 4),
          Row(
            children: [
              _AimButton(icon: Icons.rotate_left, onTap: onAimLeft),
              const SizedBox(width: 6),
              _AimButton(icon: Icons.rotate_right, onTap: onAimRight),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: canShoot ? onShoot : null,
            icon: const Icon(Icons.sports_bar_outlined, size: 20),
            label: const Text('击 球'),
          ),
        ],
      ],
    );
  }
}

class _AimButton extends StatelessWidget {
  const _AimButton({required this.icon, required this.onTap});

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
