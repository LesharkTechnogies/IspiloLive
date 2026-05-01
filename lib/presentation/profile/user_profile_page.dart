import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/services/user_service.dart';
import '../../widgets/custom_image_widget.dart';
import '../../model/social_model.dart';
import '../../model/repository/social_repository.dart';
import '../home_feed/widgets/post_card_widget.dart';
import '../../core/services/media_download_service.dart';

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
  late Future<List<PostModel>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = UserService.getUserProfileById(widget.userId);
    _postsFuture = PostRepository.getPostsByUser(widget.userId);
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

  String _stringValueNested(Map<String, dynamic> p, List<String> keys,
      {String fallback = ''}) {
    final direct = _stringValue(p, keys, fallback: '');
    if (direct.isNotEmpty) return direct;

    final nestedUser = (p['user'] as Map?)?.cast<String, dynamic>() ?? const {};
    final nestedProfile = (p['profile'] as Map?)?.cast<String, dynamic>() ?? const {};

    final userValue = _stringValue(nestedUser, keys, fallback: '');
    if (userValue.isNotEmpty) return userValue;

    final profileValue = _stringValue(nestedProfile, keys, fallback: '');
    if (profileValue.isNotEmpty) return profileValue;

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

  Widget _buildProfileSkeleton(ColorScheme colorScheme) {
    return Column(
      children: [
        Container(height: 20.h, color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
        Transform.translate(
          offset: Offset(0, -6.h),
          child: Column(
            children: [
              CircleAvatar(radius: 44, backgroundColor: colorScheme.surface, child: CircleAvatar(radius: 40, backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5))),
              SizedBox(height: 1.2.h),
              Container(height: 24, width: 40.w, color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
              SizedBox(height: 1.h),
              Container(height: 14, width: 25.w, color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostSkeleton(ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 18, backgroundColor: colorScheme.onSurface.withValues(alpha: 0.1)),
              SizedBox(width: 2.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 10, width: 120, decoration: BoxDecoration(color: colorScheme.onSurface.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8))),
                  SizedBox(height: 0.8.h),
                  Container(height: 8, width: 80, decoration: BoxDecoration(color: colorScheme.onSurface.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8))),
                ],
              ),
            ],
          ),
          SizedBox(height: 1.8.h),
          Container(height: 10, width: double.infinity, decoration: BoxDecoration(color: colorScheme.onSurface.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8))),
          SizedBox(height: 0.8.h),
          Container(height: 10, width: 70.w, decoration: BoxDecoration(color: colorScheme.onSurface.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8))),
        ],
      ),
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
            return ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: [ _buildProfileSkeleton(colorScheme) ],
            );
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
          final name = _stringValueNested(
            profile,
            ['name', 'fullName', 'displayName', 'username'],
            fallback: 'Unknown User',
          );
          final username = _stringValueNested(profile, ['username', 'email']);
          final avatar = _stringValueNested(
            profile,
            ['avatar', 'avatarUrl', 'profileImage', 'profilePicture'],
          );
          final coverImage = _stringValueNested(profile, ['coverImage', 'bannerUrl']);
          final bio = _stringValueNested(profile, ['bio', 'about'], fallback: 'No bio available yet.');
          final location = _stringValueNested(profile, ['location', 'town', 'city']);
          final company = _stringValueNested(profile, ['company', 'organization']);
          final isVerified = _boolValue(profile, ['isVerified', 'verified']);

          final followers = _stringValue(profile, ['followersCount', 'followers'], fallback: '0');
          final following = _stringValue(profile, ['followingCount', 'following'], fallback: '0');
          final posts = _stringValue(profile, ['postCount', 'postsCount', 'posts'], fallback: '0');
          final postCount = int.tryParse(posts) ?? 0;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _profileFuture = UserService.getUserProfileById(widget.userId);
                _postsFuture = PostRepository.getPostsByUser(widget.userId);
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
                      Stack(
                        clipBehavior: Clip.none,
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
                          if (avatar.isNotEmpty && avatar.startsWith('http'))
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: () async {
                                  final ext = avatar.split('.').last.split('?').first;
                                  final dlName = 'ispilo_avatar_${DateTime.now().millisecondsSinceEpoch}.${ext.isEmpty ? 'jpg' : ext}';
                                  await MediaDownloadService.downloadFile(avatar, dlName, context);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: colorScheme.surface, width: 2),
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(Icons.download, color: colorScheme.onSecondary, size: 14),
                                ),
                              ),
                            ),
                        ],
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
                            leading: const Icon(Icons.location_on, color: Colors.redAccent),
                            title: Text(location, style: theme.textTheme.bodyMedium),
                          ),
                        if (company.isNotEmpty)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            leading: const Icon(Icons.work, color: Colors.blueAccent),
                            title: Text(company, style: theme.textTheme.bodyMedium),
                          ),
                      ],
                    ],
                  ),
                ),
                FutureBuilder<List<PostModel>>(
                  future: _postsFuture,
                  builder: (context, postsSnapshot) {
                    if (postsSnapshot.connectionState == ConnectionState.waiting) {
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 3,
                        itemBuilder: (context, index) => _buildPostSkeleton(colorScheme),
                      );
                    }
                    if (postsSnapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Center(child: Text('Failed to load posts: ${postsSnapshot.error}')),
                      );
                    }
                    final posts = postsSnapshot.data ?? [];
                    if (posts.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                postCount > 0
                                    ? 'Posts are taking longer to load.'
                                    : 'No posts yet.',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                              if (postCount > 0) ...[
                                SizedBox(height: 1.2.h),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _postsFuture = PostRepository.getPostsByUser(widget.userId);
                                    });
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry posts'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        return PostCardWidget(
                          post: posts[index].toJson(),
                        );                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
