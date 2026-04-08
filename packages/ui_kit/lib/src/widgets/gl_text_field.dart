import 'package:flutter/material.dart';

import '../theme/spacing.dart';

/// App-wide standard TextField with labels, hints, and unified styling
class GLTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool readOnly;
  final int maxLines;
  final String? prefixText;
  final String? helperText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final bool enabled;

  const GLTextField({
    super.key,
    required this.label,
    this.hint,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.prefixText,
    this.helperText,
    this.controller,
    this.keyboardType,
    this.onChanged,
    this.onTap,
    this.validator,
    this.enabled = true,
  });

  @override
  State<GLTextField> createState() => _GLTextFieldState();
}

class _GLTextFieldState extends State<GLTextField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  void _toggleObscure() {
    setState(() {
      _obscured = !_obscured;
    });
  }

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

    Widget? suffix = widget.suffixIcon;
    if (widget.obscureText && widget.suffixIcon == null) {
      suffix = IconButton(
        icon: Icon(
          _obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 20,
          color: colorScheme.onSurfaceVariant,
        ),
        onPressed: _toggleObscure,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: GLSpacing.sm),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscured,
          readOnly: widget.readOnly,
          maxLines: widget.maxLines,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          onTap: widget.onTap,
          validator: widget.validator,
          enabled: widget.enabled,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
            prefixText: widget.prefixText,
            helperText: widget.helperText,
            prefixIcon: widget.prefixIcon,
            suffixIcon: suffix,
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
