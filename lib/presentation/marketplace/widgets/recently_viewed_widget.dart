import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
 
import '../../../widgets/common_product_card.dart';

class RecentlyViewedWidget extends StatelessWidget {
  final List<Map<String, dynamic>> recentProducts;
  final Function(Map<String, dynamic>) onProductTap;

  const RecentlyViewedWidget({
    super.key,
    required this.recentProducts,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final titleStyle = theme.textTheme.titleSmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ) ??
        TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurface);

    // Product card styles are defined inside _buildRecentProductCard to
    // ensure they respect the local BuildContext and avoid unused declarations.

    if (recentProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: Text('Recently Viewed', style: titleStyle),
          ),
          SizedBox(height: 0.5.h),
          SizedBox(
            height: 245, // Match card height (242px) + 3px for overflow prevention
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              itemCount: recentProducts.length,
              itemBuilder: (context, index) {
                final product = recentProducts[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 160,
                    child: CommonProductCard(
                      product: product,
                      onTap: () => onProductTap(product),
                      showSeller: true,
                      showLocation: false,
                      heroTagSuffix: '-recent-$index',
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
