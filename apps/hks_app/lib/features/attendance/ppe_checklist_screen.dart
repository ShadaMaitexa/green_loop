import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import 'attendance_state.dart';

/// PPE Checklist screen — all items must be ticked before allowing check-in.
class PpeChecklistScreen extends StatelessWidget {
  const PpeChecklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PPE Compliance Check')),
      body: Consumer<AttendanceState>(
        builder: (context, state, _) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade700,
                        Colors.green.shade400,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 40),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Safety Check',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Confirm all PPE is properly worn before starting your shift.',
                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Selfie thumbnail
                if (state.selfieFile != null) ...[
                  const Text('PPE Selfie', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      state.selfieFile!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Checklist
                const Text('Confirm each item is worn:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...state.ppeItems.map((item) => _PpeCheckTile(
                  item: item,
                  onToggle: () => state.togglePpe(item.id),
                )),
                const Spacer(),

                // Progress
                _buildProgressBar(state),
                const SizedBox(height: 24),

                // CTA
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(state.error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                        ],
                      ),
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  child: GLButton(
                    text: state.loading ? 'Verifying Location...' : 'Check In Now',
                    icon: Icons.how_to_reg_rounded,
                    isLoading: state.loading,
                    onPressed: state.allPpeChecked && !state.loading
                        ? () => _handleCheckIn(context, state)
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                if (!state.allPpeChecked)
                  Center(
                    child: Text(
                      'All PPE items must be confirmed.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressBar(AttendanceState state) {
    final checked = state.ppeItems.where((e) => e.isChecked).length;
    final total = state.ppeItems.length;
    final progress = total == 0 ? 0.0 : checked / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Compliance Progress', style: TextStyle(fontWeight: FontWeight.w500)),
            Text(
              '$checked / $total',
              style: TextStyle(
                color: progress == 1.0 ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            color: progress == 1.0 ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }

  Future<void> _handleCheckIn(BuildContext context, AttendanceState state) async {
    final success = await state.submitCheckIn();
    if (!context.mounted) return;

    if (success) {
      // Pop back to dashboard
      Navigator.pop(context, true);
    }
    // Errors are shown inline via state.error
  }
}

class _PpeCheckTile extends StatelessWidget {
  final dynamic item;
  final VoidCallback onToggle;

  const _PpeCheckTile({required this.item, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: item.isChecked
              ? Colors.green.withOpacity(0.08)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.isChecked ? Colors.green : Colors.grey[300]!,
            width: item.isChecked ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(item.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: item.isChecked
                  ? const Icon(Icons.check_circle_rounded, color: Colors.green, key: ValueKey('check'))
                  : Icon(Icons.radio_button_unchecked_rounded, color: Colors.grey[400], key: const ValueKey('uncheck')),
            ),
          ],
        ),
      ),
    );
  }
}
