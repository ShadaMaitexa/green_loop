import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:auth/auth.dart';
import 'package:data_models/data_models.dart';
import 'package:geo/geo.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameEnController = TextEditingController();
  final _nameMlController = TextEditingController();
  final _addressController = TextEditingController();
  
  List<Ward> _wards = [];
  Ward? _selectedWard;
  bool _isLoadingWards = true;
  bool _isDetectingLocation = false;
  
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _populateExistingData();
    _loadWards();
    // Only auto-detect if we don't have location data yet
    if (_latitude == null || _longitude == null) {
      _autoDetectLocation();
    }
  }

  void _populateExistingData() {
    final user = context.read<AuthState>().user;
    if (user != null) {
      _nameEnController.text = user.nameEn ?? user.name;
      _nameMlController.text = user.nameMl ?? '';
      _addressController.text = user.address ?? '';
      _latitude = user.latitude;
      _longitude = user.longitude;
      // _selectedWard will be matched in _loadWards
    }
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameMlController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadWards() async {
    setState(() => _isLoadingWards = true);
    try {
      final allWards = await context.read<AuthState>().getWards();
      // Ensure unique wards by ID
      final seenIds = <int>{};
      final uniqueWards = allWards.where((w) => seenIds.add(w.id)).toList();
      
      final currentUser = context.read<AuthState>().user;

      setState(() {
        _wards = uniqueWards;
        _isLoadingWards = false;
        
        // Match existing ward if available
        if (currentUser?.wardId != null) {
          try {
            _selectedWard = _wards.firstWhere((w) => w.id == currentUser!.wardId);
          } catch (_) {
            // Ward not found in current list
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load wards: $e')),
        );
      }
      setState(() => _isLoadingWards = false);
    }
  }

  Future<void> _autoDetectLocation() async {
    setState(() => _isDetectingLocation = true);
    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentPosition();
      
      final address = await locationService.getAddressFromLatLng(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          if (address != null) {
            _addressController.text = address;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDetectingLocation = false);
      }
    }
  }

  Future<void> _handleSave() async {
    ScaffoldMessenger.of(context).clearSnackBars();
    
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct the validation errors below.')),
      );
      return;
    }

    if (_selectedWard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a ward from the dropdown.')),
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please detect your service location on the map.')),
      );
      return;
    }

    final authState = context.read<AuthState>();
    final profile = ResidentProfile(
      userId: authState.user?.id ?? '',
      nameEn: _nameEnController.text,
      nameMl: _nameMlController.text,
      wardId: _selectedWard!.id,
      address: _addressController.text,
      latitude: _latitude!,
      longitude: _longitude!,
    );

    try {
      final success = await authState.completeProfile(profile);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!')),
        );
        
        // Note: We no longer do manual navigation here.
        // AuthWrapper in main.dart watches AuthState, and when isProfileCompleted
        // becomes true, it will automatically switch the UI to HomeScreen.
        // This preserves the widget tree structure for logout to work correctly.
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.errorMessage ?? 'Failed to save profile. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = context.watch<AuthState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () => context.read<AuthState>().logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(GLSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionHeader(theme, 'Personal Information'),
              const SizedBox(height: GLSpacing.md),
              GLTextField(
                label: 'Full Name',
                hint: 'Enter your name',
                controller: _nameEnController,
                prefixIcon: const Icon(Icons.person_outline),
                validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
              ),
              if (Localizations.localeOf(context).languageCode == 'ml') ...[
                const SizedBox(height: GLSpacing.md),
                GLTextField(
                  label: 'Name (Malayalam)',
                  hint: 'പേര് നൽകുക',
                  controller: _nameMlController,
                  prefixIcon: const Icon(Icons.translate),
                ),
              ],
              const SizedBox(height: GLSpacing.xl),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Ward',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: GLSpacing.sm),
                  if (_isLoadingWards)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: GLSpacing.md),
                      child: LinearProgressIndicator(),
                    )
                  else if (_wards.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(GLSpacing.md),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(GLRadius.md),
                        border: Border.all(color: colorScheme.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: colorScheme.error),
                          const SizedBox(width: GLSpacing.md),
                          Expanded(
                            child: Text(
                              'Could not load wards. Please check your connection.',
                              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
                            ),
                          ),
                          TextButton(
                            onPressed: _loadWards,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else
                    DropdownButtonFormField<int>(
                      key: ValueKey('ward_dropdown_${_wards.length}'),
                      value: (_selectedWard != null && _wards.any((w) => w.id == _selectedWard!.id)) 
                          ? _selectedWard!.id 
                          : null,
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: 'Choose your ward',
                        filled: true,
                        fillColor: theme.brightness == Brightness.dark ? Colors.white10 : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(GLRadius.md),
                          borderSide: BorderSide(color: theme.brightness == Brightness.dark ? Colors.white30 : Colors.black26),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(GLRadius.md),
                          borderSide: BorderSide(color: theme.brightness == Brightness.dark ? Colors.white30 : Colors.black26),
                        ),
                        prefixIcon: const Icon(Icons.location_city),
                        contentPadding: const EdgeInsets.symmetric(horizontal: GLSpacing.lg, vertical: GLSpacing.md),
                      ),
                      items: _wards.map((ward) {
                        final label = Localizations.localeOf(context).languageCode == 'ml' 
                            ? ward.nameMl 
                            : ward.nameEn;
                        return DropdownMenuItem<int>(
                          value: ward.id,
                          child: Text(label, style: theme.textTheme.bodyLarge),
                        );
                      }).toList(),
                      onChanged: (id) {
                        if (id != null) {
                          setState(() {
                            _selectedWard = _wards.firstWhere((w) => w.id == id);
                          });
                        }
                      },
                      validator: (value) => value == null ? 'Please select a ward' : null,
                    ),
                ],
              ),
              const SizedBox(height: GLSpacing.xl),
              _buildSectionHeader(theme, 'Service Location'),
              const SizedBox(height: GLSpacing.md),
              // Interactive Flutter Map
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(GLRadius.md),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(GLRadius.md),
                  child: Stack(
                    children: [
                      if (_latitude != null && _longitude != null)
                        FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(_latitude!, _longitude!),
                            initialZoom: 15.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.greenloop.resident',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(_latitude!, _longitude!),
                                  width: 40, height: 40,
                                  child: Icon(Icons.location_on, color: colorScheme.primary, size: 40),
                                ),
                              ],
                            ),
                          ],
                        )
                      else
                        const Center(child: CircularProgressIndicator()),
                      
                      Positioned(
                        bottom: GLSpacing.sm,
                        right: GLSpacing.sm,
                        child: FloatingActionButton.small(
                          onPressed: _isDetectingLocation ? null : _autoDetectLocation,
                          child: _isDetectingLocation
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.my_location),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: GLSpacing.md),
              GLTextField(
                label: 'Service Address',
                hint: 'Flat/House No, Building, Street',
                controller: _addressController,
                prefixIcon: const Icon(Icons.home_outlined),
              ),
              const SizedBox(height: GLSpacing.xxl),
              GLButton(
                text: 'Save & Continue',
                onPressed: _handleSave,
                isLoading: authState.status == AuthStatus.loading,
              ),
              const SizedBox(height: GLSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
