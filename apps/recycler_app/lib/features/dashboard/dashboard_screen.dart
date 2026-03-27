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
  State<RecyclerDashboardScreen> createState() => _RecyclerDashboardScreenState();
}

class _RecyclerDashboardScreenState extends State<RecyclerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecyclerState>().fetchDashboard();
      context.read<RecyclerState>().fetchMaterials();
      context.read<RecyclerState>().fetchWards();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RecyclerState>();
    final dash = state.dashboardData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycler Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => state.fetchDashboard(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => state.fetchDashboard(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(GLSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsGrid(dash, context),
              const SizedBox(height: GLSpacing.xxl),
              _buildActionsSection(context),
              const SizedBox(height: GLSpacing.xxl),
              _buildQuickHistory(state, context),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewPurchaseScreen()),
        ),
        label: const Text('New Purchase'),
        icon: const Icon(Icons.add_shopping_cart),
      ),
    );
  }

  Widget _buildStatsGrid(dynamic dash, BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: GLSpacing.md,
      mainAxisSpacing: GLSpacing.md,
      childAspectRatio: 1.5,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatCard(
          label: 'Total Weight',
          value: '${dash?.totalWeightPurchased ?? 0} Kg',
          icon: Icons.scale_rounded,
          color: Colors.blue,
        ),
        _StatCard(
          label: 'Total Spent',
          value: '₹${dash?.totalSpent ?? 0}',
          icon: Icons.payments_rounded,
          color: Colors.teal,
        ),
        _StatCard(
          label: 'Certificates Month',
          value: '${dash?.certificatesIssuedThisMonth ?? 0}',
          icon: Icons.verified_rounded,
          color: Colors.amber,
        ),
        _StatCard(
          label: 'Materials',
          value: '${context.watch<RecyclerState>().materials.length}',
          icon: Icons.category_rounded,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: GLSpacing.md),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                label: 'Materials',
                icon: Icons.inventory_2_rounded,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MaterialsScreen()),
                ),
              ),
            ),
            const SizedBox(width: GLSpacing.md),
            Expanded(
              child: _ActionCard(
                label: 'History',
                icon: Icons.history_rounded,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PurchaseHistoryScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickHistory(RecyclerState state, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Purchases', style: Theme.of(context).textTheme.titleLarge),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PurchaseHistoryScreen()),
              ),
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: GLSpacing.md),
        if (state.history.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(GLSpacing.xl),
            child: Text('No recent purchases.'),
          ))
        else
          ...state.history.take(3).map((p) => ListTile(
            title: Text(p.materialName),
            subtitle: Text('${p.weightKg} Kg • ${p.sourceWardName}'),
            trailing: Text('₹${p.totalAmount}', style: const TextStyle(fontWeight: FontWeight.bold)),
          )),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(GLSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: GLSpacing.xs),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(GLSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 32),
            const SizedBox(height: GLSpacing.md),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
