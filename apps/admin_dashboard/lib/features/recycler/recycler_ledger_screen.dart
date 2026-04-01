import 'package:flutter/material.dart';
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
                    Text('Recycler Ledger', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Material prices & purchase history from recyclers', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
                  ],
                ),
              ),
              GLButton(
                text: 'Add Material',
                onPressed: () => _showAddMaterialDialog(context),
                icon: Icons.add,
              ),
            ],
          ),
          const SizedBox(height: GLSpacing.xl),

          Text('Current Material Prices', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: GLSpacing.md),
          if (state.materialTypes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(GLSpacing.xl),
              child: Center(child: Text('No material types defined')),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                mainAxisExtent: 120,
                crossAxisSpacing: GLSpacing.md,
                mainAxisSpacing: GLSpacing.md,
              ),
              itemCount: state.materialTypes.length,
              itemBuilder: (context, i) {
                final m = state.materialTypes[i];
                final color = _getMaterialColor(m.name);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(GLSpacing.md),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: color.withOpacity(0.15),
                          child: Icon(_getMaterialIcon(m.name), color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(m.name, 
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text('₹${m.currentPricePerKg.toStringAsFixed(2)}/kg', 
                                style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold)
                              ),
                              Text(m.description, 
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: GLSpacing.xl),
          Text('Recent Purchases', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: GLSpacing.md),
          Card(
            child: state.purchases.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(GLSpacing.xl),
                    child: Center(child: Text('No recent purchases')),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.purchases.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final p = state.purchases[index];
                      return _buildPurchaseRow(context, p);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseRow(BuildContext context, RecyclerPurchase p) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.store_rounded, size: 18)),
      title: Row(
        children: [
          Text(p.sourceWardName ?? 'Ward ${p.sourceWardId}', style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(currencyFormat.format(p.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))),
        ],
      ),
      subtitle: Row(
        children: [
          Text('${p.materialName ?? "Material"}  •  ${p.weightKg.toStringAsFixed(1)} kg'),
          const Spacer(),
          Text(DateFormat('yyyy-MM-dd').format(p.date), style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
    return Colors.blueGrey;
  }

  IconData _getMaterialIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('plastic')) return Icons.local_drink_rounded;
    if (n.contains('dry')) return Icons.recycling_rounded;
    if (n.contains('wet')) return Icons.eco_rounded;
    if (n.contains('e-waste')) return Icons.devices_other_rounded;
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
}

