import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:data_models/data_models.dart';
import 'route_map_state.dart';

/// Screen for HKS workers to view their assigned route, ward boundary, and pickups.
class RouteMapScreen extends StatefulWidget {
  const RouteMapScreen({super.key});

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    // After build, trigger data fetching and tracking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<RouteMapState>();
      state.fetchRoute();
      state.startLocationTracking();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RouteMapState>();
    final theme = Theme.of(context);

    if (state.loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state.error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.map_outlined, size: 80, color: Colors.grey),
                const SizedBox(height: 24),
                Text(
                  state.error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 32),
                GLButton(
                  text: 'Retry Loading Route',
                  onPressed: () => state.fetchRoute(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final route = state.route;
    if (route == null) {
       return const Scaffold(body: Center(child: Text('No active route assigned.')));
    }

    // Prepare Map Layers
    final Set<Polyline> polylines = {
      Polyline(
        polylineId: const PolylineId('route_path'),
        points: route.routePath.map((e) => LatLng(e[0], e[1])).toList(),
        color: theme.colorScheme.primary,
        width: 6,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };

    final Set<Polygon> polygons = route.wardBoundary != null 
        ? {
            Polygon(
              polygonId: const PolygonId('ward_boundary'),
              points: route.wardBoundary!.map((e) => LatLng(e[0], e[1])).toList(),
              fillColor: theme.colorScheme.primary.withOpacity(0.08),
              strokeColor: theme.colorScheme.primary.withOpacity(0.3),
              strokeWidth: 2,
            ),
          }
        : {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Route'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.how_to_reg_rounded),
            tooltip: 'Log Attendance',
            onPressed: () => _handleLogAttendance(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Route',
            onPressed: () => state.fetchRoute(),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: route.routePath.isNotEmpty 
                  ? LatLng(route.routePath[0][0], route.routePath[0][1])
                  : const LatLng(9.9312, 76.2673), // Fallback to Kochi
              zoom: 15.0,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              if (route.routePath.isNotEmpty) {
                _fitRouteBounds(route);
              }
            },
            markers: _buildMarkers(route.pickups),
            polylines: polylines,
            polygons: polygons,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
          ),
          
          // Current Position Tracking Hint if needed
          if (state.currentPosition == null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Expanded(child: Text('Acquiring GPS Signal...')),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _launchNavigation(route),
        label: const Text('Start Navigation'),
        icon: const Icon(Icons.navigation_rounded),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _fitRouteBounds(HksRoute route) {
    if (route.routePath.isEmpty || _mapController == null) return;

    double minLat = route.routePath[0][0];
    double maxLat = route.routePath[0][0];
    double minLng = route.routePath[0][1];
    double maxLng = route.routePath[0][1];

    for (final point in route.routePath) {
      if (point[0] < minLat) minLat = point[0];
      if (point[0] > maxLat) maxLat = point[0];
      if (point[1] < minLng) minLng = point[1];
      if (point[1] > maxLng) maxLng = point[1];
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        64.0, // padding
      ),
    );
  }

  Set<Marker> _buildMarkers(List<HksPickup> pickups) {
    return pickups.map((p) {
      return Marker(
        markerId: MarkerId(p.id),
        position: LatLng(p.latitude, p.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          p.wasteType == WasteType.wet ? BitmapDescriptor.hueGreen :
          p.wasteType == WasteType.dry ? BitmapDescriptor.hueBlue :
          p.wasteType == WasteType.eWaste ? BitmapDescriptor.hueViolet :
          BitmapDescriptor.hueRed,
        ),
        onTap: () => _showPickupDetails(p),
      );
    }).toSet();
  }

  void _showPickupDetails(HksPickup pickup) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle for bottom sheet
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(pickup.residentName, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pickup.address, 
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              const Divider(height: 40),
              
              _buildDetailItem(Icons.recycling_rounded, 'Waste Type', pickup.wasteType.label, pickup.wasteType.color),
              _buildDetailItem(Icons.access_time_rounded, 'Scheduled Time', pickup.bookingTime, Colors.black87),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: GLButton(
                  text: 'Navigate to Point',
                  icon: Icons.directions_rounded,
                  onPressed: () {
                    Navigator.pop(context);
                    _launchNavigationToPoint(pickup.latitude, pickup.longitude);
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, Color valueColor) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.grey[700]),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey[600])),
              Text(
                value, 
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Launches Google Maps with the full route including waypoints.
  Future<void> _launchNavigation(HksRoute route) async {
    if (route.routePath.isEmpty) return;
    
    // We use the last point of the route as destination and all pickups as waypoints.
    final destination = route.routePath.last;
    final String waypoints = route.pickups
        .map((p) => '${p.latitude},${p.longitude}')
        .join('|');
    
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${destination[0]},${destination[1]}&waypoints=$waypoints&travelmode=driving',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open Google Maps.')),
        );
      }
    }
  }

  /// Directly launches navigation to a specific coordinate.
  Future<void> _launchNavigationToPoint(double lat, double lng) async {
    final url = Uri.parse('google.navigation:q=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      // iOS / Browser fallback
      final webUrl = Uri.parse('http://maps.apple.com/?daddr=$lat,$lng');
      if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl);
      }
    }
  }

  Future<void> _handleLogAttendance() async {
    final state = context.read<RouteMapState>();
    if (state.currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waiting for GPS signal...')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attendance Logging'),
        content: const Text(
          'Log your attendance for today at the current location? '
          'This will verify you are within the assigned ward boundary.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Verify & Log'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Simulated PPE proof URL as Focus is on Map and API implementation
        await state.logAttendance('https://storage.greenloop.app/ppe/worker_123_today.jpg');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Attendance verified and logged!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Verification Failed: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }
}
