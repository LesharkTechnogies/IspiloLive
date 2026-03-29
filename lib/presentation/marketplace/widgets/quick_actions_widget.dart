import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';

class QuickActionsWidget extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onContact;

  const QuickActionsWidget({
    super.key,
    required this.product,
    required this.onSave,
    required this.onShare,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
          Container(
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          SizedBox(height: 2.h),

          // Product Info
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomImageWidget(
                  imageUrl: product["image"] as String,
                  width: 15.w,
                  height: 15.w,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product["title"] as String,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      product["price"] as String,
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Action Buttons
          Column(
            children: [
              _buildActionButton(
                context,
                iconName: 'favorite_border',
                label: 'Save to Favorites',
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSave();
                  Navigator.pop(context);
                },
                colorScheme: colorScheme,
              ),
              SizedBox(height: 1.h),
              _buildActionButton(
                context,
                iconName: 'share',
                label: 'Share Product',
                onTap: () {
                  HapticFeedback.lightImpact();
                  onShare();
                  Navigator.pop(context);
                },
                colorScheme: colorScheme,
              ),
              SizedBox(height: 1.h),
              _buildActionButton(
                context,
                iconName: 'message',
                label: 'Contact Seller',
                onTap: () {
                  HapticFeedback.lightImpact();
                  onContact();
                  Navigator.pop(context);
                },
                colorScheme: colorScheme,
              ),
            ],
          ),

          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String iconName,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 2.h),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: 4.w),
            CustomIconWidget(
              iconName: iconName,
              color: colorScheme.onSurface,
              size: 24,
            ),
            SizedBox(width: 4.w),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
