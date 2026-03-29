import 'package:flutter/material.dart';

// google_fonts not used here
/// Reusable profile avatar that shows a network/local image when available,
/// falls back to an Icon, and optionally displays an online status badge.
class ProfileAvatar extends StatelessWidget {
  final String? imageUrl; // can be a network url or local file path
  final double size;
  final bool isOnline;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.size = 40,
    this.isOnline = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: ClipOval(
              child: imageUrl == null || imageUrl!.isEmpty
                  ? Icon(
                      Icons.account_circle,
                      size: size,
                      color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                    )
                  : Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      width: size,
                      height: size,
                      errorBuilder: (context, error, stack) => Icon(
                        Icons.account_circle,
                        size: size,
                        color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                      ),
                    ),
            ),
          ),
          if (isOnline)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: Colors.greenAccent.shade700,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: theme.colorScheme.surface, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
