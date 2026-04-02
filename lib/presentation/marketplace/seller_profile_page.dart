import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:ispilo/model/product_model.dart';
import 'package:ispilo/model/seller_model.dart';
import 'package:ispilo/model/repository/product_repository.dart';
import 'package:ispilo/core/services/conversation_service.dart';
import '../../core/services/seller_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';

class SellerProfilePage extends StatefulWidget {
  final String sellerId;

  const SellerProfilePage({
    super.key,
    required this.sellerId,
  });

  @override
  State<SellerProfilePage> createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends State<SellerProfilePage> {
  late Future<SellerModel?> _sellerFuture;
  late Future<Map<String, dynamic>?> _ratingsFuture;
  late Future<List<ProductModel>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _sellerFuture = SellerService.getSellerById(widget.sellerId);
    _ratingsFuture = SellerService.getSellerRatings(widget.sellerId);
    _productsFuture = ProductRepository.getProductsBySeller(widget.sellerId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(title: 'Seller Profile'),
      body: FutureBuilder<SellerModel?>(
        future: _sellerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            );
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                  SizedBox(height: 2.h),
                  Text('Failed to load seller profile'),
                  SizedBox(height: 2.h),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _sellerFuture = SellerService.getSellerById(widget.sellerId);
                    }),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final seller = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Seller Header
                _buildSellerHeader(seller, colorScheme),

                // Seller Info
                _buildSellerInfo(seller, colorScheme),

                // Rating & Reviews Section
                FutureBuilder<Map<String, dynamic>?>(
                  future: _ratingsFuture,
                  builder: (context, ratingSnapshot) {
                    if (ratingSnapshot.hasData) {
                      return _buildRatingsSection(ratingSnapshot.data!, colorScheme);
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Products Section
                _buildProductsSection(colorScheme),

                SizedBox(height: 4.h),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 1,
        variant: CustomBottomBarVariant.standard,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _contactSeller(),
        icon: const Icon(Icons.mail),
        label: const Text('Contact Seller'),
      ),
    );
  }

  Widget _buildSellerHeader(SellerModel seller, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 36,
            backgroundImage: seller.avatar.isNotEmpty
                ? NetworkImage(seller.avatar)
                : null,
            child: seller.avatar.isEmpty
                ? Icon(Icons.store, size: 36, color: colorScheme.primary)
                : null,
          ),
          SizedBox(width: 3.w),
          // Seller info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        seller.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (seller.isVerified)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Verified',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 0.5.h),
                Text(
                  seller.countryCode ?? 'International Seller',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerInfo(SellerModel seller, ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contact Info
          if (seller.phone != null && seller.phone!.isNotEmpty)
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone, color: colorScheme.primary, size: 20),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      seller.phone!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Call seller functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Call feature coming soon')),
                      );
                    },
                    child: const Text('Call'),
                  ),
                ],
              ),
            ),
          SizedBox(height: 2.h),
          // Description if available
          Text(
            'About Seller',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Professional seller with years of experience in quality products and customer service.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingsSection(
    Map<String, dynamic> ratings,
    ColorScheme colorScheme,
  ) {
    final avgRating = ratings['averageRating'] as double? ?? 0.0;
    final totalReviews = ratings['totalReviews'] as int? ?? 0;
    final ratingBreakdown = ratings['breakdown'] as Map<String, int>? ?? {};

    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ratings & Reviews',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          // Average rating
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    avgRating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < avgRating.toInt()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 18,
                        );
                      }),
                    ],
                  ),
                  Text(
                    '$totalReviews reviews',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Rating breakdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildRatingBar(5, ratingBreakdown[5] ?? 0, totalReviews, colorScheme),
                  _buildRatingBar(4, ratingBreakdown[4] ?? 0, totalReviews, colorScheme),
                  _buildRatingBar(3, ratingBreakdown[3] ?? 0, totalReviews, colorScheme),
                  _buildRatingBar(2, ratingBreakdown[2] ?? 0, totalReviews, colorScheme),
                  _buildRatingBar(1, ratingBreakdown[1] ?? 0, totalReviews, colorScheme),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(
    int stars,
    int count,
    int total,
    ColorScheme colorScheme,
  ) {
    final percentage = total > 0 ? (count / total) : 0.0;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$stars★', style: Theme.of(context).textTheme.labelSmall),
          SizedBox(width: 1.w),
          Container(
            width: 15.w,
            height: 6,
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          SizedBox(width: 1.w),
          Text(count.toString(), style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _buildProductsSection(ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Products from this Seller',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          FutureBuilder<List<ProductModel>>(
            future: _productsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: colorScheme.primary),
                );
              }

              if (snapshot.hasError || snapshot.data == null) {
                return Center(
                  child: Text('Failed to load products'),
                );
              }

              final products = snapshot.data!;

              if (products.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Text('No products yet'),
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 2.w,
                  mainAxisSpacing: 2.h,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _buildProductCard(product, colorScheme);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductModel product, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/product-detail',
          arguments: {'productId': product.id},
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              child: Image.network(
                product.imageUrl.isNotEmpty
                    ? product.imageUrl
                    : 'https://via.placeholder.com/200x200?text=No+Image',
                height: 15.h,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 15.h,
                    color: colorScheme.outline.withValues(alpha: 0.1),
                    child: Icon(Icons.image_not_supported, color: colorScheme.outline),
                  );
                },
              ),
            ),
            // Product Info
            Padding(
              padding: EdgeInsets.all(2.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    product.priceFormatted,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _contactSeller() async {
    final sellerSnapshot = await _sellerFuture;
    if (!mounted || sellerSnapshot == null || sellerSnapshot.id.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot contact seller at this time')),
      );
      return;
    }

    final conversation = await ConversationService.instance.getOrCreateConversation(
      sellerId: sellerSnapshot.id,
      sellerName: sellerSnapshot.businessName,
      sellerAvatar: sellerSnapshot.businessLogo ?? '',
    );

    if (!mounted) return;
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: conversation,
    );
  }
}
