import 'package:flutter/material.dart';

import '../theme/spacing.dart';

enum GLButtonVariant { primary, secondary, outline, ghost }
enum GLButtonSize { small, medium, large }

/// GLButton supporting variants, sizes, and loading state.
class GLButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final GLButtonVariant variant;
  final GLButtonSize size;
  final bool isLoading;
  final IconData? icon;

  const GLButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = GLButtonVariant.primary,
    this.size = GLButtonSize.medium,
    this.isLoading = false,
    this.icon,
  });

  bool get _isDisabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    Color fg;
    Color bg;
    BorderSide? border;

    switch (variant) {
      case GLButtonVariant.primary:
        bg = colorScheme.primary;
        fg = colorScheme.onPrimary;
        break;
      case GLButtonVariant.secondary:
        bg = colorScheme.secondary;
        fg = colorScheme.onSecondary;
        break;
      case GLButtonVariant.outline:
        bg = Colors.transparent;
        fg = colorScheme.primary;
        border = BorderSide(color: colorScheme.primary);
        break;
      case GLButtonVariant.ghost:
        bg = Colors.transparent;
        fg = colorScheme.primary;
        break;
    }

    if (_isDisabled) {
      bg = isDark ? Colors.white12 : Colors.black12;
      fg = isDark ? Colors.white38 : Colors.black38;
      if (variant == GLButtonVariant.outline) {
        bg = Colors.transparent;
        border = BorderSide(color: fg);
      } else if (variant == GLButtonVariant.ghost) {
        bg = Colors.transparent;
      }
    }

    double height;
    double? fontSize;
    double iconSize;
    EdgeInsets padding;

    switch (size) {
      case GLButtonSize.small:
        height = 32.0;
        fontSize = 12.0;
        iconSize = 16.0;
        padding = const EdgeInsets.symmetric(horizontal: GLSpacing.md);
        break;
      case GLButtonSize.medium:
        height = 48.0;
        fontSize = 14.0;
        iconSize = 20.0;
        padding = const EdgeInsets.symmetric(horizontal: GLSpacing.lg);
        break;
      case GLButtonSize.large:
        height = 56.0;
        fontSize = 16.0;
        iconSize = 24.0;
        padding = const EdgeInsets.symmetric(horizontal: GLSpacing.xl);
        break;
    }

    final buttonStyle = ButtonStyle(
      minimumSize: WidgetStateProperty.all(Size(0, height)),
      backgroundColor: WidgetStateProperty.all(bg),
      foregroundColor: WidgetStateProperty.all(fg),
      side: WidgetStateProperty.all(border),
      padding: WidgetStateProperty.all(padding),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GLRadius.md),
        ),
      ),
      elevation: WidgetStateProperty.all(
        variant == GLButtonVariant.primary || variant == GLButtonVariant.secondary
            ? (_isDisabled ? 0 : 2)
            : 0,
      ),
    );

    Widget child = Text(
      text,
      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
    );

    if (isLoading) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
          const SizedBox(width: GLSpacing.sm),
          child,
        ],
      );
    } else if (icon != null) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize),
          const SizedBox(width: GLSpacing.sm),
          child,
        ],
      );
    }

    return TextButton(
      style: buttonStyle,
      onPressed: _isDisabled ? null : onPressed,
      child: child,
    );
  }
}
