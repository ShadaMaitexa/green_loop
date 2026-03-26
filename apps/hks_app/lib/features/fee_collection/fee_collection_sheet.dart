import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:data_models/data_models.dart';
import 'package:core/core.dart';
import 'fee_receipt_screen.dart';

class FeeCollectionSheet extends StatefulWidget {
  final HksPickup pickup;

  const FeeCollectionSheet({super.key, required this.pickup});

  static void show(BuildContext context, HksPickup pickup) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: FeeCollectionSheet(pickup: pickup),
      ),
    );
  }

  @override
  State<FeeCollectionSheet> createState() => _FeeCollectionSheetState();
}

class _FeeCollectionSheetState extends State<FeeCollectionSheet> {
  final _amountController = TextEditingController();
  final _weightController = TextEditingController();
  PaymentMode _paymentMode = PaymentMode.cash;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    final weight = double.tryParse(_weightController.text);

    if (amount == null || amount <= 0) {
      setState(() => _error = 'Please enter a valid amount.');
      return;
    }

    if (weight == null || weight < 40.0) {
      setState(() => _error = 'Fee is only required for weight >= 40kg.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = context.read<HksRouteRepository>();
      final feeCollection = await repository.collectFee(
        pickupId: widget.pickup.id,
        amount: amount,
        paymentMode: _paymentMode,
      );

      if (mounted) {
        Navigator.pop(context); // close sheet
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FeeReceiptScreen(
              feeCollection: feeCollection,
              pickup: widget.pickup,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Collect Fee', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Resident: ${widget.pickup.residentName}', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),

          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Total Waste Weight (kg) *',
              border: OutlineInputBorder(),
              helperText: 'Must be ≥ 40kg to collect fee',
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount (₹) *',
              prefixText: '₹ ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          Text('Payment Mode', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<PaymentMode>(
                  title: const Text('Cash'),
                  value: PaymentMode.cash,
                  groupValue: _paymentMode,
                  onChanged: (val) => setState(() => _paymentMode = val!),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: RadioListTile<PaymentMode>(
                  title: const Text('UPI'),
                  value: PaymentMode.upi,
                  groupValue: _paymentMode,
                  onChanged: (val) => setState(() => _paymentMode = val!),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: GLButton(
              text: 'Submit Collection',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }
}
