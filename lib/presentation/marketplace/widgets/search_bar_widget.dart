import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;
  final String hintText;
  final double fontSize;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onFilterTap,
    this.hintText = 'Search products...',
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: Container(
              height: 6.h,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: GoogleFonts.inter(
                  fontSize: fontSize,
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: GoogleFonts.inter(
                    fontSize: fontSize,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'search',
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      size: 20,
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 1.5.h,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(width: 3.w),

          // Filter Button
          GestureDetector(
            onTap: onFilterTap,
            child: Container(
              height: 6.h,
              width: 6.h,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'filter_list',
                  color: colorScheme.onPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
