import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class ProductInfoSection extends StatelessWidget {
  final String title;
  final String price;
  final String condition;
  final double rating;
  final int reviewCount;

  const ProductInfoSection({
    super.key,
    required this.title,
    required this.price,
    required this.condition,
    required this.rating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Title
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 12),

          // Price and Condition Row
          Row(
            children: [
              Text(
                price,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getConditionColor(condition, colorScheme)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getConditionColor(condition, colorScheme)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  condition,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getConditionColor(condition, colorScheme),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Rating and Reviews
          Row(
            children: [
              // Star Rating
              Row(
                children: List.generate(5, (index) {
                  return CustomIconWidget(
                    iconName: index < rating.floor() ? 'star' : 'star_border',
                    color: index < rating.floor()
                        ? Colors.amber
                        : colorScheme.onSurface.withValues(alpha: 0.3),
                    size: 16,
                  );
                }),
              ),

              const SizedBox(width: 8),

              Text(
                rating.toStringAsFixed(1),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),

              const SizedBox(width: 4),

              Text(
                '($reviewCount reviews)',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getConditionColor(String condition, ColorScheme colorScheme) {
    switch (condition.toLowerCase()) {
      case 'new':
        return Colors.green;
      case 'like new':
        return Colors.blue;
      case 'good':
        return Colors.orange;
      case 'fair':
        return Colors.red;
      default:
        return colorScheme.primary;
    }
  }
}
