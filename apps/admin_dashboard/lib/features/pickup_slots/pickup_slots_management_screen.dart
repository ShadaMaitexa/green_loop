import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';
import '../wards/ward_state.dart';
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
                              title: Text('Date: ${slot.date} | Slot: ${slot.slot}'),
                              subtitle: Text('Status: ${slot.isAvailable ? "Available" : "Full"}'),
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
    final dateController = TextEditingController();
    final startTimeController = TextEditingController();
    final endTimeController = TextEditingController();
    List<int> selectedWardIds = [];
    final capacityController = TextEditingController();

    // Trigger ward loading
    context.read<WardState>().loadWards();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Pickup Slot'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GLTextField(
                  label: 'Date (YYYY-MM-DD)',
                  controller: dateController,
                  readOnly: true,
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      setDialogState(() {
                        dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                      });
                    }
                  },
                ),
                const SizedBox(height: GLSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: GLTextField(
                        label: 'Start Time',
                        controller: startTimeController,
                        readOnly: true,
                        onTap: () async {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 9, minute: 0),
                          );
                          if (pickedTime != null) {
                            setDialogState(() {
                              startTimeController.text = pickedTime.format(context);
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: GLSpacing.sm),
                    Expanded(
                      child: GLTextField(
                        label: 'End Time',
                        controller: endTimeController,
                        readOnly: true,
                        onTap: () async {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 12, minute: 0),
                          );
                          if (pickedTime != null) {
                            setDialogState(() {
                              endTimeController.text = pickedTime.format(context);
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: GLSpacing.lg),
                Text('Select Wards', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: GLSpacing.sm),
                Consumer<WardState>(
                  builder: (context, wardState, child) {
                    if (wardState.isLoading) return const LinearProgressIndicator();
                    if (wardState.wards.isEmpty) return const Text('No wards available');
                    
                    return Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: wardState.wards.map((ward) {
                        final isSelected = selectedWardIds.contains(ward.id);
                        return FilterChip(
                          label: Text('Ward ${ward.number ?? ward.id}'),
                          selected: isSelected,
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                selectedWardIds.add(ward.id);
                              } else {
                                selectedWardIds.remove(ward.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: GLSpacing.md),
                GLTextField(label: 'Capacity (Optional)', controller: capacityController, keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            GLButton(
              text: 'Save',
              isLoading: context.watch<PickupSlotsState>().isLoading,
              onPressed: () async {
                if (dateController.text.isEmpty ||
                    startTimeController.text.isEmpty ||
                    endTimeController.text.isEmpty ||
                    selectedWardIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all required fields and select at least one ward')),
                  );
                  return;
                }
                
                final combinedSlot = '${startTimeController.text} - ${endTimeController.text}';
                
                final success = await context.read<PickupSlotsState>().createSlot({
                  'date': dateController.text,
                  'time_range': combinedSlot,
                  'wards': selectedWardIds,
                  if (capacityController.text.isNotEmpty) 'capacity': int.tryParse(capacityController.text),
                });
                if (success && mounted && context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
