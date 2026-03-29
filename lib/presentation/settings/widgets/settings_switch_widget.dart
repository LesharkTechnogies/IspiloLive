import 'package:flutter/material.dart';
import '../../../widgets/custom_icon_widget.dart';

class SettingsSwitchWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? iconName;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  const SettingsSwitchWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.iconName,
    required this.value,
    required this.onChanged,
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
                  size: 22,
                )
              : null,
          title: Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500, // Better contrast
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
          trailing: Switch(
            value: value,
            onChanged: onChanged,
          ),
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
