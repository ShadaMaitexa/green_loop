import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import 'payment_state.dart';

class PaymentManagementScreen extends StatefulWidget {
  const PaymentManagementScreen({super.key});

  @override
  State<PaymentManagementScreen> createState() => _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends State<PaymentManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentState>().loadPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PaymentState>();

    return Padding(
      padding: const EdgeInsets.all(GLSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fee Collections',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            'View and manage user payments',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: GLSpacing.xl),
          Expanded(
            child: Card(
              child: state.isLoading && state.payments.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.payments.isEmpty
                      ? const Center(child: Text('No payments found'))
                      : ListView.separated(
                          itemCount: state.payments.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final payment = state.payments[index];
                            return ListTile(
                              leading: const Icon(Icons.receipt_long_rounded),
                              title: Text('Receipt: ${payment.receiptNumber}'),
                              subtitle: Text('Resident: ${payment.residentId ?? "N/A"}'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${payment.amount}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(payment.paymentMode.toJson()),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
