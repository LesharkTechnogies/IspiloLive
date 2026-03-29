import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class ShippingPolicySection extends StatefulWidget {
  final String shippingInfo;
  final String returnPolicy;
  final String estimatedDelivery;
  final String shippingCost;

  const ShippingPolicySection({
    super.key,
    required this.shippingInfo,
    required this.returnPolicy,
    required this.estimatedDelivery,
    required this.shippingCost,
  });

  @override
  State<ShippingPolicySection> createState() => _ShippingPolicySectionState();
}

class _ShippingPolicySectionState extends State<ShippingPolicySection> {
  bool _isShippingExpanded = false;
  bool _isReturnExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Shipping Information
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isShippingExpanded = !_isShippingExpanded;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'local_shipping',
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Shipping & Delivery',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.estimatedDelivery} • ${widget.shippingCost}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          turns: _isShippingExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: CustomIconWidget(
                            iconName: 'keyboard_arrow_down',
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Container(
                    padding:
                        const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    child: Text(
                      widget.shippingInfo,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurface.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                    ),
                  ),
                  crossFadeState: _isShippingExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Return Policy
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isReturnExpanded = !_isReturnExpanded;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'assignment_return',
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Return Policy',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        AnimatedRotation(
                          turns: _isReturnExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: CustomIconWidget(
                            iconName: 'keyboard_arrow_down',
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Container(
                    padding:
                        const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    child: Text(
                      widget.returnPolicy,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurface.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                    ),
                  ),
                  crossFadeState: _isReturnExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
