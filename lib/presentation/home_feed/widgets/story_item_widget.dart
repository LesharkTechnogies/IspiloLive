import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/profile_avatar.dart';

class StoryItemWidget extends StatelessWidget {
  final Map<String, dynamic> story;
  final VoidCallback? onTap;
  final double? diameter;

  const StoryItemWidget({
    super.key,
    required this.story,
    this.onTap,
    this.diameter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isViewed = story['isViewed'] as bool? ?? false;
    final comments = story['comments'] as int? ?? 0;

    final double boxSize = (diameter ?? min(16.w, 64)).toDouble();
    final double innerPadding = ((boxSize * 0.06).clamp(2, 8)).toDouble();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: 3.w),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: boxSize,
                  height: boxSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isViewed
                        ? null
                        : LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.tertiary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: isViewed
                        ? theme.colorScheme.outline.withValues(alpha: 0.3)
                        : null,
                  ),
                  padding: EdgeInsets.all(innerPadding),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: ProfileAvatar(
                        imageUrl: story['avatar'] as String? ?? '',
                        size: (boxSize * 0.88).toDouble(),
                        isOnline: story['isOnline'] as bool? ?? false,
                      ),
                    ),
                  ),
                ),
                if (comments > 0)
                  Positioned(
                    bottom: -8,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.chat_bubble,
                              size: 10, color: Colors.white),
                          const SizedBox(width: 2),
                          Text(
                            comments.toString(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 1.h),
            SizedBox(
              width: boxSize,
              child: Text(
                story['username'] as String? ?? '',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
