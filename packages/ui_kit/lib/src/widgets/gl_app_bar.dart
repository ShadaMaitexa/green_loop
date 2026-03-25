import 'package:flutter/material.dart';

import '../theme/spacing.dart';

/// App-wide standard AppBar handling custom routing actions and trailing icons properly aligned.
class GLAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  const GLAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
      ),
      centerTitle: centerTitle,
      leading: leading,
      actions: [
        if (actions != null) ...actions!,
        const SizedBox(width: GLSpacing.sm), // Safety margin for modern touch targets
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
