import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:data_models/data_models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'ward_state.dart';

class WardManagementScreen extends StatefulWidget {
  const WardManagementScreen({super.key});

  @override
  State<WardManagementScreen> createState() => _WardManagementScreenState();
}

class _WardManagementScreenState extends State<WardManagementScreen> {
  GoogleMapController? _mapController;
  final LatLng _initialCenter = const LatLng(11.2588, 75.7804); // Default to Kozhikode

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WardState>().loadWards();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<WardState>();
    final theme = Theme.of(context);

    return Row(
      children: [
        // Sidebar for Ward List
        Container(
          width: 350,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(right: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
          ),
          child: _buildWardSidebar(context, state),
        ),
        // Main Map Area
        Expanded(
          child: Stack(
            children: [
              _buildMap(context, state),
              _buildMapControls(context, state),
              if (state.drawMode != WardDrawMode.idle) _buildDrawOverlay(context, state),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWardSidebar(BuildContext context, WardState state) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(GLSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Wards', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              GLButton(
                text: 'Create',
                icon: Icons.add_rounded,
                variant: GLButtonVariant.primary,
                onPressed: () => state.startDrawing(),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: state.isLoading && state.wards.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  itemCount: state.wards.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final ward = state.wards[index];
                    final isSelected = state.selectedWard?.id == ward.id;
                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
                      title: Text(ward.nameEn, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(ward.nameMl, style: const TextStyle(fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.group_add_rounded, size: 20),
                            onPressed: () => _showAssignmentDialog(context, ward),
                            tooltip: 'Manage Workers',
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                      onTap: () {
                        state.selectWard(ward);
                        if (ward.boundary != null && ward.boundary!.isNotEmpty) {
                          _mapController?.animateCamera(
                            CameraUpdate.newLatLng(LatLng(ward.boundary![0][0], ward.boundary![0][1])),
                          );
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMap(BuildContext context, WardState state) {
    final polygons = <Polygon>{};

    // Existing ward polygons
    for (final ward in state.wards) {
      if (ward.boundary != null && ward.boundary!.isNotEmpty) {
        final isSelected = state.selectedWard?.id == ward.id;
        polygons.add(Polygon(
          polygonId: PolygonId('ward_${ward.id}'),
          points: ward.boundary!.map((c) => LatLng(c[0], c[1])).toList(),
          fillColor: (isSelected ? Colors.blue : Colors.green).withOpacity(0.2),
          strokeColor: isSelected ? Colors.blue : Colors.green,
          strokeWidth: 2,
          consumeTapEvents: true,
          onTap: () => state.selectWard(ward),
        ));
      }
    }

    // Pending drawing polygon
    if (state.pendingPolygon.isNotEmpty) {
      polygons.add(Polygon(
        polygonId: const PolygonId('pending'),
        points: state.pendingPolygon.map((c) => LatLng(c[0], c[1])).toList(),
        fillColor: Colors.orange.withOpacity(0.3),
        strokeColor: Colors.orange,
        strokeWidth: 3,
      ));
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _initialCenter, zoom: 13),
      onMapCreated: (controller) => _mapController = controller,
      polygons: polygons,
      onTap: (latLng) {
        if (state.drawMode != WardDrawMode.idle) {
          state.addCoordinate(latLng.latitude, latLng.longitude);
        }
      },
    );
  }

  Widget _buildMapControls(BuildContext context, WardState state) {
    if (state.drawMode == WardDrawMode.idle) return const SizedBox.shrink();

    return Positioned(
      top: GLSpacing.lg,
      right: GLSpacing.lg,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(GLSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.drawMode == WardDrawMode.drawing ? 'Drawing New Ward' : 'Editing Boundary',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: GLSpacing.sm),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => state.clearDrawing(),
                    icon: const Icon(Icons.clear_rounded),
                    label: const Text('Clear'),
                  ),
                  const SizedBox(width: GLSpacing.sm),
                  GLButton(
                    text: 'Finish & Save',
                    onPressed: () => _showSaveWardDialog(context, state),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawOverlay(BuildContext context, WardState state) {
    return const Positioned(
      bottom: GLSpacing.xl,
      left: 0,
      right: 0,
      child: Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: GLSpacing.lg, vertical: GLSpacing.md),
            child: Text('Tap on the map to place boundary vertices'),
          ),
        ),
      ),
    );
  }

  void _showSaveWardDialog(BuildContext context, WardState state) {
    final nameEnController = TextEditingController(text: state.selectedWard?.nameEn);
    final nameMlController = TextEditingController(text: state.selectedWard?.nameMl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(state.selectedWard == null ? 'New Ward Details' : 'Update Ward Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GLTextField(label: 'Name (English)', controller: nameEnController),
            const SizedBox(height: GLSpacing.md),
            GLTextField(label: 'Name (Malayalam)', controller: nameMlController),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          GLButton(
            text: 'Save Ward',
            onPressed: () async {
              final success = await state.saveWard({
                'name_en': nameEnController.text,
                'name_ml': nameMlController.text,
              });
              if (success && mounted && context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showAssignmentDialog(BuildContext context, Ward ward) {
    showDialog(
      context: context,
      builder: (context) => _WorkerAssignmentDialog(ward: ward),
    );
  }
}

class _WorkerAssignmentDialog extends StatefulWidget {
  final Ward ward;
  const _WorkerAssignmentDialog({required this.ward});

  @override
  State<_WorkerAssignmentDialog> createState() => _WorkerAssignmentDialogState();
}

class _WorkerAssignmentDialogState extends State<_WorkerAssignmentDialog> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final state = context.read<WardState>();
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        state.loadAllHksWorkers(),
        state.loadWardWorkers(widget.ward.id),
      ]);
      if (mounted) setState(() => _isLoading = false);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<WardState>();
    final allWorkers = state.allHksWorkers;
    final assignedWorkers = state.wardWorkers;

    return AlertDialog(
      title: Text('Assign Workers: ${widget.ward.nameEn}'),
      content: SizedBox(
        width: 500,
        height: 600,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  const Text('Select HKS workers to assign to this ward.'),
                  const SizedBox(height: GLSpacing.md),
                  Expanded(
                    child: ListView.builder(
                      itemCount: allWorkers.length,
                      itemBuilder: (context, index) {
                        final worker = allWorkers[index];
                        final isAssigned = assignedWorkers.any((w) => w.id == worker.id);
                        final isBusy = worker.assignedWard != null && worker.assignedWard!.id != widget.ward.id;

                        return CheckboxListTile(
                          title: Text(worker.name),
                          subtitle: Text(isBusy ? 'Assigned to: ${worker.assignedWard!.nameEn}' : 'Available'),
                          value: isAssigned,
                          onChanged: (bool? value) async {
                            final success = await state.updateWorkerAssignment(
                                  worker.id,
                                  value == true ? widget.ward.id : null,
                                );
                            if (success) _loadData();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}
