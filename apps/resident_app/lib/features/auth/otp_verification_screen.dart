import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:auth/auth.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
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
      // Logic for first-time vs returning user should be in navigation
      // But standard logout/initial handles the state change.
      // We will handle the navigation in child widgets or use a wrapper.
    } else if (mounted) {
      setState(() => _errorText = authState.errorMessage);
    }
  }

  Future<void> _handleResend() async {
    final authState = context.read<AuthState>();
    final success = await authState.requestOtp(widget.email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'OTP Resent!' : 'Failed to resend OTP'),
        ),
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
                  'Verification Code',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: GLSpacing.md),
                Text(
                  'We sent a 6-digit code to\n${widget.email}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: GLSpacing.xxl),
                // OTP Input Simulation
                GLTextField(
                  label: 'Code',
                  hint: 'Enter 6-digit code',
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  errorText: _errorText,
                  prefixIcon: const Icon(Icons.security_rounded),
                ),
                const SizedBox(height: GLSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive a code?",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextButton(
                      onPressed: authState.status == AuthStatus.loading ? null : _handleResend,
                      child: Text(
                        'Resend',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: GLSpacing.xl),
                GLButton(
                  text: 'Verify',
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
