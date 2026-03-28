import 'package:flutter/material.dart' hide MaterialType;
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:data_models/data_models.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../recycler_state.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  // Active filter state
  DateTime? _filterDate;
  MaterialType? _filterMaterial;
  Ward? _filterWard;

  bool get _hasFilters =>
      _filterDate != null || _filterMaterial != null || _filterWard != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecyclerState>().fetchHistory();
    });
  }

  Future<void> _applyFilters(RecyclerState state) async {
    await state.fetchHistory(
      date: _filterDate != null
          ? DateFormat('yyyy-MM-dd').format(_filterDate!)
          : null,
      materialId: _filterMaterial?.id,
      wardId: _filterWard?.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RecyclerState>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase History'),
        actions: [
          if (_hasFilters)
            TextButton.icon(
              icon: const Icon(Icons.filter_list_off_rounded, size: 18),
              label: const Text('Clear'),
              onPressed: () {
                setState(() {
                  _filterDate = null;
                  _filterMaterial = null;
                  _filterWard = null;
                });
                state.fetchHistory();
              },
            ),
          IconButton(
            icon: Badge(
              isLabelVisible: _hasFilters,
              child: const Icon(Icons.filter_list_rounded),
            ),
            tooltip: 'Filter',
            onPressed: () => _showFilterSheet(context, state),
          ),
        ],
      ),
      body: Column(
        children: [
          // Active filter chips
          if (_hasFilters)
            _buildActiveFilterBar(theme),
          Expanded(
            child: state.isLoading && state.history.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _applyFilters(state),
                    child: state.history.isEmpty
                        ? _buildEmptyState(context)
                        : ListView.builder(
                            padding: const EdgeInsets.all(GLSpacing.lg),
                            itemCount: state.history.length,
                            itemBuilder: (context, index) {
                              return _PurchaseCard(
                                purchase: state.history[index],
                                onTap: () => _showPurchaseDetails(
                                  context,
                                  state.history[index],
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

  Widget _buildActiveFilterBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: GLSpacing.lg, vertical: GLSpacing.sm),
      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
      child: Row(
        children: [
          Icon(Icons.filter_alt_rounded,
              size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: GLSpacing.sm),
          Expanded(
            child: Wrap(
              spacing: GLSpacing.sm,
              children: [
                if (_filterDate != null)
                  Chip(
                    label: Text(DateFormat('MMM dd, yyyy').format(_filterDate!)),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => setState(() => _filterDate = null),
                    visualDensity: VisualDensity.compact,
                  ),
                if (_filterMaterial != null)
                  Chip(
                    label: Text(_filterMaterial!.name),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => setState(() => _filterMaterial = null),
                    visualDensity: VisualDensity.compact,
                  ),
                if (_filterWard != null)
                  Chip(
                    label: Text('Ward ${_filterWard!.id}'),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => setState(() => _filterWard = null),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 72, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: GLSpacing.lg),
          Text(_hasFilters ? 'No results for this filter' : 'No purchases yet',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: GLSpacing.sm),
          Text(
            _hasFilters
                ? 'Try adjusting or clearing your filters.'
                : 'Record your first purchase from the dashboard.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, RecyclerState state) {
    // Temporary local state for the sheet
    DateTime? tempDate = _filterDate;
    MaterialType? tempMaterial = _filterMaterial;
    Ward? tempWard = _filterWard;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(GLRadius.xl)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: GLSpacing.xl,
            right: GLSpacing.xl,
            top: GLSpacing.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + GLSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: GLSpacing.lg),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.outline.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filter Purchases',
                      style: Theme.of(ctx).textTheme.headlineSmall),
                  TextButton(
                    onPressed: () => setSheetState(() {
                      tempDate = null;
                      tempMaterial = null;
                      tempWard = null;
                    }),
                    child: const Text('Clear all'),
                  ),
                ],
              ),
              const SizedBox(height: GLSpacing.xl),

              // ── Date Filter ──────────────────────────────────────────────
              Text('Date', style: Theme.of(ctx).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: GLSpacing.sm),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: tempDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setSheetState(() => tempDate = picked);
                },
                borderRadius: BorderRadius.circular(GLRadius.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: GLSpacing.lg, vertical: GLSpacing.md),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(ctx).colorScheme.outline.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(GLRadius.md),
                    color: tempDate != null
                        ? Theme.of(ctx).colorScheme.primaryContainer.withOpacity(0.3)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 18,
                          color: Theme.of(ctx).colorScheme.primary),
                      const SizedBox(width: GLSpacing.md),
                      Text(
                        tempDate != null
                            ? DateFormat('MMM dd, yyyy').format(tempDate!)
                            : 'Select date',
                        style: TextStyle(
                          color: tempDate != null
                              ? Theme.of(ctx).colorScheme.onSurface
                              : Theme.of(ctx).colorScheme.outline,
                        ),
                      ),
                      const Spacer(),
                      if (tempDate != null)
                        GestureDetector(
                          onTap: () => setSheetState(() => tempDate = null),
                          child: Icon(Icons.close,
                              size: 16, color: Theme.of(ctx).colorScheme.outline),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: GLSpacing.lg),

              // ── Material Filter ──────────────────────────────────────────
              Text('Material Type', style: Theme.of(ctx).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: GLSpacing.sm),
              DropdownButtonFormField<MaterialType>(
                value: tempMaterial,
                decoration: const InputDecoration(
                  hintText: 'All materials',
                  prefixIcon: Icon(Icons.category_rounded),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: GLSpacing.lg, vertical: GLSpacing.md),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All materials')),
                  ...state.materials.map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m.name),
                      )),
                ],
                onChanged: (v) => setSheetState(() => tempMaterial = v),
              ),
              const SizedBox(height: GLSpacing.lg),

              // ── Ward Filter ──────────────────────────────────────────────
              Text('Source Ward', style: Theme.of(ctx).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: GLSpacing.sm),
              DropdownButtonFormField<Ward>(
                value: tempWard,
                decoration: const InputDecoration(
                  hintText: 'All wards',
                  prefixIcon: Icon(Icons.map_rounded),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: GLSpacing.lg, vertical: GLSpacing.md),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All wards')),
                  ...state.wards.map((w) => DropdownMenuItem(
                        value: w,
                        child: Text('Ward ${w.id} – ${w.nameEn}'),
                      )),
                ],
                onChanged: (v) => setSheetState(() => tempWard = v),
              ),
              const SizedBox(height: GLSpacing.xxl),

              GLButton(
                text: 'Apply Filters',
                icon: Icons.check_rounded,
                onPressed: () {
                  setState(() {
                    _filterDate = tempDate;
                    _filterMaterial = tempMaterial;
                    _filterWard = tempWard;
                  });
                  Navigator.pop(ctx);
                  _applyFilters(state);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPurchaseDetails(BuildContext context, RecyclerPurchase purchase) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(GLRadius.xl)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(GLSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: GLSpacing.lg),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Purchase Details',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: GLSpacing.lg),
            _DetailRow(label: 'Material', value: purchase.materialName ?? 'Unknown'),
            _DetailRow(
                label: 'Weight', value: '${purchase.weightKg.toStringAsFixed(2)} Kg'),
            _DetailRow(
                label: 'Date',
                value: DateFormat('MMM dd, yyyy  HH:mm').format(purchase.date)),
            _DetailRow(label: 'Source Ward', value: purchase.sourceWardName ?? 'Unknown'),
            _DetailRow(
                label: 'Total Amount',
                value: '₹${purchase.totalAmount.toStringAsFixed(2)}'),
            const SizedBox(height: GLSpacing.xl),
            if (purchase.certificateUrl != null) ...[
              const Divider(),
              const SizedBox(height: GLSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: GLButton(
                      text: 'Download PoR',
                      icon: Icons.download_rounded,
                      onPressed: () =>
                          _openCertificate(context, purchase.certificateUrl!),
                    ),
                  ),
                  const SizedBox(width: GLSpacing.md),
                  GLButton(
                    text: 'Share',
                    icon: Icons.share_rounded,
                    variant: GLButtonVariant.outline,
                    onPressed: () =>
                        _shareCertificate(purchase.certificateUrl!),
                  ),
                ],
              ),
            ] else
              Container(
                padding: const EdgeInsets.all(GLSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  border: Border.all(color: Colors.amber.shade300),
                  borderRadius: BorderRadius.circular(GLRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_empty_rounded,
                        color: Colors.amber.shade700, size: 20),
                    const SizedBox(width: GLSpacing.sm),
                    Text('Certificate not yet issued',
                        style: TextStyle(color: Colors.amber.shade800)),
                  ],
                ),
              ),
            const SizedBox(height: GLSpacing.md),
          ],
        ),
      ),
    );
  }

  Future<void> _openCertificate(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    Navigator.pop(context);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open certificate URL.')),
        );
      }
    }
  }

  void _shareCertificate(String url) {
    Share.share(url,
        subject: 'GreenLoop Proof of Recycling Certificate');
  }
}

class _PurchaseCard extends StatelessWidget {
  final RecyclerPurchase purchase;
  final VoidCallback onTap;
  const _PurchaseCard({required this.purchase, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: GLSpacing.md),
      elevation: GLElevation.low,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(GLRadius.lg)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GLRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(GLSpacing.lg),
          child: Row(
            children: [
              // Left: icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(GLRadius.md),
                ),
                child: Icon(Icons.shopping_bag_rounded,
                    color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: GLSpacing.md),
              // Center: info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(purchase.materialName ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      '${purchase.weightKg.toStringAsFixed(2)} Kg  •  ${purchase.sourceWardName}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM dd, yyyy').format(purchase.date),
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
              // Right: amount + certificate badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${purchase.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (purchase.certificateUrl != null)
                    const SizedBox(height: 4),
                  if (purchase.certificateUrl != null)
                    Tooltip(
                      message: 'Certificate ready',
                      child: Icon(Icons.verified_rounded,
                          color: Colors.green.shade600, size: 18),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GLSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.outline)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
