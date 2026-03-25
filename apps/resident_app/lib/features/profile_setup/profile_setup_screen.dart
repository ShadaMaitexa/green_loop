import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:auth/auth.dart';
import 'package:data_models/data_models.dart';
import 'package:geo/geo.dart';

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
    _loadWards();
    _autoDetectLocation();
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameMlController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadWards() async {
    try {
      final wards = await context.read<AuthState>().getWards();
      setState(() {
        _wards = wards;
        _isLoadingWards = false;
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
      
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      final address = await locationService.getAddressFromLatLng(
        position.latitude,
        position.longitude,
      );

      if (address != null && mounted) {
        setState(() {
          _addressController.text = address;
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
    if (!_formKey.currentState!.validate() || _selectedWard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please detect your location')),
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

    final success = await authState.completeProfile(profile);
    if (success && mounted) {
      // The AuthWrapper in main.dart will automatically switch to HomeScreen
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authState.errorMessage ?? 'Failed to save profile')),
      );
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(GLSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Personal Information',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: GLSpacing.lg),
              GLTextField(
                label: 'Name (English)',
                hint: 'Enter your full name',
                controller: _nameEnController,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              const SizedBox(height: GLSpacing.md),
              GLTextField(
                label: 'Name (Malayalam)',
                hint: 'പേര് നൽകുക',
                controller: _nameMlController,
                prefixIcon: const Icon(Icons.translate),
              ),
              const SizedBox(height: GLSpacing.xl),
              Text(
                'Ward Selection',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: GLSpacing.md),
              if (_isLoadingWards)
                const LinearProgressIndicator()
              else
                DropdownButtonFormField<Ward>(
                  value: _selectedWard,
                  decoration: InputDecoration(
                    labelText: 'Select your ward',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(GLRadius.md),
                    ),
                    prefixIcon: const Icon(Icons.location_city),
                  ),
                  items: _wards.map((ward) {
                    return DropdownMenuItem(
                      value: ward,
                      child: Text('${ward.nameEn} (${ward.nameMl})'),
                    );
                  }).toList(),
                  onChanged: (ward) => setState(() => _selectedWard = ward),
                ),
              const SizedBox(height: GLSpacing.xl),
              Text(
                'Service Location',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: GLSpacing.md),
              // Map Placeholder with detection overlay
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(GLRadius.md),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Opacity(
                        opacity: 0.1,
                        child: Icon(Icons.map_rounded, size: 100),
                      ),
                    ),
                    if (_latitude != null)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_on, color: colorScheme.primary, size: 40),
                            Text(
                              'Location Captured',
                              style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.primary),
                            ),
                          ],
                        ),
                      ),
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
}
