import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:auth/auth.dart';
import '../../complaints/complaint_state.dart';
import 'package:data_models/data_models.dart';

class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;

  const AdminAppBar({
    super.key,
    this.showMenuButton = false,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.select<AuthState, AuthUser?>((s) => s.user);

    return AppBar(
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      leading: showMenuButton
          ? IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: onMenuPressed,
            )
          : const Padding(
              padding: EdgeInsets.all(GLSpacing.sm),
              child: Icon(
                Icons.eco_rounded,
                color: Colors.green,
                size: 32,
              ),
            ),
      title: Text(
        'GreenLoop Admin',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
      actions: [
        Consumer<ComplaintState>(
          builder: (context, state, _) {
            final pendingCount = state.complaints.where((c) => c.status != ComplaintStatus.resolved).length;
            
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: () {
                    // Navigate to complaints or show dropdown
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('You have $pendingCount active attention items.')),
                    );
                  },
                ),
                if (pendingCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$pendingCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: GLSpacing.md),
        PopupMenuButton<String>(
          offset: const Offset(0, 56),
          onSelected: (value) {
            if (value == 'logout') {
              context.read<AuthState>().logout();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.name ?? 'Administrator',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user?.role ?? 'ULB Admin',
                    style: theme.textTheme.bodySmall,
                  ),
                  const Divider(),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, size: 20, color: Colors.red),
                  SizedBox(width: GLSpacing.sm),
                  Text('Logout', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          child: CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              (user?.name ?? 'Admin').substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: GLSpacing.md),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
