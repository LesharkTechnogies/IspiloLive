import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Added for kIsWeb
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/cloudinary_service.dart';
import '../../model/repository/social_repository.dart';
import '../../core/services/user_service.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../core/services/media_download_service.dart';
import '../../widgets/fullscreen_image_viewer.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  static const String _prefAvatarUrl = 'pref_profile_avatar_url';
  static const String _prefAvatarSyncState = 'pref_profile_avatar_sync_state';
  static const String _prefPhoneNumber = 'pref_profile_phone';

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _companyCtrl = TextEditingController();
  final TextEditingController _townCtrl = TextEditingController();
  final TextEditingController _quoteCtrl = TextEditingController();
  bool _avatarPublic = true;
  String? _avatarPath;
  bool _saving = false;
  int _avatarSyncState = 0;

  int _followers = 0;
  int _following = 0;
  int _connections = 0;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadFromPreferences();
    _loadFromBackend();
  }

  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedAvatarUrl = prefs.getString(_prefAvatarUrl);
      final cachedSyncState = prefs.getInt(_prefAvatarSyncState) ?? 0;
      final cachedPhone = prefs.getString(_prefPhoneNumber) ?? '';

      if (!mounted) return;
      setState(() {
        _avatarSyncState = cachedSyncState;
        if ((cachedAvatarUrl ?? '').isNotEmpty && (_avatarPath?.isEmpty ?? true)) {
          _avatarPath = cachedAvatarUrl;
        }
        if (cachedPhone.isNotEmpty) {
          _phoneCtrl.text = cachedPhone;
        }
      });
    } catch (_) {
      // Best effort only.
    }
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Future<void> _loadFromBackend() async {
    try {
      final stats = await UserService.getUserStats();
      if (mounted) {
        setState(() {
          _followers = _parseInt(stats['followersCount'] ?? stats['followers']);
          _following = _parseInt(stats['followingCount'] ?? stats['following']);
          _connections = _parseInt(stats['connectionsCount'] ?? stats['connections']);
        });
      }
    } catch (e) {
      debugPrint('Failed to load user stats: $e');
    }

    try {
      final user = await UserRepository.getCurrentUser();
      if (mounted) {
        setState(() {
          _nameCtrl.text = user.name;
          _emailCtrl.text = user.username;
          _companyCtrl.text = user.company ?? '';
          _townCtrl.text = user.town ?? '';
          _quoteCtrl.text = user.bio ?? user.quote ?? '';
          if (user.avatar.isNotEmpty) {
            _avatarPath = user.avatar;
          }
          _avatarPublic = user.avatarPublic;
        });

      }
    } catch (e) {
      debugPrint('Failed to load user from backend: $e');
    }

    try {
      final profile = await UserService.getCurrentUser();
      final phone = profile['phone']?.toString() ?? '';
      final avatar = profile['avatar']?.toString() ??
          profile['avatarUrl']?.toString() ??
          profile['profileImage']?.toString() ??
          profile['profilePicture']?.toString() ?? '';

      final prefs = await SharedPreferences.getInstance();
      if (avatar.isNotEmpty) {
        await prefs.setString(_prefAvatarUrl, avatar);
        await prefs.setInt(_prefAvatarSyncState, 1);
      }
      if (phone.isNotEmpty) {
        await prefs.setString(_prefPhoneNumber, phone);
      }

      if (!mounted) return;
      setState(() {
        if (phone.isNotEmpty) {
          _phoneCtrl.text = phone;
        }
        if (avatar.isNotEmpty) {
          _avatarPath = avatar;
          _avatarSyncState = 1;
        }
      });
    } catch (e) {
      debugPrint('Failed to load phone/profile cache: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    // Build selective payload to avoid overwriting unchanged fields on backend
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedAvatarUrl = prefs.getString(_prefAvatarUrl) ?? '';
      final syncState = prefs.getInt(_prefAvatarSyncState) ?? _avatarSyncState;
      bool shouldSyncAvatar = false;
      String? uploadedAvatarUrl;
      // Update avatar if picked
      if (_avatarPath != null && _avatarPath!.isNotEmpty) {
        // Only trigger update if it's a local file picked or a blob url (not a remote http url)
        final isLocalFile = !_avatarPath!.startsWith('http') || _avatarPath!.startsWith('blob:');
        if (isLocalFile) {
          await prefs.setInt(_prefAvatarSyncState, 0);
          _avatarSyncState = 0;
          final originalPath = _avatarPath!;
          uploadedAvatarUrl = await CloudinaryService.uploadFile(originalPath);
            if (uploadedAvatarUrl != null) {
              _avatarPath = uploadedAvatarUrl; // Switch local path to the permanent URL
              shouldSyncAvatar = true;
          } else {
            try {
              // Fallback to backend multipart upload ONLY if Cloudinary fails
              await UserService.updateAvatar(originalPath);
            } catch (e) {
              debugPrint('Multipart upload failed: $e');
            }
          }
        } else {
          final sameAsCache = cachedAvatarUrl.isNotEmpty && cachedAvatarUrl == _avatarPath;
          if (syncState == 0 || !sameAsCache) {
            uploadedAvatarUrl = _avatarPath; // Re-sync the existing URL to the database
            shouldSyncAvatar = true;
          }
        }
      }

      // Update basic fields and avatar via UserRepository
      await UserRepository.updateProfile(
        name: _nameCtrl.text.trim(),
        bio: _quoteCtrl.text.trim(),
        quote: _quoteCtrl.text.trim(),
        location: _townCtrl.text.trim(),
        company: _companyCtrl.text.trim(),
        avatar: shouldSyncAvatar ? uploadedAvatarUrl : null,
        avatarPublic: _avatarPublic,
      );
      if (shouldSyncAvatar && (uploadedAvatarUrl ?? '').isNotEmpty) {
        await prefs.setString(_prefAvatarUrl, uploadedAvatarUrl!);
        await prefs.setInt(_prefAvatarSyncState, 1);
        _avatarSyncState = 1;
      }

      final phone = _phoneCtrl.text.trim();
      if (phone.isNotEmpty) {
        await prefs.setString(_prefPhoneNumber, phone);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      // Refetch latest profile from backend to ensure UI reflects server state
      // No need to call _loadFromBackend() again as updateProfile returns the updated user.
      // Just pop the screen.
      if (mounted) {
        setState(() => _saving = false);
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  Future<void> _pickAvatar() async {
    final result =
        await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefAvatarSyncState, 0);
      setState(() {
        _avatarSyncState = 0;
        _avatarPath = result.path;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _companyCtrl.dispose();
    _townCtrl.dispose();
    _quoteCtrl.dispose();
    super.dispose();
  }

  Widget _buildStatItem(String label, String value, Color textColor) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        SizedBox(height: 0.4.h),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: textColor.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_avatarPath != null && _avatarPath!.startsWith('http') && !_avatarPath!.startsWith('blob:')) {
                          showDialog(
                            context: context,
                            builder: (_) => FullScreenImageViewer(imageUrl: _avatarPath!),
                          );
                        } else {
                          _pickAvatar();
                        }
                      },
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor:
                            colorScheme.outline.withValues(alpha: 0.2),
                        backgroundImage: _avatarPath != null && _avatarPath!.isNotEmpty
                            ? ((kIsWeb || _avatarPath!.startsWith('http'))
                                ? NetworkImage(_avatarPath!)
                                : FileImage(File(_avatarPath!))
                                    as ImageProvider)
                            : null,
                        child: _avatarPath == null || _avatarPath!.isEmpty
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                    ),
                    if (_avatarPath != null && _avatarPath!.startsWith('http') && !_avatarPath!.startsWith('blob:'))
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: InkWell(
                          onTap: () async {
                            final ext = _avatarPath!.split('.').last.split('?').first;
                            final name = 'ispilo_avatar_${DateTime.now().millisecondsSinceEpoch}.${ext.isEmpty ? 'jpg' : ext}';
                            await MediaDownloadService.downloadFile(_avatarPath!, name, context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.secondary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: Icon(Icons.download, color: colorScheme.onSecondary, size: 18),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickAvatar,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.edit,
                              color: colorScheme.onPrimary, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 3.h),
              Container(
                padding: EdgeInsets.symmetric(vertical: 1.8.h, horizontal: 4.w),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Followers', _followers.toString(), colorScheme.onSurface),
                    _buildStatItem('Following', _following.toString(), colorScheme.onSurface),
                    _buildStatItem('Connections', _connections.toString(), colorScheme.onSurface),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                ),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: 1.5.h),
              TextFormField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Username',
                ),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: 1.5.h),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final emailReg = RegExp(r'^.+@.+\..+');
                  return emailReg.hasMatch(v.trim()) ? null : 'Invalid email';
                },
              ),
              SizedBox(height: 1.5.h),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().length < 7) ? 'Invalid phone' : null,
              ),
              SizedBox(height: 1.5.h),
              TextFormField(
                controller: _companyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Company (e.g., Leshark Technologies)',
                ),
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 1.5.h),
              TextFormField(
                controller: _townCtrl,
                decoration: const InputDecoration(
                  labelText: 'Town/Location',
                ),
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 1.5.h),
              TextFormField(
                controller: _quoteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Quote / About You',
                ),
                maxLines: 2,
                textInputAction: TextInputAction.newline,
              ),
              SizedBox(height: 1.5.h),
              SwitchListTile(
                value: _avatarPublic,
                title: const Text('Make profile picture public'),
                subtitle: const Text('If off, others will see a generic icon'),
                onChanged: (v) => setState(() => _avatarPublic = v),
              ),
              SizedBox(height: 2.h),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveProfile,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 3,
        variant: CustomBottomBarVariant.standard,
      ),
    );
  }
}
