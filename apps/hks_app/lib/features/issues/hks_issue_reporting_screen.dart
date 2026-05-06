import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:data_models/data_models.dart';
import 'package:core/core.dart';
import 'package:geo/geo.dart';
import 'hks_issue_list_screen.dart';

class HksIssueReportingScreen extends StatefulWidget {
  const HksIssueReportingScreen({super.key});

  @override
  State<HksIssueReportingScreen> createState() => _HksIssueReportingScreenState();
}

class _HksIssueReportingScreenState extends State<HksIssueReportingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  
  String? _selectedType;
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  
  double? _latitude;
  double? _longitude;
  bool _isSubmitting = false;
  bool _isDetectingLocation = false;

  final List<String> _issueTypes = [
    'Overflowing Bins',
    'Access Blocked',
    'Resident Unavailable',
    'Vehicle Breakdown',
    'Other Field Issue'
  ];

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  Future<void> _detectLocation() async {
    setState(() => _isDetectingLocation = true);
    try {
      final pos = await LocationService().getCurrentPosition();
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 70, // Optimize for upload
    );
    if (image != null) {
      setState(() => _imageFile = image);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || _selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an issue type and fill in the description.')),
      );
      return;
    }

    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A photo is required for field issues.')),
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS Location is required.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = context.read<ComplaintRepository>();
      final request = ComplaintRequest(
        type: _selectedType!,
        description: _descriptionController.text,
        latitude: _latitude!,
        longitude: _longitude!,
      );

      await repo.submitComplaint(
        request: request,
        imageFile: File(_imageFile!.path),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Issue reported successfully. Admin notified.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HksIssueListScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to report issue: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Report Field Issue')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(GLSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Issue Type', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: GLSpacing.xs),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Select Category',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(GLRadius.md)),
                  prefixIcon: const Icon(Icons.report_problem_outlined),
                ),
                items: _issueTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) => setState(() => _selectedType = val),
              ),
              const SizedBox(height: GLSpacing.lg),
              
              GLTextField(
                label: 'Description',
                hint: 'Provide more context about the issue...',
                controller: _descriptionController,
                maxLines: 4,
                validator: (val) => (val == null || val.isEmpty) ? 'Description required' : null,
              ),
              const SizedBox(height: GLSpacing.xl),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Evidence Photo *', style: Theme.of(context).textTheme.titleMedium),
                  if (_imageFile == null)
                    const Text('Required', style: TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ),
              const SizedBox(height: GLSpacing.md),
              GestureDetector(
                onTap: () => _pickImage(ImageSource.camera),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(GLRadius.md),
                    border: Border.all(color: _imageFile == null ? colorScheme.outlineVariant : Colors.green),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(GLRadius.md),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                              Positioned(
                                top: 8, right: 8,
                                child: CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.black),
                                    onPressed: () => setState(() => _imageFile = null),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined, size: 40, color: colorScheme.primary),
                              const SizedBox(height: GLSpacing.sm),
                              const Text('Tap to Capture Photo'),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: GLSpacing.xl),
              
              Text('Location Details *', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: GLSpacing.md),
              Container(
                padding: const EdgeInsets.all(GLSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(GLRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(
                      _latitude != null ? Icons.location_on : Icons.location_off,
                      color: _latitude != null ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: GLSpacing.md),
                    Expanded(
                      child: Text(
                        _latitude != null 
                          ? 'GPS Locked: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
                          : 'Detecting Location...',
                        style: TextStyle(
                          color: _latitude != null ? Colors.black87 : Colors.grey,
                          fontWeight: _latitude != null ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (_isDetectingLocation)
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    else
                      IconButton(icon: const Icon(Icons.refresh), onPressed: _detectLocation),
                  ],
                ),
              ),
              const SizedBox(height: GLSpacing.xxl),
              
              SizedBox(
                width: double.infinity,
                child: GLButton(
                  text: 'Submit Report',
                  icon: Icons.send_rounded,
                  isLoading: _isSubmitting,
                  onPressed: _handleSubmit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
