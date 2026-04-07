import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:core/core.dart';
import 'package:geo/geo.dart';
import 'package:data_models/data_models.dart';
import 'package:intl/intl.dart';
import 'pickup_history_screen.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  final MapController _mapController = MapController();
  Timer? _pollingTimer;
  
  List<Polyline> _truckPaths = [];
  List<Marker> _truckMarkers = [];
  
  bool _isLoading = true;
  bool _isBooking = false;
  
  LatLng? _residentLocation;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _fetchLiveRoutes();
    // Poll every 30 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchLiveRoutes());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      final loc = await LocationService().getCurrentPosition();
      setState(() {
        _residentLocation = LatLng(loc.latitude, loc.longitude);
      });
    } catch (e) {
      debugPrint("Could not get resident location: \$e");
    }
  }

  Future<void> _fetchLiveRoutes() async {
    if (!mounted) return;
    try {
      final repo = context.read<PickupRepository>();
      final features = await repo.getLiveRoutes();
      
      final theme = Theme.of(context);
      List<Polyline> paths = [];
      List<Marker> markers = [];
      
      for (var feature in features) {
        final geometry = feature['geometry'];
        if (geometry != null && geometry['type'] == 'LineString') {
          final coordinates = geometry['coordinates'] as List;
          if (coordinates.isNotEmpty) {
            List<LatLng> points = [];
            for (var coord in coordinates) {
              points.add(LatLng((coord[1] as num).toDouble(), (coord[0] as num).toDouble()));
            }
            
            // Draw past history line
            paths.add(Polyline(
              points: points,
              color: theme.colorScheme.primary,
              strokeWidth: 4.0,
            ));
            
            // Draw current position marker (last coordinate)
            final lastPos = points.last;
            markers.add(Marker(
              point: lastPos,
              width: 50,
              height: 50,
              child: const Icon(Icons.local_shipping, color: Colors.green, size: 40),
            ));
          }
        }
      }
      
      setState(() {
        _truckPaths = paths;
        _truckMarkers = markers;
        _isLoading = false;
      });
      
    } catch (e) {
      debugPrint("Failed to fetch live routes: \$e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _instantBooking() async {
    if (_residentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location to use Instant Booking.')),
      );
      return;
    }

    WasteType selectedType = WasteType.dry;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Instant Booking'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('A pickup will arrive soon. Please select the waste type:'),
                  const SizedBox(height: 16),
                  ...WasteType.values.map((type) => RadioListTile<WasteType>(
                    title: Row(
                      children: [
                        Icon(type.icon, color: type.color),
                        const SizedBox(width: 8),
                        Text(type.label),
                      ],
                    ),
                    value: type,
                    groupValue: selectedType,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => selectedType = val);
                      }
                    },
                    contentPadding: EdgeInsets.zero,
                  )),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('OK'),
                ),
              ],
            );
          }
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isBooking = true);
    try {
      final repo = context.read<PickupRepository>();
      
      final request = PickupRequest(
        wasteType: selectedType,
        scheduledDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        slot: 'INSTANT',
        address: 'Live Location GPS',
        latitude: _residentLocation!.latitude,
        longitude: _residentLocation!.longitude,
        isInstant: true,
      );
      
      final response = await repo.createPickup(request);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Instant Booking Confirmed! Truck dispatched. (ID: ${response.id})')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PickupHistoryScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to book instant pickup: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Truck Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchLiveRoutes();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(11.2588, 75.7804), // Default center
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.greenloop.resident',
              ),
              PolylineLayer(
                polylines: _truckPaths,
              ),
              MarkerLayer(
                markers: [
                  ..._truckMarkers,
                  if (_residentLocation != null)
                    Marker(
                      point: _residentLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                    ),
                ],
              ),
            ],
          ),
          if (_isLoading)
            const Positioned(
              top: GLSpacing.md,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isBooking ? null : _instantBooking,
        label: _isBooking ? const Text('Booking...') : const Text('Instant Booking'),
        icon: _isBooking 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.flash_on),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
