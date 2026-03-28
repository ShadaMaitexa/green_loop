import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:data_models/data_models.dart';
import 'package:intl/intl.dart';
import 'reports_state.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = now;
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
      // Clear previous report
      if (mounted) {
        context.read<ReportsState>().clearReport();
      }
    }
  }

  void _generateReport() {
    if (_startDate != null && _endDate != null) {
      context.read<ReportsState>().generateSuchitwaReport(_startDate!, _endDate!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date range first.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ReportsState>();
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Padding(
      padding: EdgeInsets.all(isDesktop ? GLSpacing.xxl : GLSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Suchitwa Mission Compliance',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              GLButton(
                text: 'Export PDF',
                icon: Icons.picture_as_pdf_rounded,
                variant: GLButtonVariant.outline,
                onPressed: state.currentReport != null
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Export functionality coming soon!')),
                        );
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: GLSpacing.lg),
          _buildControls(context, state),
          const SizedBox(height: GLSpacing.lg),
          if (state.isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (state.error != null)
            Expanded(
              child: Center(
                child: Text(
                  state.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            )
          else if (state.currentReport != null)
            Expanded(
              child: SingleChildScrollView(
                child: _buildReport(context, state.currentReport!),
              ),
            )
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.analytics_rounded,
                      size: 64,
                      color: theme.colorScheme.outline.withOpacity(0.5),
                    ),
                    const SizedBox(height: GLSpacing.md),
                    Text(
                      'Select a date range and click Generate Report',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, ReportsState state) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(GLRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(GLSpacing.lg),
        child: Wrap(
          spacing: GLSpacing.lg,
          runSpacing: GLSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            InkWell(
              onTap: _pickDateRange,
              borderRadius: BorderRadius.circular(GLRadius.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: GLSpacing.lg, vertical: GLSpacing.md),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(GLRadius.md),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.date_range_rounded,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: GLSpacing.md),
                    Text(
                      _startDate != null && _endDate != null
                          ? '${DateFormat('MMM dd, yyyy').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}'
                          : 'Select Date Range',
                    ),
                  ],
                ),
              ),
            ),
            GLButton(
              text: 'Generate Report',
              icon: Icons.refresh_rounded,
              onPressed: state.isLoading ? null : _generateReport,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReport(BuildContext context, ComplianceReport report) {
    final theme = Theme.of(context);
    final numberFormat = NumberFormat('#,##0');
    final currencyFormat = NumberFormat.currency(symbol: '₹');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Executive Summary / Key Metrics
        _buildSectionTitle(theme, 'Executive Summary'),
        const SizedBox(height: GLSpacing.lg),
        _buildKeyMetricsGrid(report, numberFormat),
        
        const SizedBox(height: GLSpacing.xxl),
        
        // Detailed Metrics Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Waste Breakdown
            Expanded(
              flex: 3,
              child: _buildWasteBreakdown(theme, report),
            ),
            const SizedBox(width: GLSpacing.xl),
            // Satisfaction & Reliability
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildSatisfactionCard(theme, report),
                  const SizedBox(height: GLSpacing.lg),
                  _buildReliabilityCard(theme, report),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: GLSpacing.xxl),

        // Financials & Growth Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Financial Summary
            Expanded(
              child: _buildFinancialCard(theme, report, currencyFormat),
            ),
            const SizedBox(width: GLSpacing.xl),
            // Growth Projections
            Expanded(
              child: _buildGrowthCard(theme, report, numberFormat),
            ),
          ],
        ),
        
        const SizedBox(height: GLSpacing.xxl),
        const SizedBox(height: GLSpacing.xxl),
      ],
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        Container(
          height: 3,
          width: 40,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildKeyMetricsGrid(ComplianceReport report, NumberFormat nf) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - (3 * GLSpacing.lg)) / 4;
        return Wrap(
          spacing: GLSpacing.lg,
          runSpacing: GLSpacing.lg,
          children: [
            SizedBox(
              width: cardWidth > 200 ? cardWidth : double.infinity,
              child: _StatCard(
                title: 'Households Onboarded',
                value: nf.format(report.coveredHouseholds),
                subtitle: '${report.householdCoveragePercentage.toStringAsFixed(1)}% of total',
                icon: Icons.home_work_rounded,
                color: Colors.blue,
              ),
            ),
            SizedBox(
              width: cardWidth > 200 ? cardWidth : double.infinity,
              child: _StatCard(
                title: 'Pickups Completed',
                value: nf.format(report.totalPickupsCompleted),
                subtitle: 'Total pilot pickups',
                icon: Icons.local_shipping_rounded,
                color: Colors.teal,
              ),
            ),
            SizedBox(
              width: cardWidth > 200 ? cardWidth : double.infinity,
              child: _StatCard(
                title: 'Waste Diverted',
                value: '${report.totalWasteCollectedKg.toStringAsFixed(1)} kg',
                subtitle: 'Tonnage since launch',
                icon: Icons.recycling_rounded,
                color: Colors.green,
              ),
            ),
            SizedBox(
              width: cardWidth > 200 ? cardWidth : double.infinity,
              child: _StatCard(
                title: 'NPS Score',
                value: report.npsScore.toStringAsFixed(0),
                subtitle: _getNpsLabel(report.npsScore),
                icon: Icons.favorite_rounded,
                color: _getNpsColor(report.npsScore),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWasteBreakdown(ThemeData theme, ComplianceReport report) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(GLRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(GLSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Waste Segregation Breakdown', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: GLSpacing.lg),
            if (report.wasteByTypeKg.isEmpty)
              const Center(child: Text('No waste data for this period.'))
            else
              ...report.wasteByTypeKg.entries.map((entry) {
                final percentage = report.totalWasteCollectedKg > 0 
                  ? (entry.value / report.totalWasteCollectedKg) * 100 
                  : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: GLSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                          Text('${entry.value.toStringAsFixed(1)} kg (${percentage.toStringAsFixed(1)}%)'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 10,
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildSatisfactionCard(ThemeData theme, ComplianceReport report) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(GLRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(GLSpacing.lg),
        child: Column(
          children: [
            const Icon(Icons.groups_rounded, size: 32, color: Colors.blueGrey),
            const SizedBox(height: GLSpacing.md),
            Text('Citizen Engagement', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: GLSpacing.sm),
            _infoRow('Onboarding Rate', '${report.householdCoveragePercentage.toStringAsFixed(1)}%'),
            _infoRow('Accuracy Score', '${report.segregationAccuracyPercentage.toStringAsFixed(1)}%'),
            _infoRow('Avg Response', '${report.averageResponseTimeSeconds.toStringAsFixed(1)}h'),
          ],
        ),
      ),
    );
  }

  Widget _buildReliabilityCard(ThemeData theme, ComplianceReport report) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(GLRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(GLSpacing.lg),
        child: Column(
          children: [
            const Icon(Icons.dns_rounded, size: 32, color: Colors.indigo),
            const SizedBox(height: GLSpacing.md),
            Text('System Reliability', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: GLSpacing.sm),
            _infoRow('System Uptime', '${report.systemUptimePercentage.toStringAsFixed(2)}%'),
            _infoRow('HKS Attendance', '${report.hksAttendancePercentage.toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialCard(ThemeData theme, ComplianceReport report, NumberFormat cur) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(GLRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(GLSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Financial Health', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: GLSpacing.lg),
            _infoRowDetail('Total Collection', cur.format(report.totalFeeCollected), 'Fees from residents'),
            const Divider(height: GLSpacing.xl),
            _infoRowDetail('Cloud Infrastructure', cur.format(report.cloudCostUsd), 'Estimated cloud spend'),
            const Divider(height: GLSpacing.xl),
            _infoRowDetail('Budget Utilization', '${report.budgetUtilizationPercentage.toStringAsFixed(1)}%', 'Against pilot allocation'),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthCard(ThemeData theme, ComplianceReport report, NumberFormat nf) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(GLRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(GLSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Growth & Projections', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: GLSpacing.lg),
            _infoRowDetail('Next Month Projection', '+${nf.format(report.projectedOnboardingNextMonth)} HH', 'Estimated onboarding'),
            const Divider(height: GLSpacing.xl),
            _infoRowDetail('Tonnage Projection', '+${report.tonnageGrowthProjectionPercent.toStringAsFixed(1)}%', 'Expected growth in volume'),
            const SizedBox(height: GLSpacing.xxl),
            const Text(
              'Scale-up Readiness: High',
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _infoRowDetail(String label, String value, String description) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
      ],
    );
  }

  String _getNpsLabel(double score) {
    if (score >= 70) return 'World Class';
    if (score >= 50) return 'Excellent';
    if (score >= 30) return 'Good';
    if (score >= 0) return 'Positive';
    return 'Action Needed';
  }

  MaterialColor _getNpsColor(double score) {
    if (score >= 50) return Colors.green;
    if (score >= 0) return Colors.blue;
    return Colors.red;
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final MaterialColor color;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.shade50,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color.shade200),
        borderRadius: BorderRadius.circular(GLRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(GLSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color.shade700, size: 24),
                ),
                const SizedBox(width: GLSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: GLSpacing.lg),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color.shade900,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color.shade700,
                    ),
              ),
            ] else
              const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
