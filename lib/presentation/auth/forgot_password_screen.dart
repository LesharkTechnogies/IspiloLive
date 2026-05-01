import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/app_export.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _emailError;
  String? _codeError;
  String? _newPasswordError;
  String? _confirmPasswordError;
  String? _apiError;

  bool _isSendingCode = false;
  bool _isResendingCode = false;
  bool _isUpdatingPassword = false;
  bool _hasRequestedCode = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  int _resendCountdown = 0;
  static const int _resendSeconds = 60;
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() {
      _resendCountdown = _resendSeconds;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown <= 1) {
        timer.cancel();
        setState(() {
          _resendCountdown = 0;
        });
        return;
      }
      setState(() {
        _resendCountdown -= 1;
      });
    });
  }

  bool _validateEmailOnly() {
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    setState(() {
      _apiError = null;
      _emailError = email.isEmpty
          ? 'Email is required'
          : (!emailRegex.hasMatch(email) ? 'Enter a valid email' : null);
    });

    return _emailError == null;
  }

  bool _validateResetFields() {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    final codeRegex = RegExp(r'^\d{6}$');

    setState(() {
      _apiError = null;
      _emailError = email.isEmpty
          ? 'Email is required'
          : (!emailRegex.hasMatch(email) ? 'Enter a valid email' : null);
      _codeError = code.isEmpty
          ? 'Verification code is required'
          : (!codeRegex.hasMatch(code) ? 'Code must be 6 digits' : null);
      _newPasswordError = newPassword.isEmpty
          ? 'New password is required'
          : (newPassword.length < 6
              ? 'Password must be at least 6 characters'
              : null);
      _confirmPasswordError = confirmPassword.isEmpty
          ? 'Confirm your password'
          : (confirmPassword != newPassword ? 'Passwords do not match' : null);
    });

    return _emailError == null &&
        _codeError == null &&
        _newPasswordError == null &&
        _confirmPasswordError == null;
  }

  String _mapApiError(Object error) {
    final raw = error.toString().toLowerCase();

    if (raw.contains('invalid verification code') ||
        (raw.contains('invalid') && raw.contains('code'))) {
      return 'Invalid verification code';
    }
    if (raw.contains('expired') && raw.contains('code')) {
      return 'Verification code has expired';
    }
    if (raw.contains('please wait') || raw.contains('too many requests')) {
      return 'Please wait before requesting another code';
    }

    return 'Something went wrong, try again';
  }

  Future<void> _sendCode() async {
    if (!_validateEmailOnly()) return;

    setState(() {
      _isSendingCode = true;
      _apiError = null;
    });

    try {
      await AuthService.requestResetCode(_emailController.text.trim());
      if (!mounted) return;

      _startResendCountdown();
      setState(() {
        _hasRequestedCode = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code sent if email exists.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _apiError = _mapApiError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSendingCode = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    if (_resendCountdown > 0 || _isResendingCode || !_validateEmailOnly()) {
      return;
    }

    setState(() {
      _isResendingCode = true;
      _apiError = null;
    });

    try {
      await AuthService.resendResetCode(_emailController.text.trim());
      if (!mounted) return;

      _startResendCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification code resent.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _apiError = _mapApiError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResendingCode = false;
        });
      }
    }
  }

  Future<void> _updatePassword() async {
    if (!_validateResetFields()) return;

    setState(() {
      _isUpdatingPassword = true;
      _apiError = null;
    });

    try {
      await AuthService.resetPassword(
        email: _emailController.text.trim(),
        code: _codeController.text.trim(),
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully.')),
        );

        _emailController.clear();
        _codeController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
  _resendTimer?.cancel();
  _resendCountdown = 0;

        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _apiError = _mapApiError(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingPassword = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isBusy = _isSendingCode || _isResendingCode || _isUpdatingPassword;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerLowest,
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -40,
                right: -30,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.22),
                        colorScheme.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -20,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        colorScheme.secondary.withValues(alpha: 0.20),
                        colorScheme.secondary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateX(0.012),
                    alignment: Alignment.center,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 520),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.surface.withValues(alpha: 0.95),
                            colorScheme.surfaceContainerHighest.withValues(alpha: 0.75),
                          ],
                        ),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.10),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.arrow_back),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Forgot Password',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter your email, request a code, then set a new password.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 18),
                            TextField(
                              controller: _emailController,
                              enabled: !isBusy,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(Icons.email_outlined),
                                errorText: _emailError,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: (_isSendingCode || _isUpdatingPassword)
                                  ? null
                                  : _sendCode,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: _isSendingCode
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Send Code'),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: (_isResendingCode ||
                                        _isSendingCode ||
                                        _isUpdatingPassword ||
                                        _resendCountdown > 0)
                                    ? null
                                    : _resendCode,
                                child: Text(
                                  _resendCountdown > 0
                                      ? 'Resend in ${_resendCountdown}s'
                                      : (_isResendingCode ? 'Resending...' : 'Resend Code'),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            AnimatedCrossFade(
                              duration: const Duration(milliseconds: 240),
                              crossFadeState: _hasRequestedCode
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              firstChild: const SizedBox.shrink(),
                              secondChild: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    controller: _codeController,
                                    enabled: !isBusy,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Verification Code',
                                      hintText: '6-digit code',
                                      prefixIcon: const Icon(Icons.verified_outlined),
                                      errorText: _codeError,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _newPasswordController,
                                    enabled: !isBusy,
                                    obscureText: _obscureNewPassword,
                                    decoration: InputDecoration(
                                      labelText: 'New Password',
                                      prefixIcon: const Icon(Icons.lock_outline),
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _obscureNewPassword = !_obscureNewPassword;
                                          });
                                        },
                                        icon: Icon(
                                          _obscureNewPassword
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                        ),
                                      ),
                                      errorText: _newPasswordError,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _confirmPasswordController,
                                    enabled: !isBusy,
                                    obscureText: _obscureConfirmPassword,
                                    decoration: InputDecoration(
                                      labelText: 'Confirm Password',
                                      prefixIcon: const Icon(Icons.lock_reset_outlined),
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _obscureConfirmPassword = !_obscureConfirmPassword;
                                          });
                                        },
                                        icon: Icon(
                                          _obscureConfirmPassword
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                        ),
                                      ),
                                      errorText: _confirmPasswordError,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  FilledButton(
                                    onPressed: isBusy ? null : _updatePassword,
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                    child: _isUpdatingPassword
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Text('Update Password'),
                                  ),
                                ],
                              ),
                            ),
                            if (_apiError != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _apiError!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
