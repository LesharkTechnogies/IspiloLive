import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_export.dart';

/// Common reusable product card widget used across marketplace and recently viewed
/// Maintains consistent sizing: 160x240 with 120px image height
class CommonProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool showSeller;
  final bool showLocation;
  final String? heroTagSuffix; // Optional suffix to make Hero tags unique

  const CommonProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onLongPress,
    this.showSeller = false,
    this.showLocation = true,
    this.heroTagSuffix,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final productTitleStyle = theme.textTheme.titleMedium?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ) ??
        TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface);

    final priceStyle = theme.textTheme.titleLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ) ??
        TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.primary);

    final metaStyle = theme.textTheme.bodySmall?.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface.withValues(alpha: 0.7),
        ) ??
        TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurface.withValues(alpha: 0.7));

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      onLongPress: onLongPress != null
          ? () {
              HapticFeedback.mediumImpact();
              onLongPress!();
            }
          : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 100,
          maxWidth: 500,
          minHeight: 242,
          maxHeight: 242,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image - Fixed height 120px, full width
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: Hero(
                    tag: 'product-${product["id"]}${heroTagSuffix ?? ""}',
                    child: CustomImageWidget(
                      imageUrl: product["image"] as String,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              // Product Details - Remaining 120px
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Title
                      Text(
                        product["title"] as String,
                        style: productTitleStyle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Price
                      Text(product["price"] as String, style: priceStyle),

                      const SizedBox(height: 4),

                      // Seller Info (if enabled)
                      if (showSeller && product["seller"] != null) ...[
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'person',
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.6),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                product["seller"] as String,
                                style: metaStyle,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],

                      const Spacer(),

                      // Rating and Location Row
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'star',
                            color: Colors.amber,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            product["rating"].toString(),
                            style: metaStyle.copyWith(
                              fontSize: 12,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          if (showLocation && product["location"] != null) ...[
                            const SizedBox(width: 8),
                            CustomIconWidget(
                              iconName: 'location_on',
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.6),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                product["location"] as String,
                                style: metaStyle,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
