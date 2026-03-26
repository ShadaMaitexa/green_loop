import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:data_models/data_models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'route_map_state.dart';
import '../pickup_completion/pickup_completion_flow.dart';
import '../fee_collection/fee_collection_sheet.dart';
import '../fee_collection/fee_summary_screen.dart';
import '../issues/hks_issue_reporting_screen.dart';
import '../issues/hks_issue_list_screen.dart';
import '../sync/sync_manager.dart';
import '../sync/sync_status_badge.dart';

class RouteMapScreen extends StatefulWidget {
  const RouteMapScreen({super.key});

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  GoogleMapController? _mapController;
  bool _followUser = false;
  LatLng? _lastKnownPosition;
  bool _isListView = false;

  @override
  void initState() {
    super.initState();
    // After build, trigger data fetching and tracking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<RouteMapState>();
      state.fetchRoute();
      state.startLocationTracking();
      
      // Listen for position changes to follow user if enabled
      state.addListener(_onStateChange);
    });

    _syncSub = context.read<SyncManager>().conflictsStream.listen((count) {
      if (mounted) _showConflictDialog(count);
    });
  }

  StreamSubscription? _syncSub;

  void _showConflictDialog(int count) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Sync Conflict'),
          ],
        ),
        content: Text('$count report(s) found conflicts during upload and require admin review.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _onStateChange() {
    if (!mounted) return;
    final state = context.read<RouteMapState>();
    if (_followUser && state.currentPosition != null) {
      final pos = LatLng(state.currentPosition!.latitude, state.currentPosition!.longitude);
      if (_lastKnownPosition?.latitude != pos.latitude || _lastKnownPosition?.longitude != pos.longitude) {
        _lastKnownPosition = pos;
        _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
      }
    }
  }

  @override
  void dispose() {
    context.read<RouteMapState>().removeListener(_onStateChange);
    _syncSub?.cancel();
    super.dispose();
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
        title: const SyncStatusTitle(originalTitle: 'Today\'s Route'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.how_to_reg_rounded),
            tooltip: 'Log Attendance',
            onPressed: () => _handleLogAttendance(),
          ),
          IconButton(
            icon: Icon(_isListView ? Icons.map_rounded : Icons.list_alt_rounded),
            tooltip: _isListView ? 'Show Map' : 'Show List',
            onPressed: () => setState(() => _isListView = !_isListView),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: 'Fee Summary',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FeeSummaryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Route',
            onPressed: () => state.fetchRoute(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'report_issue') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HksIssueReportingScreen()));
              } else if (value == 'my_issues') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HksIssueListScreen()));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report_issue',
                child: Row(
                  children: [
                    Icon(Icons.report_problem_rounded, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text('Report Field Issue'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'my_issues',
                child: Row(
                  children: [
                    Icon(Icons.list_alt_rounded, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text('My Issues'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isListView ? _buildRouteListView(route) : Stack(
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
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
          ),
          
          // Camera Control Buttons
          Positioned(
            right: 16,
            bottom: 120, // Above navigation button
            child: Column(
              children: [
                Material(
                  elevation: 4,
                  shape: const CircleBorder(),
                  color: theme.colorScheme.surface,
                  child: IconButton(
                    icon: Icon(
                      _followUser ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
                      color: _followUser ? theme.colorScheme.primary : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _followUser = !_followUser;
                        if (_followUser && state.currentPosition != null) {
                          _centerOnUser();
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Material(
                  elevation: 4,
                  shape: const CircleBorder(),
                  color: theme.colorScheme.surface,
                  child: IconButton(
                    icon: const Icon(Icons.layers_rounded),
                    onPressed: () => _fitRouteBounds(route),
                  ),
                ),
              ],
            ),
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
        80.0, // padding
      ),
    );
  }

  void _centerOnUser() {
    final state = context.read<RouteMapState>();
    if (state.currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(state.currentPosition!.latitude, state.currentPosition!.longitude),
        ),
      );
    }
  }

  Set<Marker> _buildMarkers(List<HksPickup> pickups) {
    final Set<Marker> markers = {};
    for (int i = 0; i < pickups.length; i++) {
      final p = pickups[i];
      markers.add(
        Marker(
          markerId: MarkerId(p.id),
          position: LatLng(p.latitude, p.longitude),
          infoWindow: InfoWindow(title: '${i + 1}. ${p.residentName}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            p.wasteType == WasteType.wet ? BitmapDescriptor.hueGreen :
            p.wasteType == WasteType.dry ? BitmapDescriptor.hueBlue :
            p.wasteType == WasteType.eWaste ? BitmapDescriptor.hueViolet :
            BitmapDescriptor.hueRed,
          ),
          onTap: () => _showPickupDetails(p),
        ),
      );
    }
    return markers;
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
              Row(
                children: [
                  if (pickup.phoneNumber != null) ...[
                    Expanded(
                      flex: 1,
                      child: GLButton(
                        text: 'Call',
                        variant: GLButtonVariant.outline,
                        icon: Icons.call_rounded,
                        onPressed: () => _makeCall(pickup.phoneNumber!),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                    Expanded(
                      flex: 2,
                      child: GLButton(
                        text: 'Navigate',
                        icon: Icons.directions_rounded,
                        onPressed: () {
                          Navigator.pop(context);
                          _launchNavigationToPoint(pickup.latitude, pickup.longitude);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: GLButton(
                    text: 'Complete Pickup',
                    icon: Icons.check_circle_rounded,
                    onPressed: () {
                      Navigator.pop(context); // Close bottom sheet
                      _startPickupCompletion(pickup);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: GLButton(
                    text: 'Collect Fee',
                    icon: Icons.payments_rounded,
                    variant: GLButtonVariant.outline,
                    onPressed: () {
                      Navigator.pop(context); // Close bottom sheet
                      FeeCollectionSheet.show(context, pickup);
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
      final webUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
      if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    }
  }

  Widget _buildRouteListView(HksRoute route) {
    if (route.pickups.isEmpty) {
      return const Center(child: Text('No pickups assigned for today.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: route.pickups.length,
      itemBuilder: (context, index) {
        final pickup = route.pickups[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: pickup.wasteType.color.withOpacity(0.1),
                  child: Text('${index + 1}', style: TextStyle(color: pickup.wasteType.color)),
                ),
              ],
            ),
            title: Text(pickup.residentName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pickup.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                GLStatusBadge.custom(
                  status: pickup.wasteType.label,
                  backgroundColor: pickup.wasteType.color.withOpacity(0.1),
                  textColor: pickup.wasteType.color,
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showPickupDetails(pickup),
          ),
        );
      },
    );
  }

  void _startPickupCompletion(HksPickup pickup) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PickupCompletionFlow(pickup: pickup),
      ),
    );
  }

  Future<void> _makeCall(String phoneNumber) async {
    final url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
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
