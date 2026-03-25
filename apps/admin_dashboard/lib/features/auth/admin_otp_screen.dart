import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:auth/auth.dart';

class AdminOtpScreen extends StatefulWidget {
  final String email;

  const AdminOtpScreen({super.key, required this.email});

  @override
  State<AdminOtpScreen> createState() => _AdminOtpScreenState();
}

class _AdminOtpScreenState extends State<AdminOtpScreen> {
  final _otpController = TextEditingController();
  final int _otpLength = 6;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(_onOtpChanged);
  }

  @override
  void dispose() {
    _otpController.removeListener(_onOtpChanged);
    _otpController.dispose();
    super.dispose();
  }

  void _onOtpChanged() {
    final value = _otpController.text;
    if (value.length == _otpLength) {
      _verifyOtp(value);
    }
  }

  Future<void> _verifyOtp(String otp) async {
    setState(() => _errorText = null);

    final authState = context.read<AuthState>();
    final success = await authState.verifyOtp(widget.email, otp);

    if (success && mounted) {
      // Logic for dashboard navigation is handled by AuthWrapper status
    } else if (mounted) {
      setState(() => _errorText = authState.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = context.watch<AuthState>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              colorScheme.primaryContainer.withOpacity(0.3),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: GLSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 1),
                Text(
                  'Verify Admin OTP',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: GLSpacing.md),
                Text(
                  'Enter the 6-digit administrative control code sent to\n${widget.email}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: GLSpacing.xxl),
                GLTextField(
                  label: 'Control Code',
                  hint: 'Enter 6-digit code',
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  errorText: _errorText,
                  prefixIcon: const Icon(Icons.security_rounded),
                ),
                const SizedBox(height: GLSpacing.xl),
                GLButton(
                  text: 'Confirm Identity',
                  onPressed: () => _verifyOtp(_otpController.text),
                  isLoading: authState.status == AuthStatus.loading,
                ),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
