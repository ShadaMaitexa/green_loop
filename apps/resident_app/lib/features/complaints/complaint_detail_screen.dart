import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:data_models/data_models.dart';
import 'package:core/core.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final String complaintId;
  const ComplaintDetailScreen({super.key, required this.complaintId});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  ComplaintModel? _complaint;
  bool _isLoading = true;
  int _userRating = 0;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final repo = context.read<ComplaintRepository>();
      final details = await repo.getComplaintDetails(widget.complaintId);
      setState(() {
        _complaint = details;
        _userRating = details.rating ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load details: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRating(int rating) async {
    try {
      final repo = context.read<ComplaintRepository>();
      await repo.rateComplaint(widget.complaintId, rating);
      setState(() => _userRating = rating);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rating failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_complaint == null) return const Scaffold(body: Center(child: Text('Complaint not found')));

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isResolved = _complaint!.status == ComplaintStatus.resolved;

    return Scaffold(
      appBar: AppBar(title: Text('Complaint #${_complaint!.id}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(GLSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusHeader(colorScheme),
            const SizedBox(height: GLSpacing.xl),
            
            Text(_complaint!.type, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: GLSpacing.md),
            Text(_complaint!.description, style: theme.textTheme.bodyLarge),
            const SizedBox(height: GLSpacing.xl),
            
            if (_complaint!.imageUrl != null) ...[
              Text('Evidence Photo', style: theme.textTheme.titleMedium),
              const SizedBox(height: GLSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(GLRadius.md),
                child: Image.network(
                  _complaint!.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Placeholder(fallbackHeight: 200),
                ),
              ),
              const SizedBox(height: GLSpacing.xl),
            ],

            Text('Resolution Timeline', style: theme.textTheme.titleMedium),
            const SizedBox(height: GLSpacing.md),
            _buildTimeline(colorScheme),
            
            if (isResolved) ...[
              const SizedBox(height: GLSpacing.xxl),
              Text('Rate the Resolution', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: GLSpacing.md),
              _buildRatingStars(colorScheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(ColorScheme colorScheme) {
    Color statusColor;
    switch (_complaint!.status) {
      case ComplaintStatus.submitted: statusColor = Colors.blue; break;
      case ComplaintStatus.inProgress: statusColor = Colors.orange; break;
      case ComplaintStatus.resolved: statusColor = Colors.green; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(GLRadius.xl),
        border: Border.all(color: statusColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag, color: statusColor, size: 20),
          const SizedBox(width: 8),
          Text(
            _complaint!.status.label.toUpperCase(),
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(ColorScheme colorScheme) {
    final history = _complaint!.history ?? [];
    if (history.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('Awaiting initial review...', style: TextStyle(fontStyle: FontStyle.italic)),
      );
    }

    return Column(
      children: history.map((event) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle)),
                Container(width: 2, height: 40, color: colorScheme.outlineVariant),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.status, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(event.comment, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  Text(
                    DateFormat('MMM d, h:mm a').format(event.updatedAt),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildRatingStars(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return IconButton(
          onPressed: () => _handleRating(starValue),
          icon: Icon(
            _userRating >= starValue ? Icons.star_rounded : Icons.star_outline_rounded,
            color: Colors.amber,
            size: 40,
          ),
        );
      }),
    );
  }
}
