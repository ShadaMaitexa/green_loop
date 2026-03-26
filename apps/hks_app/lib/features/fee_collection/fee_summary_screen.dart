import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:data_models/data_models.dart';
import 'package:core/core.dart';

class FeeSummaryScreen extends StatefulWidget {
  const FeeSummaryScreen({super.key});

  @override
  State<FeeSummaryScreen> createState() => _FeeSummaryScreenState();
}

class _FeeSummaryScreenState extends State<FeeSummaryScreen> {
  bool _isLoading = true;
  DailyFeeSummary? _summary;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    try {
      final repository = context.read<HksRouteRepository>();
      final summary = await repository.getFeeSummary();
      if (mounted) {
        setState(() {
          _summary = summary;
          _isLoading = false;
        });
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Fee Summary'),
        elevation: 0,
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Could not load summary: $_error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 24),
              GLButton(text: 'Retry', onPressed: _fetchSummary),
            ],
          ),
        ),
      );
    }

    if (_summary == null) {
      return const Center(child: Text('No collection data for today.'));
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Total Collected Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.account_balance_wallet_rounded, size: 48, color: Colors.white70),
                const SizedBox(height: 16),
                const Text(
                  'Total Collected Today',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  '₹${_summary!.totalCollected.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'From ${_summary!.numberHouseholds} households',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Breakdown by Payment Mode',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildBreakdownCard('Cash', _summary!.cashCollected, Icons.money_rounded, Colors.green),
          const SizedBox(height: 12),
          _buildBreakdownCard('UPI', _summary!.upiCollected, Icons.qr_code_2_rounded, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(String title, double amount, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
