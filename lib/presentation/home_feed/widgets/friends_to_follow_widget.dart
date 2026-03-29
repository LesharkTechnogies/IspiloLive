import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/profile_avatar.dart';

class FriendsToFollowWidget extends StatefulWidget {
  final List<Map<String, dynamic>> suggestions;

  const FriendsToFollowWidget({
    super.key,
    required this.suggestions,
  });

  @override
  State<FriendsToFollowWidget> createState() => _FriendsToFollowWidgetState();
}

class _FriendsToFollowWidgetState extends State<FriendsToFollowWidget> {
  final Set<int> followedUsers = {};

  void _handleFollow(int userId) {
    HapticFeedback.lightImpact();
    setState(() {
      if (followedUsers.contains(userId)) {
        followedUsers.remove(userId);
      } else {
        followedUsers.add(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Friends to Follow',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full suggestions page
                  },
                  child: Text(
                    'See All',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 1.h),
          SizedBox(
            height: 31.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 0),
              itemCount: widget.suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = widget.suggestions[index];
                final userId = int.tryParse(suggestion['id']?.toString() ?? '') ?? index;
                final isFollowed = followedUsers.contains(userId);
                final fullName = suggestion['name']?.toString() ?? 'Unknown User';
                final username = suggestion['username']?.toString() ??
                    suggestion['email']?.toString() ??
                    fullName.toLowerCase().replaceAll(' ', '_');
                final avatarUrl = suggestion['avatar']?.toString() ??
                    suggestion['avatarUrl']?.toString() ??
                    suggestion['profileImage']?.toString() ??
                    '';

                return Container(
                  width: 40.w,
                  margin: EdgeInsets.only(right: 3.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.surface,
                        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.30),
                        blurRadius: 14,
                        spreadRadius: 1,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(alpha: 0.10),
                        blurRadius: 4,
                        spreadRadius: 0,
                        offset: const Offset(-2, -2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.green.withValues(alpha: 0.55),
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: ProfileAvatar(
                                    imageUrl: avatarUrl,
                                    size: 15.w.toDouble(),
                                    isOnline: suggestion['isOnline'] as bool? ?? false,
                                  ),
                                ),
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                '@$username',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 0.6.h),
                              Text(
                                fullName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 0.4.h),
                              Text(
                                suggestion['role']?.toString() ?? 'Suggested friend',
                                style: theme.textTheme.bodySmall,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 0.8.h),
                              Text(
                                '${suggestion['mutualFriends'] as int? ?? 0} mutual friends',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 0.8.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _handleFollow(userId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFollowed
                                  ? theme.colorScheme.surface
                                  : theme.colorScheme.primary,
                              foregroundColor: isFollowed
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onPrimary,
                              side: isFollowed
                                  ? BorderSide(
                                      color: theme.colorScheme.outline
                                          .withValues(alpha: 0.3))
                                  : null,
                              padding: EdgeInsets.symmetric(vertical: 0.9.h),
                              minimumSize: Size(double.infinity, 4.2.h),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              isFollowed ? 'Following' : 'Follow',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
