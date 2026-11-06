import 'package:flutter/material.dart';

import '../../core/practice_preset.dart';

/// 球台左上角的练习浮层：切换摆球、球型与重打上一杆。
class PracticeToolbar extends StatelessWidget {
  const PracticeToolbar({
    super.key,
    required this.editing,
    required this.canUndo,
    required this.onToggleEdit,
    required this.onUndo,
    this.onPreset,
  });

  final bool editing;
  final bool canUndo;
  final VoidCallback onToggleEdit;
  final VoidCallback onUndo;
  final ValueChanged<PracticePreset>? onPreset;

  Future<void> _pickPreset(BuildContext context) async {
    final preset = await showModalBottomSheet<PracticePreset>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(dense: true, title: Text('选择练习球型')),
            for (final item in PracticePreset.values)
              ListTile(
                dense: true,
                leading: const Icon(Icons.adjust, size: 20),
                title: Text(item.label),
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
        ),
        const SizedBox(width: 6),
        _ToolChip(
          icon: Icons.grid_view,
          label: '球型',
          onTap: onPreset == null ? null : () => _pickPreset(context),
        ),
        const SizedBox(width: 6),
        _ToolChip(
          icon: Icons.undo,
          label: '重打',
          onTap: canUndo ? onUndo : null,
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
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    final foreground = active
        ? colors.onPrimary
        : (enabled ? colors.onSurface : colors.onSurfaceVariant);
    return Material(
      color: active ? colors.primary : colors.surface.withValues(alpha: 0.92),
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
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
