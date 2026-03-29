import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/common_product_card.dart';

class RelatedProductsCarousel extends StatelessWidget {
  final List<Map<String, dynamic>> relatedProducts;
  final Function(String productId) onProductTap;

  const RelatedProductsCarousel({
    super.key,
    required this.relatedProducts,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (relatedProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Related Products',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 242,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: relatedProducts.length,
              itemBuilder: (context, index) {
                final product = relatedProducts[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 160,
                    child: CommonProductCard(
                      product: product,
                      onTap: () => onProductTap(product['id'] as String),
                      showSeller: false,
                      showLocation: false,
                      heroTagSuffix: '-related-$index',
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
