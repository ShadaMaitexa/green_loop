import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import '../recycler_state.dart';
import '../materials/materials_screen.dart';
import '../purchases/new_purchase_screen.dart';
import '../history/purchase_history_screen.dart';

class RecyclerDashboardScreen extends StatefulWidget {
  const RecyclerDashboardScreen({super.key});

  @override
  State<RecyclerDashboardScreen> createState() =>
      _RecyclerDashboardScreenState();
}

class _RecyclerDashboardScreenState extends State<RecyclerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecyclerState>().fetchDashboard();
      context.read<RecyclerState>().fetchMaterials();
      context.read<RecyclerState>().fetchWards();
      context.read<RecyclerState>().fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RecyclerState>();
    final dash = state.dashboardData;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          await state.fetchDashboard();
          await state.fetchHistory();
        },
        child: CustomScrollView(
          slivers: [
            // ── Gradient Header SliverAppBar ─────────────────────────────
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withGreen(
                          (theme.colorScheme.primary.green * 1.3).clamp(0, 255).toInt(),
                        ),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          GLSpacing.xl, GLSpacing.xl, GLSpacing.xl, GLSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    Colors.white.withOpacity(0.3),
                                child: const Icon(Icons.recycling_rounded,
                                    color: Colors.white),
                              ),
                              const SizedBox(width: GLSpacing.md),
                              Text(
                                'GreenLoop Recycler',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.refresh_rounded,
                                    color: Colors.white),
                                onPressed: () => state.fetchDashboard(),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            'Welcome back 👋',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Track your recycling operations below.',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                title: const Text('Dashboard'),
              ),
              actions: const [],
            ),

            SliverPadding(
              padding: const EdgeInsets.all(GLSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Stats Grid ────────────────────────────────────────────
                  _buildSectionLabel(context, 'Overview'),
                  const SizedBox(height: GLSpacing.md),
                  _buildStatsGrid(dash, state, context),

                  const SizedBox(height: GLSpacing.xxl),

                  // ── Quick Actions ─────────────────────────────────────────
                  _buildSectionLabel(context, 'Quick Actions'),
                  const SizedBox(height: GLSpacing.md),
                  _buildActionsRow(context),

                  const SizedBox(height: GLSpacing.xxl),

                  // ── Recent Purchases ──────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionLabel(context, 'Recent Purchases'),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PurchaseHistoryScreen()),
                        ),
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: GLSpacing.md),
                  _buildRecentPurchases(state, context),
                  const SizedBox(height: GLSpacing.xxl),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewPurchaseScreen()),
        ).then((_) {
          state.fetchDashboard();
          state.fetchHistory();
        }),
        label: const Text('New Purchase'),
        icon: const Icon(Icons.add_shopping_cart_rounded),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(label,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold));
  }

  Widget _buildStatsGrid(
      dynamic dash, RecyclerState state, BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: GLSpacing.md,
      mainAxisSpacing: GLSpacing.md,
      childAspectRatio: 1.45,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatCard(
          label: 'Total Weight',
          value: '${(dash?.totalWeightPurchased ?? 0).toStringAsFixed(1)} Kg',
          icon: Icons.scale_rounded,
          iconColor: Colors.blue.shade600,
          bgColor: Colors.blue.shade50,
        ),
        _StatCard(
          label: 'Total Spent',
          value: '₹${(dash?.totalSpent ?? 0).toStringAsFixed(0)}',
          icon: Icons.payments_rounded,
          iconColor: Colors.teal.shade600,
          bgColor: Colors.teal.shade50,
        ),
        _StatCard(
          label: 'Certs This Month',
          value: '${dash?.certificatesIssuedThisMonth ?? 0}',
          icon: Icons.verified_rounded,
          iconColor: Colors.amber.shade700,
          bgColor: Colors.amber.shade50,
        ),
        _StatCard(
          label: 'Materials',
          value: '${state.materials.length}',
          icon: Icons.category_rounded,
          iconColor: Colors.purple.shade600,
          bgColor: Colors.purple.shade50,
        ),
      ],
    );
  }

  Widget _buildActionsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            label: 'Materials',
            icon: Icons.inventory_2_rounded,
            description: 'View & edit',
            color: Colors.blue,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MaterialsScreen())),
          ),
        ),
        const SizedBox(width: GLSpacing.md),
        Expanded(
          child: _ActionCard(
            label: 'History',
            icon: Icons.receipt_long_rounded,
            description: 'Filter & download',
            color: Colors.teal,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PurchaseHistoryScreen())),
          ),
        ),
        const SizedBox(width: GLSpacing.md),
        Expanded(
          child: _ActionCard(
            label: 'Certificates',
            icon: Icons.workspace_premium_rounded,
            description: 'PoR PDFs',
            color: Colors.amber.shade700,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PurchaseHistoryScreen())),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentPurchases(RecyclerState state, BuildContext context) {
    if (state.isLoading && state.history.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(GLSpacing.xl),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(GLRadius.lg),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 40,
                  color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: GLSpacing.sm),
              Text('No purchases yet',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }
    return Column(
      children: state.history.take(3).map((p) {
        return Card(
          margin: const EdgeInsets.only(bottom: GLSpacing.sm),
          elevation: GLElevation.low,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(GLRadius.lg)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: GLSpacing.lg, vertical: GLSpacing.xs),
            leading: CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.primaryContainer,
              child: Icon(Icons.shopping_bag_rounded,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 20),
            ),
            title: Text(p.materialName ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${p.weightKg.toStringAsFixed(2)} Kg  •  ${p.sourceWardName ?? 'Unknown'}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${p.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (p.certificateUrl != null)
                  Icon(Icons.verified_rounded,
                      color: Colors.green.shade600, size: 14),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Reusable Widgets ──────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: GLElevation.low,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GLRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.all(GLSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(GLSpacing.sm),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(GLRadius.md),
              ),
              child: Icon(icon, color: iconColor, size: GLIconSize.md),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(
                            color: Theme.of(context).colorScheme.outline)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GLRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(GLSpacing.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(GLRadius.lg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: GLIconSize.lg),
            const SizedBox(height: GLSpacing.sm),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color, fontSize: 12),
                textAlign: TextAlign.center),
            Text(description,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Theme.of(context).colorScheme.outline),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
