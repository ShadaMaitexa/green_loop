import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';

enum PickupStatus { pending, assigned, in_progress, completed, cancelled }

/// A unified badge for displaying status text with corresponding semantic colors.
class GLStatusBadge extends StatelessWidget {
  final PickupStatus status;

  const GLStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg = Colors.white;
    String labelText;

    switch (status) {
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
