import 'package:flutter/material.dart';

import '../../core/practice_preset.dart';
import 'game_hud.dart';

/// 球台左上角的练习浮层：切换摆球、球型与重打上一杆。
class PracticeToolbar extends StatelessWidget {
  const PracticeToolbar({
    super.key,
    required this.editing,
    required this.canUndo,
    required this.onToggleEdit,
    required this.onUndo,
    this.onPreset,
    this.selectedPreset,
    this.translucent = false,
  });

  final bool editing;
  final bool canUndo;
  final VoidCallback onToggleEdit;
  final VoidCallback onUndo;
  final ValueChanged<PracticePreset>? onPreset;
  final PracticePreset? selectedPreset;

  /// 沉浸布局叠在球台上时只留 5% 底板。
  final bool translucent;

  Future<void> _pickPreset(BuildContext context) async {
    final preset = await showModalBottomSheet<PracticePreset>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(dense: true, title: Text('选择练习球型')),
            for (final item in PracticePreset.values)
              ListTile(
                dense: true,
                selected: item == selectedPreset,
                leading: const Icon(Icons.adjust, size: 20),
                title: Text(item.label),
                trailing: item == selectedPreset ? const Icon(Icons.check, size: 20) : null,
                onTap: () => Navigator.of(sheetContext).pop(item),
              ),
          ],
        ),
      ),
    );
    if (preset != null) onPreset?.call(preset);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToolChip(
          icon: editing ? Icons.check : Icons.open_with,
          label: editing ? '完成摆球' : '摆球',
          active: editing,
          onTap: onToggleEdit,
          translucent: translucent,
        ),
        const SizedBox(width: 6),
        _ToolChip(
          icon: Icons.grid_view,
          label: '球型',
          onTap: onPreset == null ? null : () => _pickPreset(context),
          translucent: translucent,
        ),
        const SizedBox(width: 6),
        _ToolChip(
          icon: Icons.undo,
          label: '重打',
          onTap: canUndo ? onUndo : null,
          translucent: translucent,
        ),
      ],
    );
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.translucent = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;
  final bool translucent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    final foreground = active
        ? colors.onPrimary
        : (enabled ? colors.onSurface : colors.onSurfaceVariant);
    return Material(
      color: active
          ? colors.primary
          : colors.surface.withValues(alpha: translucent ? HudSurface.immersiveOpacity : 0.92),
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: foreground),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
