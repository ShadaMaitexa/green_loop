import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class ComponentsScreen extends StatelessWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;

  const ComponentsScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GLAppBar(
        title: 'GreenLeaf Components',
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: onToggleTheme,
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(GLSpacing.xl),
        children: const [
          _SectionTitle('Typography & Theme'),
          _TypographyShowcase(),
          _SectionTitle('GLButton Variants'),
          _ButtonShowcase(),
          _SectionTitle('GLCard & Input'),
          _CardAndInputShowcase(),
          _SectionTitle('GLStatusBadge'),
          _BadgeShowcase(),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: GLSpacing.xxl, bottom: GLSpacing.lg),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }
}

class _TypographyShowcase extends StatelessWidget {
  const _TypographyShowcase();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Display Large / മലയാളം വലിപ്പം', style: textTheme.displayLarge),
        const SizedBox(height: GLSpacing.md),
        Text('Headline Small / തലക്കെട്ട്', style: textTheme.headlineSmall),
        const SizedBox(height: GLSpacing.md),
        Text('Body Large / പ്രധാന വാചകം', style: textTheme.bodyLarge),
        const SizedBox(height: GLSpacing.md),
        Text('Label Large / ലേബൽ', style: textTheme.labelLarge),
      ],
    );
  }
}

class _ButtonShowcase extends StatelessWidget {
  const _ButtonShowcase();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: GLSpacing.md,
      runSpacing: GLSpacing.md,
      children: [
        GLButton(text: 'Primary', onPressed: () {}),
        GLButton(text: 'Secondary', variant: GLButtonVariant.secondary, onPressed: () {}),
        GLButton(text: 'Outline', variant: GLButtonVariant.outline, onPressed: () {}),
        GLButton(text: 'Ghost', variant: GLButtonVariant.ghost, onPressed: () {}),
        GLButton(text: 'With Icon', icon: Icons.recycling, onPressed: () {}),
        const GLButton(text: 'Loading', isLoading: true, onPressed: null),
        const GLButton(text: 'Disabled', onPressed: null),
      ],
    );
  }
}

class _CardAndInputShowcase extends StatelessWidget {
  const _CardAndInputShowcase();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GLCard(
          variant: GLCardVariant.elevated,
          header: Text(
            'Elevated Card',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          child: const GLTextField(
            label: 'Waste Type',
            hint: 'E.g., Plastic',
            prefixIcon: Icon(Icons.delete_outline),
          ),
          footer: GLButton(text: 'Submit Request', onPressed: () {}),
        ),
        const SizedBox(height: GLSpacing.xl),
        GLCard(
          variant: GLCardVariant.outlined,
          header: Text(
            'Outlined Card (Error State)',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          child: const GLTextField(
            label: 'Phone Number',
            hint: 'Enter your phone',
            errorText: 'Invalid number',
            prefixIcon: Icon(Icons.phone),
          ),
        ),
      ],
    );
  }
}

class _BadgeShowcase extends StatelessWidget {
  const _BadgeShowcase();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: GLSpacing.md,
      runSpacing: GLSpacing.md,
      children: const [
        GLStatusBadge(status: PickupStatus.pending),
        GLStatusBadge(status: PickupStatus.assigned),
        GLStatusBadge(status: PickupStatus.in_progress),
        GLStatusBadge(status: PickupStatus.completed),
        GLStatusBadge(status: PickupStatus.cancelled),
      ],
    );
  }
}
