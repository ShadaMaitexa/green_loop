import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:camera/camera.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:data_models/data_models.dart';
import 'package:core/core.dart';
import 'pickup_completion_state.dart';
import 'services/ai_classification_service.dart';

/// The multi-step flow for completing a pickup.
class PickupCompletionFlow extends StatefulWidget {
  final HksPickup pickup;

  const PickupCompletionFlow({super.key, required this.pickup});

  @override
  State<PickupCompletionFlow> createState() => _PickupCompletionFlowState();
}

class _PickupCompletionFlowState extends State<PickupCompletionFlow> {
  late PickupCompletionState _state;

  @override
  void initState() {
    super.initState();
    final repository = context.read<HksRouteRepository>();
    final aiService = AiClassificationService();
    aiService.initialize();
    _state = PickupCompletionState(
      repository: repository,
      aiService: aiService,
      pickup: widget.pickup,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _state,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pickup Completion'),
          elevation: 1,
        ),
        body: Consumer<PickupCompletionState>(
          builder: (context, state, child) {
            return Stepper(
              type: StepperType.horizontal,
              currentStep: state.currentStep,
              elevation: 0,
              controlsBuilder: (context, details) => const SizedBox.shrink(),
              steps: [
                Step(
                  title: const Text('Detail'),
                  content: _SummaryStep(pickup: state.pickup),
                  isActive: state.currentStep >= 0,
                  state: state.currentStep > 0 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: const Text('Verify'),
                  content: const _QrScanStep(),
                  isActive: state.currentStep >= 1,
                  state: state.currentStep > 1 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: const Text('Analysis'),
                  content: const _PhotoAnalysisStep(),
                  isActive: state.currentStep >= 2,
                  state: state.currentStep > 2 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: const Text('Finish'),
                  content: const _FinalizeStep(),
                  isActive: state.currentStep >= 3,
                  state: state.currentStep == 3 ? StepState.indexed : StepState.complete,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Step 1: Summary ─────────────────────────────────────────────────────────

class _SummaryStep extends StatelessWidget {
  final HksPickup pickup;
  const _SummaryStep({required this.pickup});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.read<PickupCompletionState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pickup.residentName, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(pickup.address, style: theme.textTheme.bodyMedium)),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(pickup.wasteType.icon, size: 18, color: pickup.wasteType.color),
                    const SizedBox(width: 8),
                    GLStatusBadge.custom(
                      status: pickup.wasteType.label,
                      backgroundColor: pickup.wasteType.color.withOpacity(0.1),
                      textColor: pickup.wasteType.color,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(pickup.bookingTime, style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: GLButton(
            text: 'Start Verification',
            onPressed: () => state.nextStep(),
            icon: Icons.qr_code_scanner_rounded,
          ),
        ),
      ],
    );
  }
}

// ─── Step 2: QR Scan ──────────────────────────────────────────────────────────

class _QrScanStep extends StatefulWidget {
  const _QrScanStep();

  @override
  State<_QrScanStep> createState() => _QrScanStepState();
}

class _QrScanStepState extends State<_QrScanStep> {
  final MobileScannerController _controller = MobileScannerController();
  bool _scanned = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PickupCompletionState>();
    final theme = Theme.of(context);

    // Show success state once QR is validated
    if (state.qrToken != null) {
      return Column(
        children: [
          const SizedBox(height: 16),
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 72),
          const SizedBox(height: 16),
          Text('QR Code Validated!', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Location and assignment confirmed.', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          const SizedBox(height: 32),
          GLButton(
            text: 'Proceed to Capture Photo',
            onPressed: () => state.nextStep(),
            icon: Icons.camera_alt_rounded,
          ),
        ],
      );
    }

    return Column(
      children: [
        Text(
          'Scan the QR code on the resident\'s app to verify this pickup.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Container(
          height: 280,
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.primary, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: (capture) async {
                    if (_scanned || !mounted) return;
                    final barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                      setState(() => _scanned = true);
                      final success = await state.validateQr(barcodes.first.rawValue!);
                      if (!success && mounted) {
                        setState(() => _scanned = false);
                      }
                    }
                  },
                ),
                // Scanning overlay
                if (state.loading)
                  Container(
                    color: Colors.black38,
                    child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                  ),
              ],
            ),
          ),
        ),
        if (state.error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text(state.error!, style: const TextStyle(color: Colors.red))),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        GLButton(
          text: 'Enter QR Manually',
          variant: GLButtonVariant.outline,
          onPressed: () => _showManualEntry(context, state),
        ),
      ],
    );
  }

  void _showManualEntry(BuildContext context, PickupCompletionState state) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Enter QR Code Manually'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'QR Token / Pickup ID',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await state.validateQr(controller.text.trim());
            },
            child: const Text('Validate'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ─── Step 3: Photo + AI Analysis ─────────────────────────────────────────────

class _PhotoAnalysisStep extends StatefulWidget {
  const _PhotoAnalysisStep();

  @override
  State<_PhotoAnalysisStep> createState() => _PhotoAnalysisStepState();
}

class _PhotoAnalysisStepState extends State<_PhotoAnalysisStep> {
  CameraController? _cameraController;
  bool _cameraInitialized = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _cameraError = 'No camera found on device.');
        return;
      }
      _cameraController = CameraController(cameras.first, ResolutionPreset.medium, enableAudio: false);
      await _cameraController!.initialize();
      if (mounted) setState(() => _cameraInitialized = true);
    } catch (e) {
      if (mounted) setState(() => _cameraError = 'Camera error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PickupCompletionState>();
    final theme = Theme.of(context);

    // Loading while AI runs
    if (state.loading) {
      return const SizedBox(
        height: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Running AI Analysis...'),
          ],
        ),
      );
    }

    // Photo captured — show preview + result
    if (state.wastePhoto != null) {
      final cls = state.classification;
      return Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(state.wastePhoto!, height: 200, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 16),
          if (cls != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cls.requiresAdminReview ? Colors.orange[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: cls.requiresAdminReview ? Colors.orange[200]! : Colors.green[200]!,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        cls.requiresAdminReview ? Icons.admin_panel_settings_rounded : Icons.verified_rounded,
                        color: cls.requiresAdminReview ? Colors.orange : Colors.green,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Result: ${cls.label}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'Confidence: ${(cls.confidence * 100).toStringAsFixed(1)}%',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (cls.requiresAdminReview) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '⚠ Low Confidence — Admin Review Queued',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GLButton(
                  text: 'Retake',
                  variant: GLButtonVariant.outline,
                  onPressed: () => state.resetPhoto(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GLButton(
                  text: 'Continue',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => state.nextStep(),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Camera error
    if (_cameraError != null) {
      return Column(
        children: [
          const Icon(Icons.no_photography_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(_cameraError!, textAlign: TextAlign.center),
        ],
      );
    }

    // Camera not yet ready
    if (!_cameraInitialized) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Live camera view
    return Column(
      children: [
        Text(
          'Capture a clear photo of the waste to run on-device AI contamination check.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: _cameraController!.value.aspectRatio,
            child: CameraPreview(_cameraController!),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Material(
            shape: const CircleBorder(),
            elevation: 4,
            child: IconButton.filled(
              iconSize: 48,
              padding: const EdgeInsets.all(16),
              icon: const Icon(Icons.camera_alt_rounded),
              onPressed: () async {
                final file = await _cameraController!.takePicture();
                if (mounted) {
                  await state.setWastePhoto(File(file.path));
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text('Tap to capture', style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}

// ─── Step 4: Finalize ─────────────────────────────────────────────────────────

class _FinalizeStep extends StatefulWidget {
  const _FinalizeStep();

  @override
  State<_FinalizeStep> createState() => _FinalizeStepState();
}

class _FinalizeStepState extends State<_FinalizeStep> {
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PickupCompletionState>();
    final theme = Theme.of(context);
    final cls = state.classification;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review and submit your collection record.', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 24),

        // AI Summary Card
        if (cls != null)
          Card(
            color: cls.requiresAdminReview ? Colors.orange[50] : Colors.green[50],
            child: ListTile(
              leading: Icon(
                cls.requiresAdminReview ? Icons.admin_panel_settings_rounded : Icons.check_circle_outline_rounded,
                color: cls.requiresAdminReview ? Colors.orange : Colors.green,
              ),
              title: Text('AI: ${cls.label} (${(cls.confidence * 100).toStringAsFixed(0)}% confidence)'),
              subtitle: cls.requiresAdminReview ? const Text('Flagged for admin review') : null,
            ),
          ),
        const SizedBox(height: 16),

        // Weight input
        TextField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Waste Weight (optional, in kg)',
            prefixIcon: Icon(Icons.scale_rounded),
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => state.setWeight(double.tryParse(v)),
        ),
        const SizedBox(height: 24),

        // GPS distance warning
        if (!state.isWithinDistance)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.report_problem_rounded, color: Colors.red),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Beyond 100m Limit',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('You are too far from this pickup point. A reason note is required to override.'),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Reason for Override *',
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => state.setOverrideNote(v),
                ),
              ],
            ),
          ),

        const SizedBox(height: 32),

        // Server error display
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.error!, style: const TextStyle(color: Colors.red))),
                ],
              ),
            ),
          ),

        SizedBox(
          width: double.infinity,
          child: GLButton(
            text: 'Complete Pickup',
            icon: Icons.check_circle_rounded,
            isLoading: state.loading,
            onPressed: () async {
              final success = await state.completePickup();
              if (success && context.mounted) {
                _showSuccess(context);
              }
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showSuccess(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars_rounded, color: Colors.amber, size: 80),
              const SizedBox(height: 16),
              const Text(
                'Pickup Completed!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'GreenLeaf points will be awarded to the resident after analysis.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              GLButton(
                text: 'Return to Route',
                onPressed: () {
                  Navigator.pop(ctx);    // Close dialog
                  Navigator.pop(context); // Return to map/list
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
