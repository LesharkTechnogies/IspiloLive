import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../core/services/conversation_service.dart';
import '../../model/product_model.dart';
import '../../model/repository/product_repository.dart';
import '../../widgets/custom_icon_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/category_chip_widget.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/product_card_widget.dart';
import './widgets/quick_actions_widget.dart';
import './widgets/recently_viewed_widget.dart';
import './widgets/search_bar_widget.dart';

class Marketplace extends StatefulWidget {
  const Marketplace({super.key});

  @override
  State<Marketplace> createState() => _MarketplaceState();
}

class _MarketplaceState extends State<Marketplace> {
  Future<void> _handleSellButton() async {
    final prefs = await SharedPreferences.getInstance();
    final isShopRegistered = prefs.getInt('shopregidtered') ?? 0;
    if (isShopRegistered == 1) {
      Navigator.pushNamed(context, '/sell-something');
    } else {
      Navigator.pushNamed(context, '/settings');
    }
  }

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _selectedCategory = 'All Categories';
  Map<String, dynamic> _currentFilters = {};
  List<ProductModel> _filteredProducts = [];
  List<ProductModel> _recentlyViewed = [];
  List<String> _categories = ['All Categories'];
  bool _isLoading = false;
  bool _hasMoreProducts = true;
  int _currentPage = 0;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadCategories();
    _loadInitialProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Load available product categories
  Future<void> _loadCategories() async {
    try {
      final categories = await ProductRepository.getCategories();
      setState(() {
        _categories = ['All Categories', ...categories];
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  /// Load initial products from API
  Future<void> _loadInitialProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await ProductRepository.getProducts(
        page: 0,
        size: 20,
      );
      setState(() {
        _filteredProducts = products;
        _currentPage = 0;
        _hasMoreProducts = products.length >= 20;
        _isInitialLoad = false;
      });
    } catch (e) {
      debugPrint('Error loading products: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load products: $e')),
      );
      setState(() => _isInitialLoad = false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreProducts();
    }
  }

  /// Load more products when scrolling
  Future<void> _loadMoreProducts() async {
    if (_isLoading || !_hasMoreProducts) return;

    setState(() => _isLoading = true);
    try {
      final nextPage = _currentPage + 1;
      final products = await ProductRepository.getProducts(
        page: nextPage,
        size: 20,
        category: _selectedCategory == 'All Categories' ? null : _selectedCategory,
      );

      setState(() {
        _filteredProducts.addAll(products);
        _currentPage = nextPage;
        _hasMoreProducts = products.length >= 20;
      });
    } catch (e) {
      debugPrint('Error loading more products: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load more products: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Handle search input
  Future<void> _onSearchChanged(String query) async {
    if (query.isEmpty) {
      _loadInitialProducts();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final products = await ProductRepository.searchProducts(query);
      setState(() => _filteredProducts = products);
    } catch (e) {
      debugPrint('Error searching products: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Handle category selection
  Future<void> _onCategorySelected(String category) async {
    setState(() {
      _selectedCategory = category;
      _currentPage = 0;
      _isLoading = true;
    });

    try {
      final products = await ProductRepository.getProducts(
        page: 0,
        size: 20,
        category: category == 'All Categories' ? null : category,
      );
      setState(() {
        _filteredProducts = products;
        _hasMoreProducts = products.length >= 20;
      });
    } catch (e) {
      debugPrint('Error loading category: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load category: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheetWidget(
        currentFilters: _currentFilters,
        onApplyFilters: _applyFilters,
      ),
    );
  }

  /// Apply filters (client-side filtering from fetched products)
  void _applyFilters(Map<String, dynamic> filters) {
    setState(() {
      _currentFilters = filters;
      // In a real app with large datasets, you'd apply these filters server-side
      // For now, we filter the loaded products
    });
  }

  void _onProductTap(ProductModel product) {
    // Add to recently viewed
    setState(() {
      _recentlyViewed.removeWhere((p) => p.id == product.id);
      _recentlyViewed.insert(0, product);
      if (_recentlyViewed.length > 5) {
        _recentlyViewed = _recentlyViewed.take(5).toList();
      }
    });
    // Navigate to product detail
    Navigator.pushNamed(
      context,
      '/product-detail',
      arguments: {'productId': product.id},
    );
  }

  void _onProductLongPress(ProductModel product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickActionsWidget(
        product: product.toJson(),
        onSave: () => _saveToFavorites(product),
        onShare: () => _shareProduct(product),
        onContact: () => _contactSeller(product),
      ),
    );
  }

  Future<void> _saveToFavorites(ProductModel product) async {
    try {
      await ProductRepository.addToFavorites(product.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.title} saved to favorites'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }

  void _shareProduct(ProductModel product) {
    // Implement product sharing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${product.title}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _contactSeller(ProductModel product) async {
    final seller = product.seller;
    if (seller.id.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot contact seller at this time')),
      );
      return;
    }

    final conversation = await ConversationService.instance.getOrCreateConversation(
      sellerId: seller.id,
      sellerName: seller.businessName,
      sellerAvatar: seller.businessLogo ?? '',
    );

    if (!mounted) return;
    Navigator.pushNamed(
      context,
      AppRoutes.chat,
      arguments: conversation,
    );
  }

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    _loadInitialProducts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            SearchBarWidget(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onFilterTap: _showFilterBottomSheet,
              hintText: 'Search products...',
            ),

            // Category Chips
            Container(
              height: 4.5.h,
              margin: EdgeInsets.symmetric(vertical: 0.5.h),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 2.w),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return CategoryChipWidget(
                    label: category,
                    isSelected: _selectedCategory == category,
                    onTap: () => _onCategorySelected(category),
                  );
                },
              ),
            ),

            // Main Content
            Expanded(
              child: _isInitialLoad
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          // Products Grid
                          _filteredProducts.isEmpty
                              ? _buildEmptyState(colorScheme)
                              : SliverPadding(
                                  padding: EdgeInsets.only(
                                    left: 2.w,
                                    right: 2.w,
                                    bottom: 2.h,
                                  ),
                                  sliver: SliverGrid(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      childAspectRatio: 0.667,
                                      crossAxisSpacing: 2.w,
                                      mainAxisSpacing: 1.h,
                                    ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        if (index < _filteredProducts.length) {
                                          final product = _filteredProducts[index];
                                          return ProductCardWidget(
                                            product: product.toJson(),
                                            onTap: () => _onProductTap(product),
                                            onLongPress: () =>
                                                _onProductLongPress(product),
                                          );
                                        } else {
                                          return _buildLoadingCard(colorScheme);
                                        }
                                      },
                                      childCount: _filteredProducts.length +
                                          (_isLoading ? 3 : 0),
                                    ),
                                  ),
                                ),

                          // Recently Viewed Section
                          if (_recentlyViewed.isNotEmpty)
                            SliverToBoxAdapter(
                              child: RecentlyViewedWidget(
                                recentProducts: _recentlyViewed
                                    .map((p) => p.toJson())
                                    .toList(),
                                onProductTap: (product) {
                                  _onProductTap(ProductModel.fromJson(product));
                                },
                              ),
                            ),

                          // Loading indicator
                          if (_isLoading)
                            SliverToBoxAdapter(
                              child: Container(
                                padding: EdgeInsets.all(4.w),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ),

                          // End of results
                          if (!_hasMoreProducts && _filteredProducts.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Container(
                                padding: EdgeInsets.all(4.w),
                                child: Text(
                                  'No more products to load',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),

      floatingActionButton: Theme.of(context).platform == TargetPlatform.iOS
          ? null
          : FloatingActionButton.extended(
              onPressed: _handleSellButton,
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              icon: CustomIconWidget(
                iconName: 'add',
                color: colorScheme.onPrimary,
                size: 16,
              ),
              label: Text(
                'Sell',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              elevation: 4,
            ),

      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 2,
        variant: CustomBottomBarVariant.standard,
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'search_off',
              color: colorScheme.onSurface.withValues(alpha: 0.4),
              size: 64,
            ),
            SizedBox(height: 2.h),
            Text(
              'No products found',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Try adjusting your search or filters',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            TextButton(
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
                _onCategorySelected('All Categories');
                setState(() => _currentFilters.clear());
              },
              child: Text(
                'Clear all filters',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.all(1.w),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.2),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(2.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 2.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Container(
                    height: 1.5.h,
                    width: 20.w,
                    decoration: BoxDecoration(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
