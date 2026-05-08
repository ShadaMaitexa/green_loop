import 'package:flutter/material.dart' hide MaterialType;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:data_models/data_models.dart';
import 'recycler_state.dart';

class RecyclerLedgerScreen extends StatefulWidget {
  const RecyclerLedgerScreen({super.key});

  @override
  State<RecyclerLedgerScreen> createState() => _RecyclerLedgerScreenState();
}

class _RecyclerLedgerScreenState extends State<RecyclerLedgerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecyclerState>().loadLedger();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RecyclerState>();
    final theme = Theme.of(context);

    if (state.isLoading && (state.materialTypes.isEmpty && state.purchases.isEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.materialTypes.isEmpty) {
      return Center(child: Text('Error: ${state.error}'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(GLSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recycler Administration', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                    const SizedBox(height: 4),
                    Text('Manage material pricing, verify recycler certificates & monitor city-wide transactions', 
                      style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600])
                    ),
                  ],
                ),
              ),
              GLButton(
                text: 'Add Waste Category',
                onPressed: () => _showAddMaterialDialog(context),
                icon: Icons.add_circle_outline_rounded,
              ),
            ],
          ),
          const SizedBox(height: GLSpacing.xl),

          // --- Stats Overview ---
           Row(
            children: [
              _buildStatCard(context, 'Total Recycling Volume', '${state.totalWeight.toStringAsFixed(1)} kg', Icons.auto_graph_rounded, Colors.green),
              const SizedBox(width: GLSpacing.md),
              _buildStatCard(context, 'Total Market Value', '₹${state.totalSpent.toStringAsFixed(0)}', Icons.payments_rounded, Colors.blue),
              const SizedBox(width: GLSpacing.md),
              _buildStatCard(context, 'Pending Verifications', state.pendingCount.toString(), Icons.verified_user_rounded, Colors.orange),
              const SizedBox(width: GLSpacing.md),
              _buildStatCard(context, 'Waste Categories', state.totalMaterials.toString(), Icons.inventory_2_rounded, Colors.purple),
            ],
          ),
          const SizedBox(height: GLSpacing.xxl),

          if (state.pendingCertificates.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.pending_actions_rounded, color: Colors.orange, size: 28),
                const SizedBox(width: 12),
                Text('Verification Requests', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: GLSpacing.md),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.pendingCertificates.length,
              itemBuilder: (context, index) {
                final cert = state.pendingCertificates[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: GLSpacing.sm),
                  elevation: 0,
                  color: Colors.orange.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.orange.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(GLSpacing.md),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(GLSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.description, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cert.recyclerName ?? "Registered Recycler", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('CSR Certificate #${cert.id}  •  Requested on ${cert.dateRequested != null ? DateFormat('MMM d, yyyy').format(cert.dateRequested!) : "Recently"}',
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        if (cert.certificateUrl != null && cert.certificateUrl!.isNotEmpty)
                          TextButton.icon(
                            onPressed: () { /* Future: Download or Open PDF */ }, 
                            icon: const Icon(Icons.open_in_new_rounded, size: 18),
                            label: const Text('Review Docs'),
                          ),
                        const SizedBox(width: 8),
                        GLButton(
                          text: 'Verify & Approve',
                          onPressed: () async {
                            final success = await context.read<RecyclerState>().verifyCertificate(cert.id);
                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Certificate verified and status updated to VERIFIED!')));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: GLSpacing.xxl),
          ],

          Row(
            children: [
              const Icon(Icons.local_offer_rounded, color: Colors.blue, size: 28),
              const SizedBox(width: 12),
              Text('Master Catalog & Material Pricing', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: GLSpacing.md),
          if (state.materialTypes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(GLSpacing.xl),
              child: Center(child: Text('No material types defined in Master Catalog')),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                mainAxisExtent: 140,
                crossAxisSpacing: GLSpacing.md,
                mainAxisSpacing: GLSpacing.md,
              ),
              itemCount: state.materialTypes.length,
              itemBuilder: (context, i) {
                final m = state.materialTypes[i];
                final color = _getMaterialColor(m.name);
                return Card(
                  elevation: 0,
                  color: color.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: color.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(GLSpacing.md),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(GLSpacing.md),
                    onTap: () => _showEditMaterialDialog(context, m),
                    child: Padding(
                      padding: const EdgeInsets.all(GLSpacing.lg),
                      child: Row(
                        children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                          child: Icon(_getMaterialIcon(m.name), color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(m.name, 
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text('Current Market Price', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              Text('₹${m.currentPricePerKg.toStringAsFixed(2)} / kg', 
                                style: theme.textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.bold)
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.edit_note_rounded, color: Colors.grey),
                      ],
                    ),
                  ),
                ));
              },
            ),

          const SizedBox(height: GLSpacing.xxl),
          Row(
            children: [
              const Icon(Icons.history_rounded, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              Text('Global Recycling Transactions', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.download_rounded), label: const Text('Export History')),
            ],
          ),
          const SizedBox(height: GLSpacing.md),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GLSpacing.md)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: GLSpacing.sm),
              child: state.purchases.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(GLSpacing.xl),
                      child: Center(child: Text('No city-wide transactions recorded yet')),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.purchases.length,
                      separatorBuilder: (_, __) => const Divider(indent: 70),
                      itemBuilder: (context, index) {
                        final p = state.purchases[index];
                        return _buildPurchaseRow(context, p);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GLSpacing.md),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(GLSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseRow(BuildContext context, RecyclerPurchase p) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final materialColor = _getMaterialColor(p.materialName ?? "");
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: materialColor.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(_getMaterialIcon(p.materialName ?? ""), color: materialColor, size: 20),
      ),
      title: Row(
        children: [
          Text(p.sourceWardName ?? 'Ward ${p.sourceWardId}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(currencyFormat.format(p.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))),
        ],
      ),
      subtitle: Row(
        children: [
          Text('${p.materialName ?? "General Waste"}  •  ${p.weightKg.toStringAsFixed(1)} kg'),
          const Spacer(),
          Text(DateFormat('MMM d, yyyy').format(p.date), style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Color _getMaterialColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('plastic')) return Colors.purple;
    if (n.contains('dry')) return Colors.green;
    if (n.contains('wet')) return Colors.blue;
    if (n.contains('e-waste')) return Colors.orange;
    if (n.contains('medical')) return Colors.red;
    return Colors.blueGrey;
  }

  IconData _getMaterialIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('plastic')) return Icons.local_drink_rounded;
    if (n.contains('dry')) return Icons.recycling_rounded;
    if (n.contains('wet')) return Icons.eco_rounded;
    if (n.contains('e-waste')) return Icons.devices_other_rounded;
    if (n.contains('medical')) return Icons.medical_services_rounded;
    return Icons.category_rounded;
  }

  void _showAddMaterialDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Material Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GLTextField(label: 'Name', controller: nameController),
            const SizedBox(height: GLSpacing.md),
            GLTextField(label: 'Price per Kg', controller: priceController, keyboardType: TextInputType.number),
            const SizedBox(height: GLSpacing.md),
            GLTextField(label: 'Description', controller: descController),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          GLButton(
            text: 'Save',
            onPressed: () async {
              final success = await context.read<RecyclerState>().addMaterial({
                'name': nameController.text,
                'price_per_kg': double.tryParse(priceController.text) ?? 0.0,
                'description': descController.text,
              });
              if (success && mounted && context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showEditMaterialDialog(BuildContext context, MaterialType material) {
    final nameController = TextEditingController(text: material.name);
    final priceController = TextEditingController(text: material.currentPricePerKg.toString());
    final descController = TextEditingController(text: material.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Material Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GLTextField(label: 'Name', controller: nameController),
            const SizedBox(height: GLSpacing.md),
            GLTextField(label: 'Price per Kg', controller: priceController, keyboardType: TextInputType.number),
            const SizedBox(height: GLSpacing.md),
            GLTextField(label: 'Description', controller: descController),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          GLButton(
            text: 'Update',
            onPressed: () async {
              final success = await context.read<RecyclerState>().updateMaterial(material.id, {
                'name': nameController.text,
                'price_per_kg': double.tryParse(priceController.text) ?? material.currentPricePerKg,
                'description': descController.text,
              });
              if (success && mounted && context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
