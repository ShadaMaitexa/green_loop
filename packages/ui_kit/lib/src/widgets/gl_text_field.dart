import 'package:flutter/material.dart';

import '../theme/spacing.dart';

/// App-wide standard TextField with labels, hints, and unified styling
class GLTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;

  const GLTextField({
    super.key,
    required this.label,
    this.hint,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.controller,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final outlineColor = isDark ? Colors.white30 : Colors.black26;

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(GLRadius.md),
      borderSide: BorderSide(color: outlineColor),
    );

    final errorBorder = border.copyWith(
      borderSide: BorderSide(color: colorScheme.error, width: 2),
    );

    final focusedBorder = border.copyWith(
      borderSide: BorderSide(color: colorScheme.primary, width: 2),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: GLSpacing.sm),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: isDark ? Colors.white10 : Colors.white,
            border: border,
            enabledBorder: border,
            focusedBorder: focusedBorder,
            errorBorder: errorBorder,
            focusedErrorBorder: errorBorder,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: GLSpacing.lg,
              vertical: GLSpacing.md,
            ),
          ),
        ),
      ],
    );
  }
}
