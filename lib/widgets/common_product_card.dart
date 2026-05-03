import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_export.dart';
import 'dart:math';

/// Common reusable product card widget used across marketplace and recently viewed
/// Maintains consistent sizing: 160x240 with 120px image height
class CommonProductCard extends StatefulWidget {
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
  State<CommonProductCard> createState() => _CommonProductCardState();
}

class _CommonProductCardState extends State<CommonProductCard> {
  bool _isHovered = false;

  String _getImage() {
    final img = widget.product['mainImage'] ?? widget.product['image'] ?? widget.product['imageUrl'] ?? widget.product['thumbnail'];
    if (img is String && img.isNotEmpty) return img;
    final images = widget.product['images'] ?? widget.product['mediaUrls'];
    if (images is List && images.isNotEmpty) return images.first.toString();
    return '';
  }

  String _getTitle() {
    return (widget.product['title'] ?? widget.product['name'] ?? 'Untitled').toString();
  }

  String _getPrice() {
    final p = widget.product['price'];
    if (p is num) return '\$${p.toStringAsFixed(2)}';
    return p?.toString() ?? '\$0.00';
  }

  String _getSellerName() {
    final s = widget.product['seller'];
    if (s is Map) return (s['name'] ?? s['username'] ?? s['title'] ?? 'Unknown Seller').toString();
    return s?.toString() ?? 'Unknown Seller';
  }

  String _getRating() {
    final r = widget.product['rating'] ?? widget.product['averageRating'];
    if (r is num) return r.toStringAsFixed(1);
    return '0.0';
  }

  String _getLocation() {
    return (widget.product['location'] ?? '').toString();
  }

  String _getHeroTag() {
    final id = widget.product['id'];
    final idStr = (id == null || id.toString().isEmpty) ? widget.product.hashCode.toString() : id.toString();
    return 'product-$idStr${widget.heroTagSuffix ?? ""}';
  }

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

    // 3D effect parameters
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.001) // perspective
      ..rotateX(_isHovered ? 0.05 : 0)
      ..rotateY(_isHovered ? 0.05 : 0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _isHovered = true;
          });
        },
        onPanEnd: (_) => setState(() => _isHovered = false),
        onTapDown: (_) => setState(() => _isHovered = true),
        onTapUp: (_) => setState(() => _isHovered = false),
        onTapCancel: () => setState(() => _isHovered = false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        onLongPress: widget.onLongPress != null
            ? () {
                HapticFeedback.mediumImpact();
                widget.onLongPress!();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: transform,
          transformAlignment: FractionalOffset.center,
          constraints: const BoxConstraints(
            minWidth: 100,
            maxWidth: 500,
            minHeight: 242,
            maxHeight: 242,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: _isHovered ? 0.5 : 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: _isHovered ? 0.15 : 0.05),
                blurRadius: _isHovered ? 16 : 8,
                offset: Offset(0, _isHovered ? 8 : 2),
                spreadRadius: _isHovered ? 2 : 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: Hero(
                    tag: _getHeroTag(),
                    child: CustomImageWidget(
                      imageUrl: _getImage(),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              // Product Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Title
                      Text(
                        _getTitle(),
                        style: productTitleStyle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Price
                      Text(_getPrice(), style: priceStyle),

                      const SizedBox(height: 4),

                      // Seller Info
                      if (widget.showSeller) ...[
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'person',
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _getSellerName(),
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
                            _getRating(),
                            style: metaStyle.copyWith(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          if (widget.showLocation && _getLocation().isNotEmpty) ...[
                            const SizedBox(width: 8),
                            CustomIconWidget(
                              iconName: 'location_on',
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _getLocation(),
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
