import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CourseCardWidget extends StatelessWidget {
  final Map<String, dynamic> course;
  final VoidCallback? onTap;
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final VoidCallback? onWishlist;

  const CourseCardWidget({
    super.key,
    required this.course,
    this.onTap,
    this.onSave,
    this.onShare,
    this.onWishlist,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEnrolled = course["isEnrolled"] as bool? ?? false;
    final isNew = course["isNew"] as bool? ?? false;
    final progress = course["progress"] as double? ?? 0.0;

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showQuickActions(context),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnailSection(context, colorScheme, isNew),
            _buildContentSection(context, theme, isEnrolled, progress),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailSection(
      BuildContext context, ColorScheme colorScheme, bool isNew) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          child: CustomImageWidget(
            imageUrl: course["thumbnail"] as String,
            width: double.infinity,
            height: 14.h,
            fit: BoxFit.cover,
          ),
        ),
        if (isNew)
          Positioned(
            top: 2.h,
            left: 3.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: AppTheme.getSuccessColor(
                    Theme.of(context).brightness == Brightness.light),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'NEW',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 1.h,
          right: 3.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              course["duration"] as String,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection(
      BuildContext context, ThemeData theme, bool isEnrolled, double progress) {
    return Padding(
      padding: EdgeInsets.all(3.w),
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
          SizedBox(height: 1.h),
          Row(
            children: [
              CustomIconWidget(
                iconName: 'person',
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              SizedBox(width: 1.w),
              Expanded(
                child: Text(
                  course["instructor"] as String,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              _buildRatingSection(theme),
              const Spacer(),
              _buildPriceSection(theme),
            ],
          ),
          if (isEnrolled) ...[
            SizedBox(height: 0.7.h),
            _buildProgressSection(theme, progress),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingSection(ThemeData theme) {
    final rating = course["rating"] as double? ?? 0.0;
    final reviewCount = course["reviewCount"] as int? ?? 0;

    return Row(
      children: [
        CustomIconWidget(
          iconName: 'star',
          size: 16,
          color: AppTheme.getWarningColor(theme.brightness == Brightness.light),
        ),
        SizedBox(width: 1.w),
        Text(
          rating.toStringAsFixed(1),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 1.w),
        Text(
          '($reviewCount)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection(ThemeData theme) {
    final price = course["price"] as String;
    final originalPrice = course["originalPrice"] as String?;

    return Row(
      children: [
        if (originalPrice != null) ...[
          Text(
            originalPrice,
            style: theme.textTheme.bodySmall?.copyWith(
              decoration: TextDecoration.lineThrough,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(width: 1.w),
        ],
        Text(
          price,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(ThemeData theme, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
        ),
      ],
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.h),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'bookmark_border',
                size: 24,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              title: const Text('Save for Later'),
              onTap: () {
                Navigator.pop(context);
                onSave?.call();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'share',
                size: 24,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                onShare?.call();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'favorite_border',
                size: 24,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              title: const Text('Add to Wishlist'),
              onTap: () {
                Navigator.pop(context);
                onWishlist?.call();
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}
