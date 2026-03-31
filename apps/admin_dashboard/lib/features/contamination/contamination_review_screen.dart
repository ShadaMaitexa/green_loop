import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class ContaminationReviewScreen extends StatelessWidget {
  const ContaminationReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(GLSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contamination Review', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('AI flagged waste quality control', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: GLSpacing.xl),
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline, color: Colors.blue),
                title: Text('Review Queue'),
                subtitle: Text('Items flagged by the HKS mobile app AI module.'),
              ),
            ),
            const SizedBox(height: GLSpacing.xl),
            Center(
              child: Column(
                children: [
                   const Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
                   const SizedBox(height: 16),
                   Text('Queue Clean!', style: Theme.of(context).textTheme.titleLarge),
                   const Text('No pending contamination reports at this time.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
