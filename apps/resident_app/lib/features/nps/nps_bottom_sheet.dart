import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import 'nps_state.dart';

class NpsBottomSheet extends StatefulWidget {
  const NpsBottomSheet({super.key});

  @override
  State<NpsBottomSheet> createState() => _NpsBottomSheetState();
}

class _NpsBottomSheetState extends State<NpsBottomSheet> {
  int? _selectedRating;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NpsState>();

    return Padding(
      padding: EdgeInsets.only(
        left: GLSpacing.xl,
        right: GLSpacing.xl,
        top: GLSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + GLSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('How are we doing?', style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: GLSpacing.md),
          const Text('On a scale of 0 to 10, how likely are you to recommend GreenLoop to a friend?'),
          const SizedBox(height: GLSpacing.xl),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(11, (index) {
              final isSelected = _selectedRating == index;
              return InkWell(
                onTap: () => setState(() => _selectedRating = index),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
                    border: Border.all(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey[400]!,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$index',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: GLSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Not likely', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              Text('Very likely', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          const SizedBox(height: GLSpacing.xl),
          if (_selectedRating != null) ...[
            GLTextField(
              controller: _commentController,
              label: 'Care to share why? (Optional)',
              maxLines: 3,
            ),
            const SizedBox(height: GLSpacing.xl),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: GLSpacing.md),
                child: Text(state.error!, style: const TextStyle(color: Colors.red)),
              ),
            GLButton(
              text: 'Submit Feedback',
              isLoading: state.isSubmitting,
              onPressed: () async {
                final success = await context.read<NpsState>().submitNps(
                      _selectedRating!,
                      _commentController.text.trim(),
                    );
                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thank you for your feedback!')),
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}
