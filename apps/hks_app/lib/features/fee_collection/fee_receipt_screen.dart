import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:data_models/data_models.dart';
import 'package:intl/intl.dart';

class FeeReceiptScreen extends StatelessWidget {
  final FeeCollection feeCollection;
  final HksPickup pickup;

  const FeeReceiptScreen({
    super.key,
    required this.feeCollection,
    required this.pickup,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUpi = feeCollection.paymentMode == PaymentMode.upi;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Receipt'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Receipt Card
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'GreenLoop HKS',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${feeCollection.amount.toStringAsFixed(2)}',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    _buildRow('Receipt No.', feeCollection.receiptNumber, theme),
                    const Divider(height: 32),
                    _buildRow('Date', DateFormat('dd MMM yyyy, hh:mm a').format(feeCollection.collectedAt), theme),
                    const Divider(height: 32),
                    _buildRow('Resident', pickup.residentName, theme),
                    const Divider(height: 32),
                    _buildRow('Payment Mode', isUpi ? 'UPI' : 'Cash', theme, isBold: true),
                    
                    if (isUpi) ...[
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Status', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                          const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                              SizedBox(width: 4),
                              Text('Paid', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                          )
                        ],
                      )
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GLButton(
                    text: 'Share Receipt',
                    icon: Icons.share_rounded,
                    variant: GLButtonVariant.outline,
                    onPressed: () {
                      // Share image logic (simulated for UI)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sharing receipt image...')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GLButton(
                    text: 'Done',
                    icon: Icons.check_rounded,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, ThemeData theme, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
