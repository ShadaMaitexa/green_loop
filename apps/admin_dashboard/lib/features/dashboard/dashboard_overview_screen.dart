import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ui_kit/ui_kit.dart';
import 'dashboard_state.dart';
import 'models/dashboard_stats.dart';

class DashboardOverviewScreen extends StatefulWidget {
  const DashboardOverviewScreen({super.key});

  @override
  State<DashboardOverviewScreen> createState() => _DashboardOverviewScreenState();
}

class _DashboardOverviewScreenState extends State<DashboardOverviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardState>().loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardState>();
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(GLSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, state, theme),
          const SizedBox(height: GLSpacing.xl),
          if (state.isLoading && state.stats == null)
            const Center(child: CircularProgressIndicator())
          else if (state.stats != null) ...[
            _buildKPIs(context, state.stats!.kpis, theme),
            const SizedBox(height: GLSpacing.xxl),
            _buildTrendChart(context, state.stats!.weeklyTrend, theme),
            const SizedBox(height: GLSpacing.xxl),
            _buildWardComparison(context, state.stats!.wardComparison, theme),
            if (state.stats!.npsStats != null) ...[
              const SizedBox(height: GLSpacing.xxl),
              _buildNpsSection(context, state.stats!.npsStats!, theme),
            ],
          ] else
            Center(child: Text(state.error ?? 'Failed to load data')),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DashboardState state, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('System Overview', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text('Track key performance indicators and trends', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
          ],
        ),
        DropdownButton<DateRange>(
          value: state.currentRange,
          onChanged: (value) {
            if (value != null) state.setRange(value);
          },
          items: DateRange.values.map((range) {
            return DropdownMenuItem(value: range, child: Text(range.label));
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildKPIs(BuildContext context, DashboardKPIs kpis, ThemeData theme) {
    final isDesktop = GLResponsive.isDesktop(context);
    final isTablet = GLResponsive.isTablet(context);

    return GridView.count(
      crossAxisCount: isDesktop ? 4 : (isTablet ? 2 : 1),
      childAspectRatio: isDesktop ? 1.5 : (isTablet ? 1.5 : 2.5),
      crossAxisSpacing: GLSpacing.lg,
      mainAxisSpacing: GLSpacing.lg,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildKPICard('Pickups Today', '${kpis.pickupsToday}', Icons.local_shipping_rounded, Colors.blue),
        _buildKPICard('Active Workers', '${kpis.activeWorkers}', Icons.people_rounded, Colors.green),
        _buildKPICard('Pending Issues', '${kpis.pendingComplaints}', Icons.report_problem_rounded, Colors.orange),
        _buildKPICard('Waste Weight', '${kpis.totalWasteKg.toStringAsFixed(1)} kg', Icons.scale_rounded, Colors.purple),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(GLSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: GLSpacing.md),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: GLSpacing.xs),
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart(BuildContext context, List<TrendPoint> trends, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(GLSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pickup Trends (Last 4 Weeks)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: GLSpacing.xl),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: true, leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40))),
                  borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey[300]!)),
                  lineBarsData: [
                    LineChartBarData(
                      spots: trends.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.count.toDouble())).toList(),
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 4,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: theme.colorScheme.primary.withOpacity(0.1)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWardComparison(BuildContext context, List<WardComparison> wards, ThemeData theme) {
     return Card(
      child: Padding(
        padding: const EdgeInsets.all(GLSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ward-Level Comparison', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: GLSpacing.xl),
            SizedBox(
              height: 350,
              child: BarChart(
                BarChartData(
                  barGroups: wards.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(toY: e.value.pickups.toDouble(), color: Colors.blue, width: 12),
                        BarChartRodData(toY: e.value.complaints.toDouble(), color: Colors.orange, width: 12),
                        BarChartRodData(toY: e.value.wasteWeight / 10, color: Colors.purple, width: 12), // Scaled weight for visibility
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= wards.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(wards[index].wardName, style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: GLSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Pickups', Colors.blue),
                const SizedBox(width: GLSpacing.lg),
                _buildLegendItem('Complaints', Colors.orange),
                const SizedBox(width: GLSpacing.lg),
                _buildLegendItem('Waste (unscaled)', Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: GLSpacing.xs),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildNpsSection(BuildContext context, NpsStats npsStats, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(GLSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('NPS & Resident Satisfaction', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: npsStats.score >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(npsStats.score >= 0 ? Icons.sentiment_very_satisfied : Icons.sentiment_dissatisfied, 
                           color: npsStats.score >= 0 ? Colors.green : Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        'NPS: ${npsStats.score.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: npsStats.score >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: GLSpacing.md),
            Text('Total Responses: ${npsStats.totalResponses}', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: GLSpacing.xl),
            const Text('Recent Feedback', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: GLSpacing.md),
            if (npsStats.recentFeedback.isEmpty)
              const Text('No feedback yet.')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: npsStats.recentFeedback.length,
                itemBuilder: (context, index) {
                  final feedback = npsStats.recentFeedback[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: _ratingColor(feedback.rating).withOpacity(0.2),
                      child: Text('${feedback.rating}', style: TextStyle(color: _ratingColor(feedback.rating), fontWeight: FontWeight.bold)),
                    ),
                    title: Text(feedback.comment?.isNotEmpty == true ? feedback.comment! : 'No comment provided'),
                    subtitle: Text(feedback.date),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _ratingColor(int rating) {
    if (rating >= 9) return Colors.green;
    if (rating >= 7) return Colors.orange;
    return Colors.red;
  }
}
