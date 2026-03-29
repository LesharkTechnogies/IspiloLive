import 'package:flutter/material.dart';

import '../../../widgets/common_product_card.dart';

class ProductCardWidget extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ProductCardWidget({
    super.key,
    required this.product,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return CommonProductCard(
      product: product,
      onTap: onTap,
      onLongPress: onLongPress,
      showSeller: false,
      showLocation: true,
      heroTagSuffix: '-marketplace',
    );
  }
}
