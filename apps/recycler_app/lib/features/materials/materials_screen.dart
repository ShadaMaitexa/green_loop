import 'package:flutter/material.dart' hide MaterialType;
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:data_models/data_models.dart';
import '../recycler_state.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecyclerState>().fetchMaterials();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RecyclerState>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Accepted Materials'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => state.fetchMaterials(),
          ),
        ],
      ),
      body: state.isLoading && state.materials.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => state.fetchMaterials(),
              child: state.materials.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      padding: const EdgeInsets.all(GLSpacing.lg),
                      itemCount: state.materials.length,
                      itemBuilder: (context, index) {
                        final material = state.materials[index];
                        return _MaterialCard(
                          material: material,
                          onEdit: () => _showMaterialDialog(context, state, existing: material),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMaterialDialog(context, state),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Material'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 72, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: GLSpacing.lg),
          Text('No materials yet',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: GLSpacing.sm),
          Text('Tap + to add your first accepted material.',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  void _showMaterialDialog(BuildContext context, RecyclerState state,
      {MaterialType? existing}) {
    final nameController = TextEditingController(text: existing?.name);
    final descController = TextEditingController(text: existing?.description);
    final priceController =
        TextEditingController(text: existing?.currentPricePerKg.toString());
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(GLRadius.xl)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: GLSpacing.xl,
          right: GLSpacing.xl,
          top: GLSpacing.xl,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + GLSpacing.xl,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: GLSpacing.lg),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.outline.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                existing == null ? 'Add Material' : 'Edit Material',
                style: Theme.of(ctx).textTheme.headlineSmall,
              ),
              const SizedBox(height: GLSpacing.xl),
              GLTextField(
                label: 'Material Name',
                controller: nameController,
                hint: 'e.g. Cardboard, PET Plastic',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: GLSpacing.lg),
              GLTextField(
                label: 'Description',
                controller: descController,
                hint: 'Brief description of material type',
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Description is required'
                    : null,
              ),
              const SizedBox(height: GLSpacing.lg),
              GLTextField(
                label: 'Price per Kg (₹)',
                controller: priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixText: '₹ ',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Price is required';
                  if (double.tryParse(v.trim()) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: GLSpacing.xxl),
              GLButton(
                text: existing == null ? 'Add Material' : 'Save Changes',
                isLoading: state.isLoading,
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final type = MaterialType(
                    id: existing?.id ?? '',
                    name: nameController.text.trim(),
                    description: descController.text.trim(),
                    currentPricePerKg:
                        double.parse(priceController.text.trim()),
                  );
                  final success = existing == null
                      ? await state.addMaterial(type)
                      : await state.updateMaterial(type);

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(success
                          ? (existing == null
                              ? 'Material added successfully!'
                              : 'Material updated successfully!')
                          : 'Failed to save material. Please try again.'),
                      backgroundColor: success
                          ? Colors.green.shade700
                          : Theme.of(context).colorScheme.error,
                    ));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final MaterialType material;
  final VoidCallback onEdit;

  const _MaterialCard({required this.material, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: GLSpacing.md),
      elevation: GLElevation.low,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GLRadius.lg)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: GLSpacing.lg,
          vertical: GLSpacing.sm,
        ),
        leading: CircleAvatar(
          backgroundColor:
              theme.colorScheme.primaryContainer,
          child: Icon(Icons.recycling_rounded,
              color: theme.colorScheme.onPrimaryContainer, size: GLIconSize.md),
        ),
        title: Text(material.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(material.description,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${material.currentPricePerKg.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: theme.colorScheme.primary,
              ),
            ),
            Text('per Kg',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.outline)),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}
