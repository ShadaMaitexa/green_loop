import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:data_models/data_models.dart';
import '../recycler_state.dart';
import 'package:intl/intl.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecyclerState>().fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RecyclerState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, state),
          ),
        ],
      ),
      body: state.isLoading && state.history.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => state.fetchHistory(),
              child: ListView.builder(
                padding: const EdgeInsets.all(GLSpacing.lg),
                itemCount: state.history.length,
                itemBuilder: (context, index) {
                  final purchase = state.history[index];
                  return Card(
                    child: ListTile(
                      title: Text(purchase.materialName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '${DateFormat('MMM dd, yyyy HH:mm').format(purchase.date)}\nWeight: ${purchase.weightKg} Kg • Ward: ${purchase.sourceWardName}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹${purchase.totalAmount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          if (purchase.certificateUrl != null) 
                            const Icon(Icons.verified_rounded, color: Colors.green, size: 20),
                        ],
                      ),
                      onTap: () => _showPurchaseDetails(context, purchase),
                    ),
                  );
                },
              ),
            ),
    );
  }

  void _showPurchaseDetails(BuildContext context, RecyclerPurchase purchase) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(GLSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Purchase Detail', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: GLSpacing.lg),
            _DetailRow(label: 'Material', value: purchase.materialName),
            _DetailRow(label: 'Weight', value: '${purchase.weightKg} Kg'),
            _DetailRow(label: 'Date', value: DateFormat('MMM dd, yyyy HH:mm').format(purchase.date)),
            _DetailRow(label: 'Source Ward', value: purchase.sourceWardName),
            _DetailRow(label: 'Total Spent', value: '₹${purchase.totalAmount}'),
            const SizedBox(height: GLSpacing.xl),
            if (purchase.certificateUrl != null)
              GLButton(
                text: 'Download Certificate',
                onPressed: () {
                  // TODO: Open PDF
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening PDF...')));
                },
              )
            else
              const Chip(label: Text('PoR Not Ready'), backgroundColor: Colors.amberAccent),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context, RecyclerState state) {
    // Basic filter dialog setup - more fields can be added
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter History'),
        content: const Text('Filters apply via django-filter querystring parameters.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              state.fetchHistory();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GLSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text('$label:'), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))],
      ),
    );
  }
}
