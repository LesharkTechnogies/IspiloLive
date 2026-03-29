import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class ActionButtonsBar extends StatelessWidget {
  final VoidCallback onContactSeller;
  final VoidCallback onMakeOffer;
  final VoidCallback onSaveProduct;
  final bool isSaved;

  const ActionButtonsBar({
    super.key,
    required this.onContactSeller,
    required this.onMakeOffer,
    required this.onSaveProduct,
    required this.isSaved,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Save Button
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onSaveProduct();
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSaved
                      ? colorScheme.primary.withValues(alpha: 0.1)
                      : colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSaved
                        ? colorScheme.primary
                        : colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: isSaved ? 'bookmark' : 'bookmark_border',
                    color: isSaved
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 24,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Contact Seller Button
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onContactSeller();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.surface,
                  foregroundColor: colorScheme.primary,
                  elevation: 0,
                  side: BorderSide(color: colorScheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomIconWidget(
                      iconName: 'chat_bubble_outline',
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Contact Seller',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Make Offer Button
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onMakeOffer();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomIconWidget(
                      iconName: 'local_offer',
                      color: colorScheme.onPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Make Offer',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
