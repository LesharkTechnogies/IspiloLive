import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../core/theme_provider.dart';
import '../../core/services/user_service.dart';
import '../../widgets/fullscreen_image_viewer.dart';
import '../../widgets/custom_bottom_bar.dart';
// Use social_repository which provides PostRepository and a UserModel-backed UserRepository
import './widgets/settings_section_widget.dart';
import './widgets/settings_switch_widget.dart';
import './widgets/settings_tile_widget.dart';
import 'change_password.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  static const String _prefProfileAvatarUrl = 'pref_profile_avatar_url';
  // Pref keys
  static const String _prefBiometric = 'pref_biometric_auth';
  static const String _prefTwoFactor = 'pref_two_factor';
  static const String _prefAccountVisibility = 'pref_account_visibility';
  static const String _prefSocialNotifs = 'pref_social_notifs';
  static const String _prefMessageNotifs = 'pref_message_notifs';
  static const String _prefEducationNotifs = 'pref_education_notifs';
  static const String _prefMarketplaceNotifs = 'pref_marketplace_notifs';
  static const String _prefHighContrast = 'pref_high_contrast';
  static const String _prefOfflineContent = 'pref_offline_content';
  static const String _prefOfflineMessages = 'pref_offline_messages';

  // Settings state variables
  bool _biometricAuth = false;
  String? _cachedAvatarUrl;
  bool _twoFactorAuth = false;
  bool _accountVisibility = true;
  bool _socialNotifications = true;
  bool _messageNotifications = true;
  bool _educationNotifications = false;
  bool _marketplaceNotifications = true;
  bool _darkMode = false;
  bool _systemTheme = true;
  bool _highContrast = false;
  bool _offlineContent = true;
  bool _offlineMessages = true;

  final LocalAuthentication _localAuth = LocalAuthentication();

  // User profile and stats from API
  Map<String, dynamic>? _userProfile;
  // Cached current user model (from social feed models)
  int _postCount = 0;
  int _followers = 0;
  int _following = 0;
  int _connections = 0;

  static const Duration _createShopLabelVisibleDuration = Duration(minutes: 1);
  Timer? _createShopLabelTimer;
  bool _showCreateShopLabel = true;
  Offset? _createShopButtonOffset;

  Future<void> _loadUserProfileAndStats() async {
    try {
      final user = await UserService.getCurrentUser();
      final avatar = user['avatar']?.toString() ??
          user['avatarUrl']?.toString() ??
          user['profileImage']?.toString() ??
          user['profilePicture']?.toString() ??
          '';

      if (avatar.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefProfileAvatarUrl, avatar);
      }

      setState(() {
        _userProfile = user;
        if (avatar.isNotEmpty) {
          _cachedAvatarUrl = avatar;
        }
      });

      // Fetch user stats
      final stats = await UserService.getUserStats();
      setState(() {
        _postCount = (stats['posts'] ?? stats['postCount'] ?? 0) as int;
        _followers = (stats['followers'] ?? stats['followersCount'] ?? 0) as int;
        _following = (stats['following'] ?? stats['followingCount'] ?? 0) as int;
        _connections = (stats['connections'] ?? stats['connectionsCount'] ?? 0) as int;
      });
    } catch (e) {
      debugPrint('Failed to load user profile: $e');
    }
  }

  // Use shared current user profile from API
  Map<String, dynamic> get _userProfileData => _userProfile != null
      ? {
          'name': _userProfile!['name'] ?? _userProfile!['firstName'] ?? 'User',
          'username': _userProfile!['username'] ?? '',
          'email': _userProfile!['email'] ?? '',
          'avatar': _userProfile!['avatar'] ??
              _userProfile!['avatarUrl'] ??
              _userProfile!['profileImage'] ??
              _userProfile!['profilePicture'] ??
              _cachedAvatarUrl ??
              '',
          'bio': _userProfile!['bio'] ?? '',
          'verified': _userProfile!['isVerified'] ?? false,
          'location': _userProfile!['location'] ?? _userProfile!['town'] ?? '',
          'phone': _userProfile!['phone'] ?? '',
          'phonePrivacyPublic': _userProfile!['phonePrivacyPublic'] ?? false,
          'posts': _postCount,
          'followers': _followers,
          'following': _following,
          'connections': _connections,
        }
      : {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadCachedAvatar();
    _loadUserProfileAndStats();
    _startCreateShopLabelTimer();
  }

  Future<void> _loadCachedAvatar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_prefProfileAvatarUrl);
      if (cached == null || cached.isEmpty) return;
      if (!mounted) return;
      setState(() {
        _cachedAvatarUrl = cached;
      });
    } catch (_) {
      // Best effort only.
    }
  }

  @override
  void dispose() {
    _createShopLabelTimer?.cancel();
    super.dispose();
  }

  void _startCreateShopLabelTimer() {
    _createShopLabelTimer?.cancel();
    _createShopLabelTimer =
        Timer(_createShopLabelVisibleDuration, () {
      if (!mounted) return;
      setState(() {
        _showCreateShopLabel = false;
      });
    });
  }

  void _ensureCreateShopButtonOffset() {
    if (_createShopButtonOffset != null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _createShopButtonOffset != null) return;
      final size = MediaQuery.of(context).size;
      const margin = 16.0;
      final initialOffset = Offset(
        size.width - _createShopButtonWidth - margin,
        size.height - _createShopButtonHeight - _createShopBottomInset,
      );

      setState(() {
        _createShopButtonOffset = initialOffset;
      });
    });
  }

  double get _createShopButtonWidth => _showCreateShopLabel ? 168.0 : 56.0;
  double get _createShopButtonHeight => 56.0;
  double get _createShopBottomInset => 110.0;

  void _updateCreateShopButtonPosition(Offset delta) {
    final size = MediaQuery.of(context).size;
    const margin = 16.0;

    final current = _createShopButtonOffset ??
        Offset(
          size.width - _createShopButtonWidth - margin,
          size.height - _createShopButtonHeight - _createShopBottomInset,
        );

    final maxX = (size.width - _createShopButtonWidth - margin).clamp(margin, size.width);
    final maxY =
        (size.height - _createShopButtonHeight - _createShopBottomInset).clamp(margin, size.height);

    setState(() {
      _createShopButtonOffset = Offset(
        (current.dx + delta.dx).clamp(margin, maxX.toDouble()),
        (current.dy + delta.dy).clamp(margin, maxY.toDouble()),
      );
    });
  }

  Future<void> _handleCreateShopPressed() async {
    final prefs = await SharedPreferences.getInstance();
    final isShopRegistered = prefs.getInt('shopregidtered') ?? 0;
    if (!mounted) return;

    if (isShopRegistered == 1) {
      Navigator.pushNamed(context, '/sell-something');
    } else {
      Navigator.pushNamed(context, '/shop-registration-step1');
    }
  }

  Widget _buildCreateShopDraggableButton(ThemeData theme) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) => _updateCreateShopButtonPosition(details.delta),
      child: Material(
        color: Colors.transparent,
        elevation: 8,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: _handleCreateShopPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            height: _createShopButtonHeight,
            padding: EdgeInsets.symmetric(
              horizontal: _showCreateShopLabel ? 16 : 0,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.store,
                  color: theme.colorScheme.onPrimary,
                ),
                if (_showCreateShopLabel) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Create Shop',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _biometricAuth = prefs.getBool(_prefBiometric) ?? false;
      _twoFactorAuth = prefs.getBool(_prefTwoFactor) ?? false;
      _accountVisibility = prefs.getBool(_prefAccountVisibility) ?? true;
      _socialNotifications = prefs.getBool(_prefSocialNotifs) ?? true;
      _messageNotifications = prefs.getBool(_prefMessageNotifs) ?? true;
      _educationNotifications = prefs.getBool(_prefEducationNotifs) ?? false;
      _marketplaceNotifications = prefs.getBool(_prefMarketplaceNotifs) ?? true;
      _highContrast = prefs.getBool(_prefHighContrast) ?? false;
      _offlineContent = prefs.getBool(_prefOfflineContent) ?? true;
      _offlineMessages = prefs.getBool(_prefOfflineMessages) ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefBiometric, _biometricAuth);
    await prefs.setBool(_prefTwoFactor, _twoFactorAuth);
    await prefs.setBool(_prefAccountVisibility, _accountVisibility);
    await prefs.setBool(_prefSocialNotifs, _socialNotifications);
    await prefs.setBool(_prefMessageNotifs, _messageNotifications);
    await prefs.setBool(_prefEducationNotifs, _educationNotifications);
    await prefs.setBool(_prefMarketplaceNotifs, _marketplaceNotifications);
    await prefs.setBool(_prefHighContrast, _highContrast);
    await prefs.setBool(_prefOfflineContent, _offlineContent);
    await prefs.setBool(_prefOfflineMessages, _offlineMessages);
  }

  Future<void> _handleBiometricToggle(bool value) async {
    HapticFeedback.lightImpact();
    if (value) {
      try {
        final bool canCheck = await _localAuth.canCheckBiometrics ||
            await _localAuth.isDeviceSupported();
        if (!canCheck) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Biometrics not available on this device')),
          );
          return;
        }
        final bool didAuth = await _localAuth.authenticate(
          localizedReason: 'Authenticate to enable biometric unlock',
          options: const AuthenticationOptions(
              biometricOnly: true, stickyAuth: true),
        );
        if (didAuth) {
          setState(() => _biometricAuth = true);
          await _saveSettings();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric authentication enabled')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Biometric setup failed: $e')),
        );
      }
    } else {
      setState(() => _biometricAuth = false);
      await _saveSettings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric authentication disabled')),
      );
    }
  }

  void _handleTwoFactorToggle(bool value) {
    HapticFeedback.lightImpact();
    setState(() => _twoFactorAuth = value);
    _saveSettings();
    if (value) {
      _showTwoFactorSetupDialog();
    }
  }

  void _handleNotificationToggle(String type, bool value) {
    HapticFeedback.lightImpact();
    setState(() {
      switch (type) {
        case 'social':
          _socialNotifications = value;
          break;
        case 'messages':
          _messageNotifications = value;
          break;
        case 'education':
          _educationNotifications = value;
          break;
        case 'marketplace':
          _marketplaceNotifications = value;
          break;
      }
    });
    _saveSettings();
  }

  void _handleThemeToggle(String type, bool value) {
    HapticFeedback.lightImpact();
    final themeProvider = context.read<ThemeProvider>();

    switch (type) {
      case 'dark':
        if (value) {
          themeProvider.setThemeMode(ThemeMode.dark);
        } else {
          themeProvider.setThemeMode(ThemeMode.light);
        }
        break;
      case 'system':
        if (value) {
          themeProvider.setThemeMode(ThemeMode.system);
        } else {
          themeProvider.setThemeMode(ThemeMode.light);
        }
        break;
      case 'contrast':
        _highContrast = value;
        _saveSettings();
        break;
      case 'text':
        themeProvider.setLargeTextEnabled(value);
        break;
    }

    setState(() {
      _darkMode = themeProvider.themeMode == ThemeMode.dark;
      _systemTheme = themeProvider.themeMode == ThemeMode.system;
    });
  }

  void _handleEditProfile() async {
    await Navigator.pushNamed(context, '/edit-profile');
    if (mounted) {
      _loadUserProfileAndStats();
    }
  }

  void _handlePasswordChange() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
    );
  }

  void _handleDataUsage() {
    HapticFeedback.lightImpact();
  }

  void _handleClearCache() {
    HapticFeedback.mediumImpact();
    _showClearCacheDialog();
  }

  void _handleFAQ() {
    HapticFeedback.lightImpact();
  }

  void _handleContactSupport() {
    HapticFeedback.lightImpact();
  }

  void _handleFeedback() {
    HapticFeedback.lightImpact();
  }

  void _handleGuidelines() {
    HapticFeedback.lightImpact();
  }

  void _handleTerms() {
    HapticFeedback.lightImpact();
  }

  void _handlePrivacyPolicy() {
    HapticFeedback.lightImpact();
  }

  void _handleLicenses() {
    HapticFeedback.lightImpact();
  }

  void _handleLogout() {
    HapticFeedback.mediumImpact();
    _showLogoutDialog();
  }

  void _handleDeleteAccount() {
    HapticFeedback.heavyImpact();
    _showDeleteAccountDialog();
  }

  void _showTwoFactorSetupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setup Two-Factor Authentication'),
        content: const Text(
          'Two-factor authentication adds an extra layer of security to your account. You will need to verify your phone number to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _twoFactorAuth = true;
              });
              _saveSettings();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Two-factor authentication enabled'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Setup'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear all cached data including offline content. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              // Clear SharedPreferences data (including auth token)
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              if (!mounted) return;
              // Navigate to Login screen and remove all other routes
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              try {
                // Call backend delete account
                await UserService.deleteAccount();
                
                // Clear state and logout
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account deleted successfully.'),
                    duration: Duration(seconds: 3),
                  ),
                );

                // Exit to login screen
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete account: $e'),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Use the null-safe getter so all accesses are on a non-nullable Map
    final p = _userProfileData;

    return Column(
      children: [
        // Cover Image
        if (p['coverImage'] != null)
          GestureDetector(
            onTap: () {
              final url = p['coverImage'] as String? ?? '';
              if (url.isEmpty) return;
              showDialog(
                context: context,
                builder: (_) =>
                    FullScreenImageViewer(imageUrl: url, heroTag: 'cover_$url'),
              );
            },
            child: Container(
              height: 20.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
              ),
              child: Hero(
                tag: 'cover_${p['coverImage']}',
                child: CustomImageWidget(
                  imageUrl: p['coverImage'] as String? ?? '',
                  width: double.infinity,
                  height: 20.h,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

        // Profile Structure
        Transform.translate(
          offset: Offset(0, p['coverImage'] != null ? -30 : 10),
          child: Column(
            children: [
              // Main Profile Box
              Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.75.h),
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16), 
                  boxShadow: [
                    BoxShadow(
                      color: Colors.lightGreen.withAlpha(40),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Edit Profile Row (align right)
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: _handleEditProfile,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                          decoration: BoxDecoration(
                            border: Border.all(color: colorScheme.primary),
                            borderRadius: BorderRadius.circular(20),
                            color: colorScheme.primary.withAlpha(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomIconWidget(
                                iconName: 'edit',
                                color: colorScheme.primary,
                                size: 14,
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                'Edit Profile',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar Left
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                final url = p['avatar'] as String? ?? '';
                                if (url.isEmpty) return;
                                showDialog(
                                  context: context,
                                  builder: (_) => FullScreenImageViewer(
                                      imageUrl: url, heroTag: 'avatar_$url'),
                                );
                              },
                              child: Container(
                              width: 80,
                              height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                color: colorScheme.primary.withAlpha(20),
                                  border: Border.all(
                                    color: colorScheme.surface,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(20),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(40),
                                child: (p['avatar'] as String?)?.isNotEmpty == true
                                    ? Hero(
                                        tag: 'avatar_${p['avatar']}',
                                        child: CustomImageWidget(
                                          imageUrl: p['avatar'] as String,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          (p['name'] as String?)?.isNotEmpty == true ? (p['name'] as String)[0].toUpperCase() : 'U',
                                          style: GoogleFonts.inter(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w700,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                      ),
                              ),
                              ),
                            ),
                            if (p['verified'] == true)
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colorScheme.surface,
                                      width: 2,
                                    ),
                                  ),
                                  child: CustomIconWidget(
                                    iconName: 'check',
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(width: 4.w),
                        // Profile Information Right
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p['name'] as String? ?? 'User',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (p['username'] != null && (p['username'] as String).isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    p['username'] as String,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurface.withAlpha(150),
                                    ),
                                  ),
                                ),
                              SizedBox(height: 1.h),
                              if (p['phone'] != null && (p['phone'] as String).isNotEmpty)
                                Row(
                                  children: [
                                    Icon(Icons.phone, size: 14, color: colorScheme.secondary),
                                    SizedBox(width: 1.w),
                                    Expanded(
                                      child: Text(
                                        p['phone'] as String,
                                        style: theme.textTheme.bodySmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              if (p['location'] != null && (p['location'] as String).isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.location_on, size: 14, color: colorScheme.secondary),
                                      SizedBox(width: 1.w),
                                      Expanded(
                                        child: Text(
                                          p['location'] as String,
                                          style: theme.textTheme.bodySmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (p['bio'] != null && (p['bio'] as String).isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    p['bio'] as String,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      height: 1.3,
                                      fontStyle: FontStyle.italic,
                                      color: colorScheme.onSurface.withAlpha(200),
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Stats Box
              Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.75.h),
                padding: EdgeInsets.symmetric(vertical: 2.h),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.lightGreen.withAlpha(40),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn(
                      count: p['posts'] as int? ?? 0,
                      label: 'Posts',
                      theme: theme,
                    ),
                    _buildStatColumn(
                      count: p['followers'] as int? ?? 0,
                      label: 'Followers',
                      theme: theme,
                    ),
                    _buildStatColumn(
                      count: p['following'] as int? ?? 0,
                      label: 'Following',
                      theme: theme,
                    ),
                    _buildStatColumn(
                      count: p['connections'] as int? ?? 0,
                      label: 'Connections',
                      theme: theme,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn({
    required int count,
    required String label,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Text(
          count >= 1000
              ? '${(count / 1000).toStringAsFixed(1)}K'
              : count.toString(),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  // Helper to update avatar online and cache locally
//  Future<void> _updateAvatar(String newAvatarUrl) async {
//    //
//  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<int>(
      future: SharedPreferences.getInstance().then((prefs) => prefs.getInt('shopregidtered') ?? 0),
      builder: (context, snapshot) {
        final isShopRegistered = snapshot.data == 1;
        if (!isShopRegistered) {
          _ensureCreateShopButtonOffset();
        }
        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              _darkMode = themeProvider.themeMode == ThemeMode.dark;
              _systemTheme = themeProvider.themeMode == ThemeMode.system;

              return Stack(
                children: [
                  ListView(
                    padding: EdgeInsets.zero, // Forces the profile header all the way to the screen's absolute top edge
                    children: [
                      _buildProfileHeader(),

                      SizedBox(height: 1.h),
                      SettingsSectionWidget(
                title: 'Privacy & Security',
                children: [
                  SettingsSwitchWidget(
                    title: 'Biometric Authentication',
                    subtitle: 'Use fingerprint or face ID to unlock the app',
                    iconName: 'fingerprint',
                    value: _biometricAuth,
                    onChanged: _handleBiometricToggle,
                  ),
                  SettingsTileWidget(
                    title: 'Change Password',
                    subtitle: 'Update your account password',
                    iconName: 'lock_outline',
                    onTap: _handlePasswordChange,
                  ),
                  SettingsSwitchWidget(
                    title: 'Two-Factor Authentication',
                    subtitle: 'Add an extra layer of security',
                    iconName: 'security',
                    value: _twoFactorAuth,
                    onChanged: _handleTwoFactorToggle,
                  ),
                  SettingsSwitchWidget(
                    title: 'Public Profile',
                    subtitle: 'Allow others to find and view your profile',
                    iconName: 'visibility',
                    value: _accountVisibility,
                    onChanged: (value) {
                      setState(() {
                        _accountVisibility = value;
                      });
                      _saveSettings();
                    },
                    showDivider: false,
                  ),
                ],
              ),
              SettingsSectionWidget(
                title: 'Notifications',
                children: [
                  SettingsSwitchWidget(
                    title: 'Social Interactions',
                    subtitle: 'Likes, comments, follows, and mentions',
                    iconName: 'favorite_outline',
                    value: _socialNotifications,
                    onChanged: (value) =>
                        _handleNotificationToggle('social', value),
                  ),
                  SettingsSwitchWidget(
                    title: 'Messages',
                    subtitle: 'Direct messages and chat notifications',
                    iconName: 'message_outlined',
                    value: _messageNotifications,
                    onChanged: (value) =>
                        _handleNotificationToggle('messages', value),
                  ),
                  SettingsSwitchWidget(
                    title: 'Education Reminders',
                    subtitle: 'Course updates and learning reminders',
                    iconName: 'school_outlined',
                    value: _educationNotifications,
                    onChanged: (value) =>
                        _handleNotificationToggle('education', value),
                  ),
                  SettingsSwitchWidget(
                    title: 'Marketplace Alerts',
                    subtitle: 'Product updates and transaction notifications',
                    iconName: 'shopping_bag_outlined',
                    value: _marketplaceNotifications,
                    onChanged: (value) =>
                        _handleNotificationToggle('marketplace', value),
                    showDivider: false,
                  ),
                ],
              ),
              SettingsSectionWidget(
                title: 'Appearance',
                children: [
                  SettingsSwitchWidget(
                    title: 'Use System Theme',
                    subtitle: 'Follow device dark/light mode setting',
                    iconName: 'brightness_auto',
                    value: _systemTheme,
                    onChanged: (value) => _handleThemeToggle('system', value),
                  ),
                  SettingsSwitchWidget(
                    title: 'Dark Mode',
                    subtitle: 'Use dark theme for better night viewing',
                    iconName: 'dark_mode',
                    value: _darkMode,
                    onChanged: (value) => _handleThemeToggle('dark', value),
                  ),
                  SettingsSwitchWidget(
                    title: 'High Contrast',
                    subtitle: 'Increase contrast for better visibility',
                    iconName: 'contrast',
                    value: _highContrast,
                    onChanged: (value) => _handleThemeToggle('contrast', value),
                  ),
                  SettingsSwitchWidget(
                    title: 'Large Text',
                    subtitle: 'Increase text size across the entire app',
                    iconName: 'text_fields',
                    value: themeProvider.largeTextEnabled,
                    onChanged: (value) => _handleThemeToggle('text', value),
                    showDivider: false,
                  ),
                ],
              ),
              SettingsSectionWidget(
                title: 'Data & Storage',
                children: [
                  SettingsSwitchWidget(
                    title: 'Offline Content',
                    subtitle: 'Download content for offline access',
                    iconName: 'cloud_download',
                    value: _offlineContent,
                    onChanged: (value) {
                      setState(() {
                        _offlineContent = value;
                      });
                      _saveSettings();
                    },
                  ),
                  SettingsSwitchWidget(
                    title: 'Offline Messages',
                    subtitle: 'Keep recent chats available offline',
                    iconName: 'chat_bubble_outline',
                    value: _offlineMessages,
                    onChanged: (value) {
                      setState(() {
                        _offlineMessages = value;
                      });
                      _saveSettings();
                    },
                  ),
                  SettingsTileWidget(
                    title: 'Data Usage',
                    subtitle: 'View and manage data consumption',
                    iconName: 'data_usage',
                    onTap: _handleDataUsage,
                  ),
                  SettingsTileWidget(
                    title: 'Clear Cache',
                    subtitle: 'Free up storage space',
                    iconName: 'delete_outline',
                    onTap: _handleClearCache,
                    showDivider: false,
                  ),
                ],
              ),
              SettingsSectionWidget(
                title: 'Groups',
                children: [
                  SettingsTileWidget(
                    title: 'Create Group',
                    subtitle: 'Create a new community group',
                    iconName: 'group_add',
                    onTap: () {
                      Navigator.pushNamed(context, '/create-group');
                    },
                    showDivider: false,
                  ),
                ],
              ),
              SettingsSectionWidget(
                title: 'Help & Support',
                children: [
                  SettingsTileWidget(
                    title: 'Frequently Asked Questions',
                    subtitle: 'Find answers to common questions',
                    iconName: 'help_outline',
                    onTap: _handleFAQ,
                  ),
                  SettingsTileWidget(
                    title: 'Contact Support',
                    subtitle: 'Get help from our support team',
                    iconName: 'support_agent',
                    onTap: _handleContactSupport,
                  ),
                  SettingsTileWidget(
                    title: 'Send Feedback',
                    subtitle: 'Help us improve the app',
                    iconName: 'feedback_outlined',
                    onTap: _handleFeedback,
                  ),
                  SettingsTileWidget(
                    title: 'Community Guidelines',
                    subtitle: 'Learn about our community standards',
                    iconName: 'gavel',
                    onTap: _handleGuidelines,
                    showDivider: false,
                  ),
                ],
              ),
              SettingsSectionWidget(
                title: 'About',
                children: [
                  SettingsTileWidget(
                    title: 'App Version',
                    subtitle: '2.1.0 (Build 42)',
                    iconName: 'info_outline',
                  ),
                  SettingsTileWidget(
                    title: 'Terms of Service',
                    iconName: 'description',
                    onTap: _handleTerms,
                  ),
                  SettingsTileWidget(
                    title: 'Privacy Policy',
                    iconName: 'privacy_tip',
                    onTap: _handlePrivacyPolicy,
                  ),
                  SettingsTileWidget(
                    title: 'Open Source Licenses',
                    iconName: 'code',
                    onTap: _handleLicenses,
                    showDivider: false,
                  ),
                ],
              ),
              SettingsSectionWidget(
                title: 'Account',
                children: [
                  SettingsTileWidget(
                    title: 'Logout',
                    iconName: 'logout',
                    onTap: _handleLogout,
                    trailing: const SizedBox.shrink(),
                  ),
                  SettingsTileWidget(
                    title: 'Delete Account',
                    subtitle: 'Permanently delete your account and data',
                    iconName: 'delete_forever',
                    onTap: _handleDeleteAccount,
                    trailing: const SizedBox.shrink(),
                    showDivider: false,
                  ),
                ],
              ),
                      SizedBox(height: 4.h),
                    ],
                  ),
                  if (!isShopRegistered && _createShopButtonOffset != null)
                    Positioned(
                      left: _createShopButtonOffset!.dx,
                      top: _createShopButtonOffset!.dy,
                      child: _buildCreateShopDraggableButton(theme),
                    ),
                ],
              );
            },
          ),
          bottomNavigationBar: const CustomBottomBar(
            currentIndex: 3,
            variant: CustomBottomBarVariant.standard,
          ),
        );
      },
    );
  }
}
