// removed unused 'dart:math' - no longer used for splash sizing
import 'package:local_auth/local_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _backgroundFadeAnimation;

  bool _isInitialized = false;
  bool _hasError = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSplashSequence();
  }

  void _initializeAnimations() {
    // Logo animation controller
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Fade animation controller
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Logo scale animation with bounce effect
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    ));

    // Logo fade animation
    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    // Background fade animation
    _backgroundFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _startSplashSequence() async {
    try {
      // Start background fade
      _fadeAnimationController.forward();

      // Small delay then start logo animation
      await Future.delayed(const Duration(milliseconds: 300));
      _logoAnimationController.forward();

      // Simplified initialization - just wait for animations
      await Future.delayed(const Duration(milliseconds: 1500));

      setState(() {
        _isInitialized = true;
      });

      // Wait a bit more for user to see "Ready to connect!" message
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        _navigateToNextScreen();
      }
    } catch (e) {
      if (mounted) {
        _handleInitializationError();
      }
    }
  }



  void _handleInitializationError() {
    setState(() {
      _hasError = true;
    });

    if (_retryCount < _maxRetries) {
      // Show retry option after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _showRetryDialog();
        }
      });
    } else {
      // Max retries reached, show error state
      _showErrorState();
    }
  }

  void _showRetryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Connection Error',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'Unable to connect to Ispilo services. Please check your internet connection and try again.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _retryInitialization();
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToOfflineMode();
            },
            child: const Text('Continue Offline'),
          ),
        ],
      ),
    );
  }

  void _retryInitialization() {
    setState(() {
      _hasError = false;
      _retryCount++;
    });
    _startSplashSequence();
  }

  void _showErrorState() {
    // Navigate to offline mode or show persistent error
    _navigateToOfflineMode();
  }

  Future<void> _navigateToNextScreen() async {
    // Check if user is logged in
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final biometricEnabled = prefs.getBool('pref_biometric_auth') ?? false;

    if (token != null && token.isNotEmpty) {
      if (biometricEnabled) {
        // Prompt for fingerprint before entering
        final LocalAuthentication localAuth = LocalAuthentication();
        try {
          final bool didAuth = await localAuth.authenticate(
            localizedReason: 'Authenticate to access Ispilo',
            options: const AuthenticationOptions(biometricOnly: true, useErrorDialogs: true, stickyAuth: true),
          );
          if (didAuth) {
            if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.homeFeed);
          } else {
            // User cancelled biometric, redirect to login
             if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
          }
        } catch (e) {
          // If error (e.g. no biometrics available), fallback to login or home
          if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      } else {
        // User is logged in and no biometric required
        if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.homeFeed);
      }
    } else {
      // User is not logged in, go to login screen
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  void _navigateToOfflineMode() {
    // Navigate to login even in offline mode so they can try to login
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hide system status bar for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundFadeAnimation,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo section
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _logoAnimationController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _logoScaleAnimation.value,
                            child: Opacity(
                              opacity: _logoFadeAnimation.value,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // App logo: small unwrapped image (no white box)
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 2.h),
                                    child: Image.asset(
                                      'assets/images/Ispilo.png',
                                      width: 72, // small size
                                      height: 72,
                                      fit: BoxFit.contain,
                                      errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
                                    ),
                                  ),
                                  SizedBox(height: 3.h),
                                  // App name
                                  Text(
                                    'Ispilo',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineLarge
                                        ?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 32,
                                          letterSpacing: 2,
                                        ),
                                  ),
                                  SizedBox(height: 1.h),
                                  // Tagline
                                  Text(
                                    'Connect • Learn • Trade',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                          fontSize: 16,
                                          letterSpacing: 1,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Loading section
                  SizedBox(
                    height: 20.h,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_hasError) ...[
                            // Error state
                            CustomIconWidget(
                              iconName: 'error_outline',
                              color: Colors.red,
                              size: 32.w,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Connection Error',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: 16,
                                  ),
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              'Retrying... ($_retryCount/$_maxRetries)',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                    fontSize: 12.sp,
                                  ),
                            ),
                          ] else ...[
                            // Loading state
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: SizedBox(
                                width: 18.w,
                                height: 18.w,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppTheme.lightTheme.colorScheme.primary),
                                    strokeWidth: 3,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              _isInitialized
                                  ? 'Ready to connect!'
                                  : 'Initializing...',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
                                    fontSize: 16,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Bottom section with version info
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Column(
                      children: [
                        Text(
                          'ISP Community Platform',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                    fontSize: 12.sp,
                                  ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Version 1.0.0',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                    fontSize: 12,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Custom exception for timeout handling
class TimeoutException implements Exception {
  final String message;
  const TimeoutException([this.message = 'Operation timed out']);

  @override
  String toString() => 'TimeoutException: $message';
}
