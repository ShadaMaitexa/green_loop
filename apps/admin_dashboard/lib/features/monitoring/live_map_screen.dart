import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  GoogleMapController? _controller;

  // Initial camera position pointing at Kozhikode
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(11.2588, 75.7804),
    zoom: 13,
  );

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
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: (controller) => _controller = controller,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
            polygons: _buildPolygons(state),
            markers: _buildMarkers(state),
          ),
          _buildOverlay(state),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () {
          if (state.workerPositions.isNotEmpty) {
            _controller?.animateCamera(
              CameraUpdate.newLatLng(
                LatLng(state.workerPositions.first.latitude, state.workerPositions.first.longitude),
              ),
            );
          }
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Set<Polygon> _buildPolygons(MonitoringState state) {
    return state.wardBoundaries.map((ward) {
      return Polygon(
        polygonId: PolygonId('ward_${ward.wardId}'),
        points: ward.polygon.map((p) => LatLng(p[0], p[1])).toList(),
        strokeWidth: 2,
        strokeColor: Colors.blue.withOpacity(0.5),
        fillColor: Colors.blue.withOpacity(0.1),
      );
    }).toSet();
  }

  Set<Marker> _buildMarkers(MonitoringState state) {
    final Set<Marker> markers = {};

    // Pickup Markers
    for (final pickup in state.pendingPickups) {
      if (pickup.latitude != null && pickup.longitude != null) {
        markers.add(
          Marker(
            markerId: MarkerId('pickup_${pickup.id}'),
            position: LatLng(pickup.latitude!, pickup.longitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _getWasteTypeHue(pickup.wasteType),
            ),
            infoWindow: InfoWindow(
              title: '${pickup.wasteType.label} Pickup',
              snippet: 'Status: ${pickup.status}',
            ),
          ),
        );
      }
    }

    // Worker Markers
    for (final worker in state.workerPositions) {
      markers.add(
        Marker(
          markerId: MarkerId('worker_${worker.workerId}'),
          position: LatLng(worker.latitude, worker.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            worker.isDeviated ? BitmapDescriptor.hueYellow : BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(
            title: worker.workerName,
            snippet: worker.isDeviated ? 'DEVIATION ALERT (>500m)' : 'On Route',
          ),
        ),
      );
    }
    
    // Fallback for pending pickups (since I need markers for them)
    // For now, let's assume we implement it correctly in the model.
    
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
              _buildLegendItem(Colors.lightBlue, 'HKS Workers'),
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

  double _getWasteTypeHue(WasteType type) {
    switch (type) {
      case WasteType.dry:
        return BitmapDescriptor.hueGreen;
      case WasteType.wet:
        return BitmapDescriptor.hueBlue;
      case WasteType.eWaste:
        return BitmapDescriptor.hueOrange;
      case WasteType.biomedical:
        return BitmapDescriptor.hueRed;
    }
  }
}
