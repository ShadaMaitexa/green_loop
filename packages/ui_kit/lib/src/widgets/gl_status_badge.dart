import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';

enum PickupStatus { pending, assigned, in_progress, completed, cancelled }

/// A unified badge for displaying status text with corresponding semantic colors.
///
/// Use [GLStatusBadge.fromStatus] (the default constructor) for enum-driven colors,
/// or [GLStatusBadge.custom] for a fully custom label/color badge.
class GLStatusBadge extends StatelessWidget {
  final PickupStatus? _status;
  final String? _customLabel;
  final Color? _backgroundColor;
  final Color? _textColor;

  const GLStatusBadge({
    super.key,
    required PickupStatus status,
  })  : _status = status,
        _customLabel = null,
        _backgroundColor = null,
        _textColor = null;

  const GLStatusBadge.custom({
    super.key,
    required String status,
    Color? backgroundColor,
    Color? textColor,
  })  : _status = null,
        _customLabel = status,
        _backgroundColor = backgroundColor,
        _textColor = textColor;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String labelText;

    if (_customLabel != null) {
      labelText = _customLabel;
      bg = _backgroundColor ?? GLColors.info;
      fg = _textColor ?? Colors.white;
    } else {
      fg = Colors.white;
      switch (_status!) {
        case PickupStatus.completed:
          bg = GLColors.success;
          labelText = 'Completed';
          break;
        case PickupStatus.pending:
          bg = Colors.grey;
          labelText = 'Pending';
          break;
        case PickupStatus.in_progress:
          bg = GLColors.info;
          labelText = 'In Progress';
          break;
        case PickupStatus.assigned:
          bg = GLColors.warning;
          labelText = 'Assigned';
          break;
        case PickupStatus.cancelled:
          bg = GLColors.error;
          labelText = 'Cancelled';
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GLSpacing.md,
        vertical: GLSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(GLRadius.xl), // Pill shape
      ),
      child: Text(
        labelText,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: fg,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
