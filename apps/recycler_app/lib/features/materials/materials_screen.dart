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

    return Scaffold(
      appBar: AppBar(title: const Text('Accepted Materials')),
      body: state.isLoading && state.materials.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => state.fetchMaterials(),
              child: ListView.builder(
                padding: const EdgeInsets.all(GLSpacing.lg),
                itemCount: state.materials.length,
                itemBuilder: (context, index) {
                  final material = state.materials[index];
                  return Card(
                    child: ListTile(
                      title: Text(material.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(material.description),
                      trailing: Text(
                        '₹${material.currentPricePerKg}/Kg',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                      onTap: () => _editMaterialDialog(context, material),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editMaterialDialog(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _editMaterialDialog(BuildContext context, MaterialType? material) {
    final nameController = TextEditingController(text: material?.name);
    final descController = TextEditingController(text: material?.description);
    final priceController = TextEditingController(text: material?.currentPricePerKg.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(material == null ? 'Add Material' : 'Edit Material'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GLTextField(label: 'Material Name', controller: nameController),
            const SizedBox(height: GLSpacing.md),
            GLTextField(label: 'Description', controller: descController),
            const SizedBox(height: GLSpacing.md),
            GLTextField(label: 'Price per Kg (₹)', controller: priceController, keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              // TODO: Implement actual save - for now just UI
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
