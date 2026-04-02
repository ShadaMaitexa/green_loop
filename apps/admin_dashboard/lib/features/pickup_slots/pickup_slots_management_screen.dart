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
                              title: Text('${slot.label} | ${slot.slot}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Status: ${slot.isAvailable ? "Active" : "Inactive"}'),
                                  if (slot.wards.isNotEmpty)
                                    Text('Wards: ${slot.wards.join(", ")}', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () {
                                  context.read<PickupSlotsState>().deleteSlot(slot.id); 
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
    final labelController = TextEditingController(text: 'Morning Shift');
    final timeRangeController = TextEditingController(text: '09:00 - 12:00');
    final capacityController = TextEditingController(text: '15');
    bool isActive = true;
    List<int> selectedWards = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Master Pickup Slot'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GLTextField(
                  label: 'Slot Label',
                  controller: labelController,
                  hint: 'e.g. Morning Slot',
                ),
                const SizedBox(height: GLSpacing.md),
                GLTextField(
                  label: 'Time Range (HH:mm - HH:mm)',
                  controller: timeRangeController,
                  hint: 'e.g. 09:00 - 12:00',
                ),
                const SizedBox(height: GLSpacing.md),
                GLTextField(
                  label: 'Maximum Capacity',
                  controller: capacityController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: GLSpacing.md),
                const Text('Assign to Wards', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: GLSpacing.xs),
                Wrap(
                  spacing: 8,
                  children: List.generate(10, (index) {
                    final wardId = index + 1;
                    final isSelected = selectedWards.contains(wardId);
                    return FilterChip(
                      label: Text('Ward $wardId'),
                      selected: isSelected,
                      onSelected: (val) {
                        setDialogState(() {
                          if (val) {
                            selectedWards.add(wardId);
                          } else {
                            selectedWards.remove(wardId);
                          }
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: GLSpacing.md),
                SwitchListTile(
                  title: const Text('Is Active'),
                  value: isActive,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setDialogState(() => isActive = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            GLButton(
              text: 'Save Slot',
              isLoading: context.watch<PickupSlotsState>().isLoading,
              onPressed: () async {
                if (labelController.text.isEmpty || timeRangeController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all required fields')),
                  );
                  return;
                }
                
                final success = await context.read<PickupSlotsState>().createSlot({
                  'label': labelController.text,
                  'time_range': timeRangeController.text,
                  'capacity': int.tryParse(capacityController.text) ?? 15,
                  'is_active': isActive,
                  'wards': selectedWards,
                });
                if (success) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
