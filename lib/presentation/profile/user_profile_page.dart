import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/services/user_service.dart';
import '../../widgets/custom_image_widget.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;

  const UserProfilePage({
    super.key,
    required this.userId,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = UserService.getUserProfileById(widget.userId);
  }

  String _stringValue(Map<String, dynamic> p, List<String> keys, {String fallback = ''}) {
    for (final k in keys) {
      final v = p[k];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    return fallback;
  }

  bool _boolValue(Map<String, dynamic> p, List<String> keys, {bool fallback = false}) {
    for (final k in keys) {
      final v = p[k];
      if (v is bool) return v;
    }
    return fallback;
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color textColor,
  }) {
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
    final appGreen = theme.brightness == Brightness.dark
        ? const Color(0xFF0E4D45)
        : const Color(0xFF075E54);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: appGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Profile',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: Text(
                  'Unable to load this profile right now.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            );
          }

          final profile = snapshot.data ?? <String, dynamic>{};
          final name = _stringValue(profile, ['name', 'fullName', 'displayName', 'username'], fallback: 'Unknown User');
          final username = _stringValue(profile, ['username', 'email']);
          final avatar = _stringValue(profile, ['avatar', 'avatarUrl', 'profileImage', 'profilePicture']);
          final coverImage = _stringValue(profile, ['coverImage', 'bannerUrl']);
          final bio = _stringValue(profile, ['bio', 'about'], fallback: 'No bio available yet.');
          final location = _stringValue(profile, ['location', 'town', 'city']);
          final company = _stringValue(profile, ['company', 'organization']);
          final isVerified = _boolValue(profile, ['isVerified', 'verified']);

          final followers = _stringValue(profile, ['followersCount', 'followers'], fallback: '0');
          final following = _stringValue(profile, ['followingCount', 'following'], fallback: '0');
          final posts = _stringValue(profile, ['postCount', 'postsCount', 'posts'], fallback: '0');

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _profileFuture = UserService.getUserProfileById(widget.userId);
              });
              await _profileFuture;
            },
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  height: 20.h,
                  color: appGreen.withValues(alpha: 0.9),
                  child: coverImage.isNotEmpty
                      ? CustomImageWidget(
                          imageUrl: coverImage,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                Transform.translate(
                  offset: Offset(0, -6.h),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: colorScheme.surface,
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: appGreen.withValues(alpha: 0.15),
                          backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                          child: avatar.isEmpty
                              ? Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                  style: GoogleFonts.inter(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: appGreen,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      SizedBox(height: 1.2.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (isVerified) ...[
                            SizedBox(width: 1.4.w),
                            const Icon(
                              Icons.verified,
                              size: 18,
                              color: Color(0xFF25D366),
                            ),
                          ],
                        ],
                      ),
                      if (username.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 0.5.h),
                          child: Text(
                            '@$username',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(5.w, 0, 5.w, 3.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 1.8.h, horizontal: 4.w),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: appGreen.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(label: 'Posts', value: posts, textColor: colorScheme.onSurface),
                            _buildStatItem(label: 'Followers', value: followers, textColor: colorScheme.onSurface),
                            _buildStatItem(label: 'Following', value: following, textColor: colorScheme.onSurface),
                          ],
                        ),
                      ),
                      SizedBox(height: 2.4.h),
                      Text(
                        'About',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: appGreen,
                        ),
                      ),
                      SizedBox(height: 0.8.h),
                      Text(
                        bio,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.4,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (location.isNotEmpty || company.isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        if (location.isNotEmpty)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            leading: Icon(Icons.location_on_outlined, color: appGreen),
                            title: Text(location, style: theme.textTheme.bodyMedium),
                          ),
                        if (company.isNotEmpty)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            leading: Icon(Icons.work_outline, color: appGreen),
                            title: Text(company, style: theme.textTheme.bodyMedium),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
