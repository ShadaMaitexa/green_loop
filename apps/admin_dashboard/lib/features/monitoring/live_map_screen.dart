import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:data_models/data_models.dart';
import 'monitoring_state.dart';
import 'package:ui_kit/ui_kit.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  final MapController _mapController = MapController();

  static const _initialCenter = LatLng(11.2588, 75.7804);
  static const _initialZoom = 13.0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MonitoringState>();

    if (state.isLoading && state.wardBoundaries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.wardBoundaries.isEmpty) {
      return Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: GLSpacing.md),
          Text(state.error!),
          const SizedBox(height: GLSpacing.md),
          GLButton(
            text: 'Retry',
            onPressed: () => state.initializeMap(),
          ),
        ],
      ));
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _initialCenter,
              initialZoom: _initialZoom,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.green_loop',
              ),
              PolygonLayer(
                polygons: _buildPolygons(state),
              ),
              MarkerLayer(
                markers: _buildMarkers(state),
              ),
            ],
          ),
          _buildOverlay(state),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () {
          if (state.workerPositions.isNotEmpty) {
            _mapController.move(
              LatLng(state.workerPositions.first.latitude, state.workerPositions.first.longitude),
              15.0,
            );
          }
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }

  List<Polygon> _buildPolygons(MonitoringState state) {
    return state.wardBoundaries.map((ward) {
      return Polygon(
        points: ward.polygon.map((p) => LatLng(p[0], p[1])).toList(),
        borderStrokeWidth: 2,
        borderColor: Colors.blue.withValues(alpha: 0.5),
        color: Colors.blue.withValues(alpha: 0.1),
      );
    }).toList();
  }

  List<Marker> _buildMarkers(MonitoringState state) {
    final List<Marker> markers = [];

    // Pickup Markers
    for (final pickup in state.pendingPickups) {
      if (pickup.latitude != null && pickup.longitude != null) {
        markers.add(
          Marker(
            point: LatLng(pickup.latitude!, pickup.longitude!),
            width: 40,
            height: 40,
            child: Tooltip(
              message: '${pickup.wasteType.label} Pickup\nStatus: ${pickup.status}',
              child: Icon(
                Icons.location_on,
                color: _getWasteTypeColor(pickup.wasteType),
                size: 30,
              ),
            ),
          ),
        );
      }
    }

    // Worker Markers
    for (final worker in state.workerPositions) {
      markers.add(
        Marker(
          point: LatLng(worker.latitude, worker.longitude),
          width: 40,
          height: 40,
          child: Tooltip(
            message: '${worker.workerName}\n${worker.isDeviated ? 'DEVIATION ALERT (>500m)' : 'On Route'}',
            child: Icon(
              Icons.person_pin_circle,
              color: worker.isDeviated ? Colors.orange : Colors.blue,
              size: 35,
            ),
          ),
        ),
      );
    }
    
    return markers;
  }

  Widget _buildOverlay(MonitoringState state) {
    return Positioned(
      top: GLSpacing.md,
      right: GLSpacing.md,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: GLSpacing.md, vertical: GLSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Live Monitoring',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: GLSpacing.xs),
              _buildLegendItem(Colors.blue, 'Wards'),
              _buildLegendItem(Colors.blue, 'HKS Workers'),
              _buildLegendItem(Colors.orange, 'Deviation Alerts'),
              const Divider(),
              Text(
                '${state.workerPositions.length} workers active',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: GLSpacing.xs),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Color _getWasteTypeColor(WasteType type) {
    switch (type) {
      case WasteType.dry:
        return Colors.green;
      case WasteType.wet:
        return Colors.blue;
      case WasteType.eWaste:
        return Colors.orange;
      case WasteType.biomedical:
        return Colors.red;
    }
  }
}

