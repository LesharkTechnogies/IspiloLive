import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';

import 'core/app_export.dart';
import 'core/theme_provider.dart';
import 'core/services/version_service.dart';
import 'widgets/custom_error_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return CustomErrorWidget(
      errorDetails: details,
    );
  };
  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  // Run orientation lock and version check in parallel
  await Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
    VersionService.checkAndLog(),
  ]);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  DateTime? _pausedTime;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _checkBiometricLock();
    }
  }

  Future<void> _checkBiometricLock() async {
    if (_pausedTime == null) return;

    final elapsed = DateTime.now().difference(_pausedTime!);
    // If parked in background for more than 5 minutes
    if (elapsed.inMinutes >= 5) {
      final prefs = await SharedPreferences.getInstance();
      final biometricEnabled = prefs.getBool('pref_biometric_auth') ?? false;
      final token = prefs.getString('auth_token');

      // Only lock if biometric is enabled and user is logged in
      if (biometricEnabled && token != null && token.isNotEmpty) {
        // We push a biometric lock route
        _navigatorKey.currentState?.push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => BiometricLockScreen(localAuth: _localAuth),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, screenType) {
      return ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return MaterialApp(
              navigatorKey: _navigatorKey,
              title: 'Ispilo',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
              builder: (context, child) {
                final bool largeTextEnabled = themeProvider.largeTextEnabled;
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(largeTextEnabled ? 1.4 : 1.0),
                    viewPadding: MediaQuery.of(context).viewPadding.copyWith(
                          bottom: MediaQuery.of(context)
                              .viewPadding
                              .bottom
                              .clamp(0.0, 34.0),
                        ),
                  ),
                  child: child!,
                );
              },
              // 🚨 END CRITICAL SECTION
              debugShowCheckedModeBanner: false,
              routes: AppRoutes.routes,
              initialRoute: AppRoutes.initial,
            );
          },
        ),
      );
    });
  }
}

class BiometricLockScreen extends StatefulWidget {
  final LocalAuthentication localAuth;
  const BiometricLockScreen({super.key, required this.localAuth});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    try {
      final didAuth = await widget.localAuth.authenticate(
        localizedReason: 'Authenticate to resume Ispilo',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (didAuth && mounted) {
        Navigator.pop(context); // close lock screen
      }
    } catch (_) {
      // Error or not setup natively
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text('App Locked', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _authenticate,
              icon: const Icon(Icons.fingerprint, size: 32),
              label: const Text('Unlock with Biometrics'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
