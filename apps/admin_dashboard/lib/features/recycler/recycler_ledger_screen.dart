import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class RecyclerLedgerScreen extends StatelessWidget {
  const RecyclerLedgerScreen({super.key});

  final List<_MaterialItem> _mockMaterials = const [
    _MaterialItem('Dry Waste (Mixed)', '₹4.50/kg', '1,240 kg', Icons.recycling_rounded, Color(0xFF4CAF50)),
    _MaterialItem('Wet Waste / Compost', '₹2.00/kg', '980 kg', Icons.eco_rounded, Color(0xFF2196F3)),
    _MaterialItem('E-Waste', '₹45.00/kg', '120 kg', Icons.devices_other_rounded, Color(0xFFFF9800)),
    _MaterialItem('Plastics (Hard)', '₹8.00/kg', '560 kg', Icons.local_drink_rounded, Color(0xFF9C27B0)),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Add Material'),
              ),
            ],
          ),
          const SizedBox(height: GLSpacing.xl),

          Text('Current Material Prices', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: GLSpacing.md),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 280,
              mainAxisExtent: 110,
              crossAxisSpacing: GLSpacing.md,
              mainAxisSpacing: GLSpacing.md,
            ),
            itemCount: _mockMaterials.length,
            itemBuilder: (context, i) {
              final m = _mockMaterials[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(GLSpacing.md),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: m.color.withOpacity(0.15),
                        child: Icon(m.icon, color: m.color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(m.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                            Text(m.price, style: theme.textTheme.titleMedium?.copyWith(color: m.color, fontWeight: FontWeight.bold)),
                            Text('Collected: ${m.volume}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
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
            child: Column(
              children: [
                _buildPurchaseRow(context, 'Recycler A', 'Dry Waste', '200 kg', '₹900', '2026-03-31'),
                const Divider(height: 1),
                _buildPurchaseRow(context, 'Green Collect Co.', 'E-Waste', '15 kg', '₹675', '2026-03-30'),
                const Divider(height: 1),
                _buildPurchaseRow(context, 'Recycler A', 'Plastics', '80 kg', '₹640', '2026-03-30'),
                const Divider(height: 1),
                _buildPurchaseRow(context, 'EcoSort Ltd.', 'Wet Waste', '120 kg', '₹240', '2026-03-29'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseRow(BuildContext context, String buyer, String material, String qty, String total, String date) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.store_rounded, size: 18)),
      title: Row(
        children: [
          Text(buyer, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(total, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))),
        ],
      ),
      subtitle: Row(
        children: [
          Text('$material  •  $qty'),
          const Spacer(),
          Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

class _MaterialItem {
  final String name;
  final String price;
  final String volume;
  final IconData icon;
  final Color color;

  const _MaterialItem(this.name, this.price, this.volume, this.icon, this.color);
}
