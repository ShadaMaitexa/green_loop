import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:data_models/data_models.dart';
import 'package:core/core.dart';
import 'package:geo/geo.dart';
import 'complaint_detail_screen.dart';

class ComplaintSubmissionScreen extends StatefulWidget {
  const ComplaintSubmissionScreen({super.key});

  @override
  State<ComplaintSubmissionScreen> createState() => _ComplaintSubmissionScreenState();
}

class _ComplaintSubmissionScreenState extends State<ComplaintSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  
  String? _selectedType;
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  
  double? _latitude;
  double? _longitude;
  bool _isSubmitting = false;
  bool _isDetectingLocation = false;

  final List<String> _complaintTypes = [
    'Missed Pickup',
    'Damaged Collection Bin',
    'Overflowing Point',
    'Rude Behavior by Staff',
    'Other Service Issue'
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
      setState(() => _isDetectingLocation = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 70, // Optimize for S3
    );
    if (image != null) {
      setState(() => _imageFile = image);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || _selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = context.read<ComplaintRepository>();
      final request = ComplaintRequest(
        type: _selectedType!,
        description: _descriptionController.text,
        latitude: _latitude ?? 0.0,
        longitude: _longitude ?? 0.0,
      );

      final result = await repo.submitComplaint(
        request: request,
        imageFile: _imageFile != null ? File(_imageFile!.path) : null,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ComplaintDetailScreen(complaintId: result.id),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to file complaint: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('File a Complaint')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(GLSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Complaint Type',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(GLRadius.md)),
                  prefixIcon: const Icon(Icons.report_problem_outlined),
                ),
                items: _complaintTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) => setState(() => _selectedType = val),
              ),
              const SizedBox(height: GLSpacing.lg),
              
              GLTextField(
                label: 'Description',
                hint: 'Tell us more about the issue...',
                controller: _descriptionController,
                maxLines: 4,
                validator: (val) => (val == null || val.isEmpty) ? 'Description required' : null,
              ),
              const SizedBox(height: GLSpacing.xl),
              
              Text('Evidence Photo', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: GLSpacing.md),
              GestureDetector(
                onTap: () => _showImageSourcePicker(),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(GLRadius.md),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(GLRadius.md),
                          child: Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, size: 40, color: colorScheme.primary),
                              const SizedBox(height: GLSpacing.sm),
                              const Text('Add Photo'),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: GLSpacing.xl),
              
              Text('Location Details', style: Theme.of(context).textTheme.titleMedium),
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
                    Icon(Icons.location_on, color: colorScheme.primary),
                    const SizedBox(width: GLSpacing.md),
                    Expanded(
                      child: Text(
                        _latitude != null 
                          ? 'Coordinates: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
                          : 'Detecting location...',
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
              
              GLButton(
                text: 'Submit Complaint',
                isLoading: _isSubmitting,
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
