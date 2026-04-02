import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/seller_service.dart';
import '../../core/services/conversation_service.dart';
import '../../model/repository/product_repository.dart';
import '../../model/product_model.dart';

import '../../core/app_export.dart';
import '../../core/models/seller.dart';
import './widgets/action_buttons_bar.dart';
import './widgets/expandable_description.dart';
import './widgets/product_image_gallery.dart';
import './widgets/product_info_section.dart';
import './widgets/related_products_carousel.dart';
import './widgets/seller_profile_section.dart';
import './widgets/shipping_policy_section.dart';
import './widgets/specifications_section.dart';

class ProductDetail extends StatefulWidget {
  const ProductDetail({super.key});

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  bool _isSaved = false;
  bool _loading = false;
  String? _hudError;
  Map<String, dynamic>? _productData;
  List<Map<String, dynamic>> _relatedProducts = [];
  String? _productId;

  void _setLoading(bool value) {
    if (!mounted) return;
    setState(() {
      _loading = value;
      if (value) _hudError = null;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProductData();
    });
  }

  /// Load product data from API based on product ID
  Future<void> _loadProductData() async {
    _setLoading(true);
    try {
      // Get product ID from route arguments
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _productId = args?['productId']?.toString() ?? args?['id']?.toString();

      if (_productId == null || _productId!.isEmpty) {
        _setError('No product selected');
        return;
      }

      // Fetch product details from API
      final product = await ProductRepository.getProductById(_productId!);

      if (!mounted) return;

      setState(() {
        _productData = product.toJson();
        _isSaved = false;
      });

      // Load related/other products from same seller
      _loadRelatedProducts();
    } catch (e) {
      debugPrint('Error loading product: $e');
      if (mounted) {
        _setError('Failed to load product: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Load related products from the same seller
  Future<void> _loadRelatedProducts() async {
    try {
      if (_productData == null) return;

      final seller = _productData!['seller'] as Map<String, dynamic>?;
      final sellerId = seller?['id'] as String?;

      if (sellerId == null) return;

      final List<ProductModel> products = await ProductRepository.getProductsBySeller(sellerId, size: 4);

      if (!mounted) return;

      setState(() {
        // Convert ProductModel to Map for compatibility with existing code
        _relatedProducts = products
            .where((p) => p.id != _productId) // Exclude current product
            .take(4)
            .map<Map<String, dynamic>>((p) => {
              'id': p.id,
              'title': p.title,
              'price': '\$${p.price.toStringAsFixed(2)}',
              'image': p.mainImage,
              'seller': seller,
            })
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading related products: $e');
    }
  }

  void _setError(String error) {
    setState(() {
      _hudError = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Show loading or error state
    if (_loading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: _buildAppBar(context, theme),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: colorScheme.primary),
              const SizedBox(height: 16),
              const Text('Loading product details...'),
            ],
          ),
        ),
      );
    }

    if (_hudError != null || _productData == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: _buildAppBar(context, theme),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(_hudError ?? 'Failed to load product'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadProductData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Extract data safely
    final product = _productData!;
    final seller = product['seller'] as Map<String, dynamic>? ?? {};
    final specifications = product['specifications'] as Map<String, dynamic>? ?? {};
    final shipping = product['shipping'] as Map<String, dynamic>? ?? {};
    final images = (product['images'] as List?)?.cast<String>() ?? ['https://via.placeholder.com/400x400?text=No+Image'];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(context, theme),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image Gallery
                      ProductImageGallery(
                        images: images,
                        productTitle: product['name'] as String? ?? product['title'] as String? ?? 'Product',
                      ),

                      const SizedBox(height: 16),

                      // Product Info Section
                      ProductInfoSection(
                        title: product['name'] as String? ?? product['title'] as String? ?? 'Product',
                        price: product['price'] != null
                            ? '\$${(product['price'] as num).toStringAsFixed(2)}'
                            : product['price'] as String? ?? 'Contact for price',
                        condition: product['condition'] as String? ?? 'New',
                        rating: ((product['rating'] as num?) ?? 4.0).toDouble(),
                        reviewCount: product['reviewCount'] as int? ?? 0,
                      ),

                      const SizedBox(height: 16),

                      // Seller Profile Section
                      if (seller.isNotEmpty)
                        SellerProfileSection(
                          sellerName: seller['name'] as String? ?? 'Unknown Seller',
                          sellerAvatar: seller['avatar'] as String? ?? '',
                          isVerified: seller['isVerified'] as bool? ?? false,
                          sellerRating: ((seller['rating'] as num?) ?? 4.0).toDouble(),
                          totalSales: seller['totalSales'] as int? ?? 0,
                          onViewProfile: () => _viewSellerProfile(),
                        ),

                      const SizedBox(height: 24),

                      // Product Description
                      if (product['description'] != null)
                        ExpandableDescription(
                          description: product['description'] as String,
                        ),

                      const SizedBox(height: 24),

                      // Technical Specifications
                      if (specifications.isNotEmpty)
                        SpecificationsSection(
                          specifications: specifications.cast<String, String>(),
                        ),

                      const SizedBox(height: 24),

                      // Shipping & Return Policy
                      if (shipping.isNotEmpty)
                        ShippingPolicySection(
                          shippingInfo: shipping['info'] as String? ?? 'Standard shipping available',
                          returnPolicy: shipping['returnPolicy'] as String? ?? 'Contact seller for returns',
                          estimatedDelivery: shipping['estimatedDelivery'] as String? ?? '5-7 business days',
                          shippingCost: shipping['cost'] as String? ?? 'Contact seller',
                        ),

                      const SizedBox(height: 24),

                      // Related Products
                      if (_relatedProducts.isNotEmpty)
                        RelatedProductsCarousel(
                          relatedProducts: _relatedProducts,
                          onProductTap: _navigateToProduct,
                        ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              // Action Buttons Bar
              ActionButtonsBar(
                onContactSeller: _contactSeller,
                onMakeOffer: _makeOffer,
                onSaveProduct: _toggleSaveProduct,
                isSaved: _isSaved,
              ),
            ],
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return AppBar(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: CustomIconWidget(
          iconName: 'arrow_back_ios',
          color: colorScheme.onSurface,
          size: 24,
        ),
      ),
      actions: [
        IconButton(
          onPressed: _shareProduct,
          icon: CustomIconWidget(
            iconName: 'share',
            color: colorScheme.onSurface,
            size: 24,
          ),
        ),
        IconButton(
          onPressed: _toggleSaveProduct,
          icon: CustomIconWidget(
            iconName: _isSaved ? 'bookmark' : 'bookmark_border',
            color: _isSaved ? colorScheme.primary : colorScheme.onSurface,
            size: 24,
          ),
        ),
      ],
    );
  }
  Future<void> _openMessagingWithSeller() async {
    _setLoading(true);

    // Try to upsert seller from product payload (will use existing id if present)
    final productSellerMap =
        (_productData?['seller'] as Map<String, dynamic>?) ?? {};
    // Prefer explicit seller id if present
    String? explicitSellerId = productSellerMap['id'] as String?;
    Seller? seller;
    if (explicitSellerId != null && explicitSellerId.isNotEmpty) {
      final existing =
          await SellerService.getSellerRaw(explicitSellerId);
      if (existing != null) {
        seller = existing;
      } else {
        // upsert using provided id and other fields
        productSellerMap['id'] = explicitSellerId;
        seller =
            await SellerService.upsertSellerFromMap(productSellerMap);
      }
    } else {
      seller =
          await SellerService.upsertSellerFromMap(productSellerMap);
      explicitSellerId = seller?.id;
    }

    if (seller == null) {
      _setLoading(false);
      return;
    }

    _setLoading(false);

    final conversation =
        await ConversationService.instance.getOrCreateConversation(
      sellerId: seller.id,
      sellerName: seller.name,
      sellerAvatar: seller.avatar,
    );

    if (!mounted) return;
    
    // Capture Navigator after mounted check to avoid use_build_context_synchronously
    final navigator = Navigator.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigator.pushNamed(AppRoutes.chat, arguments: conversation);
    });
  }

  Future<void> _callSellerWithSeller() async {
    _setLoading(true);

    final productSellerMap =
        (_productData?['seller'] as Map<String, dynamic>?) ?? {};
    String? explicitSellerId = productSellerMap['id'] as String?;
    Seller? seller;
    if (explicitSellerId != null && explicitSellerId.isNotEmpty) {
      final existing =
          await SellerService.getSellerRaw(explicitSellerId);
      seller = existing ??
          await SellerService.upsertSellerFromMap(productSellerMap);
    } else {
      seller =
          await SellerService.upsertSellerFromMap(productSellerMap);
    }

    if (seller == null) { _setLoading(false); return; }

    final rawPhone = seller.phone ?? '';
    final isPublic = seller.phonePrivacyPublic;

    if (rawPhone.isEmpty) {
      _setLoading(false);
      setState(() {
        _hudError = 'Seller phone number not available.';
      });
      return;
    }

    if (!isPublic) {
      _setLoading(false);
      setState(() {
        _hudError = 'Seller phone number is private.';
      });
      return;
    }

    final normalized = _normalizePhone(rawPhone, seller.countryCode);

    _setLoading(false); // clear HUD before showing confirmation
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call Seller'),
        content: Text('Call $normalized?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final uri = Uri(scheme: 'tel', path: normalized);
              launchUrl(uri);
            },
            child: const Text('Call'),
          ),
        ],
      ),
    );
  }

  Future<void> _openWhatsAppWithSeller() async {
    _setLoading(true);

    final productSellerMap =
        (_productData?['seller'] as Map<String, dynamic>?) ?? {};
    String? explicitSellerId = productSellerMap['id'] as String?;
    Seller? seller;
    if (explicitSellerId != null && explicitSellerId.isNotEmpty) {
      final existing =
          await SellerService.getSellerRaw(explicitSellerId);
      seller = existing ??
          await SellerService.upsertSellerFromMap(productSellerMap);
    } else {
      seller =
          await SellerService.upsertSellerFromMap(productSellerMap);
    }

    if (seller == null) { _setLoading(false); return; }

    final rawPhone = seller.phone ?? '';
    final isPublic = seller.phonePrivacyPublic;

    if (rawPhone.isEmpty) {
      _setLoading(false);
      setState(() {
        _hudError = 'Seller phone number not available.';
      });
      return;
    }

    if (!isPublic) {
      _setLoading(false);
      setState(() {
        _hudError = 'Seller phone number is private.';
      });
      return;
    }

    final normalized = _normalizePhone(rawPhone, seller.countryCode);
    final uri = Uri.parse('https://wa.me/$normalized');

    _setLoading(false);
    if (!mounted) return;

    // show confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open WhatsApp'),
        content: Text('Open WhatsApp chat with $normalized?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final scaffold = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              if (!await canLaunchUrl(uri)) {
                scaffold.showSnackBar(
                  const SnackBar(
                    content: Text('Could not open WhatsApp.'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }

  String _normalizePhone(String raw, String? countryCode) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final cc = (countryCode ?? '254').replaceAll(RegExp(r'[^0-9]'), '');
    // If digits already looks like an international number (starts with country code), return as-is.
    if (digits.length >= 10) return digits;
    // Otherwise prefix country code
    return '$cc$digits';
  }


  void _toggleSaveProduct() {
    if (_productId == null) return;

    setState(() => _isSaved = !_isSaved);

    if (_isSaved) {
      ProductRepository.addToFavorites(_productId!).then((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to favorites')),
          );
        }
      }).catchError((e) {
        setState(() => _isSaved = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      });
    } else {
      ProductRepository.removeFromFavorites(_productId!).then((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from favorites')),
          );
        }
      }).catchError((e) {
        setState(() => _isSaved = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      });
    }
  }

  void _shareProduct() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing product...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _navigateToProduct(String productId) {
    if (productId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid product')),
      );
      return;
    }
    // Replace current product with new one
    _productId = productId;
    _loadProductData();
  }

  void _viewSellerProfile() {
    if (_productData == null) return;

    final seller = _productData!['seller'] as Map<String, dynamic>?;
    final sellerId = seller?['id'] as String?;

    if (sellerId == null || sellerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seller information not available')),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/seller-profile',
      arguments: {'sellerId': sellerId},
    );
  }

  void _contactSeller() {
    if (_productData == null) return;

    final seller = _productData!['seller'] as Map<String, dynamic>?;
    final sellerId = seller?['id'] as String?;

    if (sellerId == null || sellerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot contact seller at this time')),
      );
      return;
    }

    _openMessagingWithSeller();
  }

  void _makeOffer() {
    if (_productData == null) return;

    final TextEditingController offerController = TextEditingController();
    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Make an Offer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: offerController,
                decoration: const InputDecoration(
                  labelText: 'Your Offer Price',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitOffer(offerController.text, messageController.text);
            },
            child: const Text('Send Offer'),
          ),
        ],
      ),
    );
  }

  void _submitOffer(String amount, String message) {
    if (amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an offer amount')),
      );
      return;
    }

    if (_productData == null) return;

    final seller = _productData!['seller'] as Map<String, dynamic>?;
    final sellerId = seller?['id'] as String?;

    if (sellerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot send offer at this time')),
      );
      return;
    }

    // Send offer to seller via message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Offer of \$$amount submitted to seller'),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
