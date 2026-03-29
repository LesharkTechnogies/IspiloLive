import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import 'video_card_widget.dart';

class MyLearningSectionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> enrolledCourses;
  final Function(Map<String, dynamic>) onContinueCourse;
  final List<Map<String, String>> enrolledVideos;

  const MyLearningSectionWidget({
    super.key,
    required this.enrolledCourses,
    required this.onContinueCourse,
    this.enrolledVideos = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (enrolledCourses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
         
          if (enrolledVideos.isNotEmpty) ...[
            SizedBox(height: 2.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                'My Learning Videos',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp.clamp(12.sp, 17.sp),
                ),
              ),
            ),
            SizedBox(height: 1.h),
            SizedBox(
              height: 28.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                itemCount: (enrolledVideos.length / 3).ceil(),
                itemBuilder: (context, colIndex) {
                  final firstIndex = colIndex * 3;
                  final secondIndex = firstIndex + 1;
                  final thirdIndex = firstIndex + 2;
                  final first = enrolledVideos[firstIndex];
                  final Map<String, String>? second =
                      secondIndex < enrolledVideos.length
                          ? enrolledVideos[secondIndex]
                          : null;
                  final Map<String, String>? third =
                      thirdIndex < enrolledVideos.length
                          ? enrolledVideos[thirdIndex]
                          : null;

                  return Container(
                    width: 30.w + 30.w + 30.w + 31 * 2,
                    margin: const EdgeInsets.only(right: 31),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 30.w,
                          height: 27.h,
                          child: VideoCardWidget(
                            thumbnailUrl: first['thumbnail'] ?? '',
                            title: first['title'] ?? '',
                            subtitle: first['channel'],
                            duration: first['duration'],
                            views: first['views'],
                            onTap: () {
                              // TODO: Navigate to video player/details
                            },
                          ),
                        ),
                        const SizedBox(width: 31),
                        if (second != null)
                          SizedBox(
                            width: 30.w,
                            height: 27.h,
                            child: VideoCardWidget(
                              thumbnailUrl: second['thumbnail'] ?? '',
                              title: second['title'] ?? '',
                              subtitle: second['channel'],
                              duration: second['duration'],
                              views: second['views'],
                              onTap: () {
                                // TODO: Navigate to video player/details
                              },
                            ),
                          )
                        else
                          SizedBox(width: 30.w, height: 27.h),
                        const SizedBox(width: 31),
                        if (third != null)
                          SizedBox(
                            width: 30.w,
                            height: 27.h,
                            child: VideoCardWidget(
                              thumbnailUrl: third['thumbnail'] ?? '',
                              title: third['title'] ?? '',
                              subtitle: third['channel'],
                              duration: third['duration'],
                              views: third['views'],
                              onTap: () {
                                // TODO: Navigate to video player/details
                              },
                            ),
                          )
                        else
                          SizedBox(width: 30.w, height: 27.h),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEnrolledCourseCard(
      BuildContext context, Map<String, dynamic> course, ThemeData theme) {
    final progress = course["progress"] as double? ?? 0.0;
    final colorScheme = theme.colorScheme;

    return Container(
      width: 50.w,
      margin: EdgeInsets.only(right: 2.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: CustomImageWidget(
              imageUrl: course["thumbnail"] as String,
              width: double.infinity,
              height: 6.5.h,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(2.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course["title"] as String,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.3.h),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: colorScheme.outline.withValues(alpha: 0.18),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  minHeight: 0.5.h,
                ),
                SizedBox(height: 0.2.h),
                Text(
                  course["instructor"] as String,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
