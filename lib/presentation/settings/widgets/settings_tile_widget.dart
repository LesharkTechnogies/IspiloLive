import 'package:flutter/material.dart';
import '../../../widgets/custom_icon_widget.dart';

class SettingsTileWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? iconName;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  const SettingsTileWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.iconName,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        ListTile(
          dense: true, // Minimizes layout spacing
          visualDensity: const VisualDensity(horizontal: 0, vertical: -2), // Compacts vertical height further
          contentPadding: EdgeInsets.zero,
          leading: iconName != null
              ? CustomIconWidget(
                  iconName: iconName!,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  size: 22, // Slightly reduced icon size for compact layout
                )
              : null,
          title: Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500, // Makes text pop for high contrast
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                )
              : null,
          trailing: trailing ??
              (onTap != null
                  ? CustomIconWidget(
                      iconName: 'chevron_right',
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      size: 20,
                    )
                  : null),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            color: theme.dividerColor,
          ),
      ],
    );
  }
}
