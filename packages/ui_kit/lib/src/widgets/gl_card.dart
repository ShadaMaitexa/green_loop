import 'package:flutter/material.dart';

import '../theme/spacing.dart';

enum GLCardVariant { elevated, outlined }

/// Reusable card component mapping GreenLeaf Theme metrics.
class GLCard extends StatelessWidget {
  final Widget? header;
  final Widget child;
  final Widget? footer;
  final GLCardVariant variant;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const GLCard({
    super.key,
    required this.child,
    this.header,
    this.footer,
    this.variant = GLCardVariant.elevated,
    this.padding = const EdgeInsets.all(GLSpacing.lg),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Apply specific parameters mapping to variant style.
    double elevation;
    ShapeBorder shape;

    switch (variant) {
      case GLCardVariant.elevated:
        elevation = theme.brightness == Brightness.dark ? 2.0 : 4.0;
        shape = RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GLRadius.lg),
        );
        break;
      case GLCardVariant.outlined:
        elevation = 0.0;
        shape = RoundedRectangleBorder(
          side: BorderSide(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(GLRadius.lg),
        );
        break;
    }

    Widget cardBody = Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header != null) ...[
            header!,
            const SizedBox(height: GLSpacing.md),
          ],
          child,
          if (footer != null) ...[
            const SizedBox(height: GLSpacing.md),
            footer!,
          ],
        ],
      ),
    );

    return Card(
      elevation: elevation,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              child: cardBody,
            )
          : cardBody,
    );
  }
}
