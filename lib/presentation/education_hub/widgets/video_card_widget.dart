import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class VideoCardWidget extends StatelessWidget {
  const VideoCardWidget({
    super.key,
    required this.thumbnailUrl,
    required this.title,
    this.subtitle,
    this.duration,
    this.views,
    this.onTap,
  });

  final String thumbnailUrl;
  final String title;
  final String? subtitle;
  final String? duration;
  final String? views;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with play overlay
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: colorScheme.surface,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: colorScheme.surface,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                  // Gradient bottom
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Color(0x99000000),
                            Color(0x00000000),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Duration chip
                  if (duration != null && duration!.isNotEmpty)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          duration!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  // Play button
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Texts
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
            if ((subtitle != null && subtitle!.isNotEmpty) ||
                (views != null && views!.isNotEmpty))
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Expanded(
                        child: Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                    if (views != null && views!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.remove_red_eye_outlined,
                          size: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 4),
                      Text(
                        views!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
