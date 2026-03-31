import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import 'pickup_slots_state.dart';

class PickupSlotsManagementScreen extends StatefulWidget {
  const PickupSlotsManagementScreen({super.key});

  @override
  State<PickupSlotsManagementScreen> createState() => _PickupSlotsManagementScreenState();
}

class _PickupSlotsManagementScreenState extends State<PickupSlotsManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PickupSlotsState>().loadSlots();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PickupSlotsState>();

    return Padding(
      padding: const EdgeInsets.all(GLSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pickup Slots',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Manage available timeslots for residents',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
              GLButton(
                text: 'Add Slot',
                onPressed: () => _showAddSlotDialog(context),
                icon: Icons.add_rounded,
              ),
            ],
          ),
          const SizedBox(height: GLSpacing.xl),
          Expanded(
            child: Card(
              child: state.isLoading && state.slots.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.slots.isEmpty
                      ? const Center(child: Text('No slots found'))
                      : ListView.builder(
                          itemCount: state.slots.length,
                          itemBuilder: (context, index) {
                            final slot = state.slots[index];
                            return ListTile(
                              leading: const Icon(Icons.access_time_rounded),
                              title: Text('Date: ${slot['date']} | Slot: ${slot['slot']}'),
                              subtitle: Text('Ward ID: ${slot['ward']} | Capacity: ${slot['capacity'] ?? "N/A"}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () {
                                  if (slot['id'] != null) {
                                    context.read<PickupSlotsState>().deleteSlot(slot['id'].toString());
                                  }
                                },
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

  void _showAddSlotDialog(BuildContext context) {
    final dateController = TextEditingController();
    final slotController = TextEditingController();
    final wardController = TextEditingController();
    final capacityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Pickup Slot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GLTextField(label: 'Date (YYYY-MM-DD)', controller: dateController),
            const SizedBox(height: GLSpacing.md),
            GLTextField(label: 'Time Slot (e.g. 09:00 AM - 12:00 PM)', controller: slotController),
            const SizedBox(height: GLSpacing.md),
            GLTextField(label: 'Ward ID', controller: wardController, keyboardType: TextInputType.number),
            const SizedBox(height: GLSpacing.md),
            GLTextField(label: 'Capacity (Optional)', controller: capacityController, keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          GLButton(
            text: 'Save',
            isLoading: context.watch<PickupSlotsState>().isLoading,
            onPressed: () async {
              final success = await context.read<PickupSlotsState>().createSlot({
                'date': dateController.text,
                'slot': slotController.text,
                'ward': int.tryParse(wardController.text),
                if (capacityController.text.isNotEmpty) 'capacity': int.tryParse(capacityController.text),
              });
              if (success && mounted && context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
