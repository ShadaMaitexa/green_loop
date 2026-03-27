import 'package:flutter/material.dart';
import '../admin_dashboard_screen.dart';
import 'package:ui_kit/ui_kit.dart';

class SidebarDrawer extends StatelessWidget {
  final List<DashboardSection> sections;
  final int selectedIndex;
  final ValueChanged<int> onSectionSelected;
  final bool isPersistent;

  const SidebarDrawer({
    super.key,
    required this.sections,
    required this.selectedIndex,
    required this.onSectionSelected,
    this.isPersistent = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          _buildHeader(context),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                vertical: GLSpacing.md,
                horizontal: GLSpacing.sm,
              ),
              itemCount: sections.length,
              itemBuilder: (context, index) {
                final section = sections[index];
                final isSelected = selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: GLSpacing.xs),
                  child: ListTile(
                    selected: isSelected,
                    selectedTileColor: theme.colorScheme.primaryContainer.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(GLSpacing.sm),
                    ),
                    leading: Icon(
                      section.icon,
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      section.title,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                      ),
                    ),
                    onTap: () => onSectionSelected(index),
                  ),
                );
              },
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    if (isPersistent) return const SizedBox(height: GLSpacing.xl);

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: GLSpacing.xl,
        horizontal: GLSpacing.lg,
      ),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco_rounded, color: Colors.green, size: 32),
              const SizedBox(width: GLSpacing.sm),
              Text(
                'GreenLoop',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(GLSpacing.lg),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: GLSpacing.md),
          Row(
            children: [
              const Icon(Icons.help_outline_rounded, size: 20),
              const SizedBox(width: GLSpacing.md),
              const Text('Support Center'),
            ],
          ),
        ],
      ),
    );
  }
}
