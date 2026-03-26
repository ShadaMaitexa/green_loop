import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:ui_kit/ui_kit.dart';

/// Full-screen front-camera selfie capture for PPE check-in.
/// Returns a [File] via [Navigator.pop] when the user confirms.
class SelfieCaptureScreen extends StatefulWidget {
  const SelfieCaptureScreen({super.key});

  @override
  State<SelfieCaptureScreen> createState() => _SelfieCaptureScreenState();
}

class _SelfieCaptureScreenState extends State<SelfieCaptureScreen> {
  CameraController? _controller;
  File? _preview;
  bool _initializing = true;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    _initFrontCamera();
  }

  Future<void> _initFrontCamera() async {
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _controller = CameraController(front, ResolutionPreset.medium, enableAudio: false);
      await _controller!.initialize();
      if (mounted) setState(() => _initializing = false);
    } catch (e) {
      if (mounted) setState(() {
        _cameraError = 'Could not open camera: $e';
        _initializing = false;
      });
    }
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final file = await _controller!.takePicture();
    setState(() => _preview = File(file.path));
  }

  void _retake() => setState(() => _preview = null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Take PPE Selfie'),
      ),
      body: _cameraError != null
          ? _buildError(theme)
          : _initializing
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _preview != null
                  ? _buildPreview(theme)
                  : _buildCamera(theme),
    );
  }

  Widget _buildCamera(ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CameraPreview(_controller!),
                ),
                // Oval face guide
                IgnorePointer(
                  child: CustomPaint(
                    painter: _OvalGuidePainter(),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Text(
                'Ensure your PPE is clearly visible',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              Material(
                shape: const CircleBorder(),
                elevation: 8,
                color: Colors.white,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _capture,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(_preview!, fit: BoxFit.cover),
            ),
          ),
        ),
        Container(
          color: Colors.black,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Row(
            children: [
              Expanded(
                child: GLButton(
                  text: 'Retake',
                  variant: GLButtonVariant.outline,
                  icon: Icons.refresh_rounded,
                  onPressed: _retake,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GLButton(
                  text: 'Use Photo',
                  icon: Icons.check_rounded,
                  onPressed: () => Navigator.pop(context, _preview),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.no_photography_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_cameraError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

/// Draws a translucent oval overlay to guide selfie framing.
class _OvalGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.45),
      width: size.width * 0.65,
      height: size.height * 0.55,
    );
    canvas.drawOval(rect, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
