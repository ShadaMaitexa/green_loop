import 'package:flutter/material.dart' hide MaterialType;
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:data_models/data_models.dart';
import '../recycler_state.dart';

class NewPurchaseScreen extends StatefulWidget {
  const NewPurchaseScreen({super.key});

  @override
  State<NewPurchaseScreen> createState() => _NewPurchaseScreenState();
}

class _NewPurchaseScreenState extends State<NewPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  
  MaterialType? _selectedMaterial;
  Ward? _selectedWard;
  final _weightController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _weightController.addListener(_calculateAmount);
  }

  void _calculateAmount() {
    if (_selectedMaterial != null && _weightController.text.isNotEmpty) {
      final weight = double.tryParse(_weightController.text) ?? 0.0;
      final total = weight * _selectedMaterial!.currentPricePerKg;
      _amountController.text = total.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RecyclerState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Record New Purchase')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(GLSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMaterialDropdown(state.materials),
              const SizedBox(height: GLSpacing.lg),
              _buildWardDropdown(state.wards),
              const SizedBox(height: GLSpacing.lg),
              GLTextField(
                label: 'Weight (Kg)',
                controller: _weightController,
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: GLSpacing.lg),
              GLTextField(
                label: 'Total Amount (₹)',
                controller: _amountController,
                keyboardType: TextInputType.number,
                readOnly: true,
                prefixText: '₹ ',
                helperText: 'Auto-calculated based on material price',
              ),
              const SizedBox(height: GLSpacing.xxl),
              GLButton(
                text: 'Save Purchase Record',
                onPressed: state.isLoading ? null : _savePurchase,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialDropdown(List<MaterialType> materials) {
    return DropdownButtonFormField<MaterialType>(
      decoration: const InputDecoration(labelText: 'Material Type'),
      value: _selectedMaterial,
      items: materials.map((m) => DropdownMenuItem(
        value: m,
        child: Text(m.name),
      )).toList(),
      onChanged: (val) {
        setState(() => _selectedMaterial = val);
        _calculateAmount();
      },
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  Widget _buildWardDropdown(List<Ward> wards) {
    return DropdownButtonFormField<Ward>(
      decoration: const InputDecoration(labelText: 'Source Ward'),
      value: _selectedWard,
      items: wards.map((w) => DropdownMenuItem(
        value: w,
        child: Text('${w.id} - ${w.nameEn}'),
      )).toList(),
      onChanged: (val) => setState(() => _selectedWard = val),
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  void _savePurchase() {
    if (_formKey.currentState!.validate() && _selectedMaterial != null && _selectedWard != null) {
      final purchase = RecyclerPurchase(
        materialTypeId: _selectedMaterial!.id,
        materialName: _selectedMaterial!.name,
        weightKg: double.parse(_weightController.text),
        totalAmount: double.parse(_amountController.text),
        sourceWardId: _selectedWard!.id,
        sourceWardName: _selectedWard!.nameEn,
        date: DateTime.now(),
      );
      
      context.read<RecyclerState>().addPurchase(purchase).then((success) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Purchase record saved successfully!')),
          );
          Navigator.pop(context);
        }
      });
    }
  }
}
