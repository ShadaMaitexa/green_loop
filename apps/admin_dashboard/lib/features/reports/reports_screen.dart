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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - (3 * GLSpacing.lg)) / 4;
            return Wrap(
              spacing: GLSpacing.lg,
              runSpacing: GLSpacing.lg,
              children: [
                SizedBox(
                  width: cardWidth > 200 ? cardWidth : double.infinity,
                  child: _StatCard(
                    title: 'Total Waste Collected',
                    value: '${report.totalWasteCollectedKg.toStringAsFixed(1)} kg',
                    icon: Icons.delete_outline,
                    color: Colors.brown,
                  ),
                ),
                SizedBox(
                  width: cardWidth > 200 ? cardWidth : double.infinity,
                  child: _StatCard(
                    title: 'Household Coverage',
                    value: '${report.householdCoveragePercentage.toStringAsFixed(1)}%',
                    subtitle: '${numberFormat.format(report.coveredHouseholds)} / ${numberFormat.format(report.totalHouseholds)}',
                    icon: Icons.home_work_outlined,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(
                  width: cardWidth > 200 ? cardWidth : double.infinity,
                  child: _StatCard(
                    title: 'Segregation Accuracy',
                    value: '${report.segregationAccuracyPercentage.toStringAsFixed(1)}%',
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                ),
                SizedBox(
                  width: cardWidth > 200 ? cardWidth : double.infinity,
                  child: _StatCard(
                    title: 'HKS Attendance',
                    value: '${report.hksAttendancePercentage.toStringAsFixed(1)}%',
                    subtitle: '${report.activeHKSWorkers} / ${report.totalHKSWorkers} active',
                    icon: Icons.people_outline,
                    color: Colors.orange,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: GLSpacing.xl),
        Card(
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
                Text(
                  'Waste Segregation Breakdown',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: GLSpacing.lg),
                if (report.wasteByTypeKg.isEmpty)
                  const Text('No waste data available for this period.')
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
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                            minHeight: 8,
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
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
