import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme_provider.dart';
import '../widgets/profile_avatar.dart';

/// Custom app bar widget implementing Professional Social Minimalism design
/// with enterprise-grade reliability and trust signals for ISP community
enum CustomAppBarVariant {
  standard,
  search,
  profile,
  settings,
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final CustomAppBarVariant variant;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final bool showSearchField;
  final String? searchHint;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchSubmitted;
  final bool showNotificationBadge;
  final int notificationCount;

  const CustomAppBar({
    super.key,
    this.title,
    this.variant = CustomAppBarVariant.standard,
    this.actions,
    this.leading,
    this.showBackButton = false,
    this.onBackPressed,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.showSearchField = false,
    this.searchHint = 'Search...',
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.showNotificationBadge = false,
    this.notificationCount = 0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return AppBar(
      title: _buildTitle(context, theme, isLight),
      leading: _buildLeading(context, theme),
      actions: _buildActions(context, theme, isLight),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? colorScheme.surface,
      foregroundColor: foregroundColor ?? colorScheme.onSurface,
      elevation: elevation,
      shadowColor: theme.shadowColor,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
        statusBarBrightness: isLight ? Brightness.light : Brightness.dark,
      ),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: foregroundColor ?? colorScheme.onSurface,
      ),
    );
  }

  Widget? _buildTitle(BuildContext context, ThemeData theme, bool isLight) {
    switch (variant) {
      case CustomAppBarVariant.search:
        if (showSearchField) {
          return _buildSearchField(context, theme);
        }
        return _buildTitleText(theme);
      case CustomAppBarVariant.standard:
      case CustomAppBarVariant.profile:
      case CustomAppBarVariant.settings:
        return _buildTitleText(theme);
    }
  }

  Widget? _buildTitleText(ThemeData theme) {
    if (title == null) return null;

    return Text(
      title!,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: foregroundColor ?? theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildSearchField(BuildContext context, ThemeData theme) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha(77),
        ),
      ),
      child: TextField(
        onChanged: onSearchChanged,
        onSubmitted: (_) => onSearchSubmitted?.call(),
        style: GoogleFonts.inter(
          fontSize: 14,
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: searchHint,
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withAlpha(153),
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: theme.colorScheme.onSurface.withAlpha(153),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  Widget? _buildLeading(BuildContext context, ThemeData theme) {
    if (leading != null) return leading;

    if (showBackButton) {
      return IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
        tooltip: 'Back',
      );
    }

    // Show menu button for main screens
    if (variant == CustomAppBarVariant.standard) {
      return IconButton(
        icon: Image.asset(
          'assets/images/ispilo.png',
          width: 28,
          height: 28,
        ),
        onPressed: () {
          if (Scaffold.maybeOf(context)?.hasDrawer ?? false) {
            Scaffold.of(context).openDrawer();
          }
        },
        tooltip: 'Ispilo',
      );
    }

    return null;
  }

  List<Widget>? _buildActions(
      BuildContext context, ThemeData theme, bool isLight) {
    final List<Widget> actionWidgets = [];

    // Add variant-specific actions
    switch (variant) {
      case CustomAppBarVariant.standard:
        actionWidgets.addAll(_buildStandardActions(context, theme, isLight));
        break;
      case CustomAppBarVariant.search:
        actionWidgets.addAll(_buildSearchActions(context, theme));
        break;
      case CustomAppBarVariant.profile:
        actionWidgets.addAll(_buildProfileActions(context, theme));
        break;
      case CustomAppBarVariant.settings:
        actionWidgets.addAll(_buildSettingsActions(context, theme));
        break;
    }

    // Add custom actions
    if (actions != null) {
      actionWidgets.addAll(actions!);
    }

    return actionWidgets.isNotEmpty ? actionWidgets : null;
  }

  List<Widget> _buildStandardActions(
      BuildContext context, ThemeData theme, bool isLight) {
    return [
      // Theme toggle action
      Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: 'Toggle Theme',
          );
        },
      ),
      // Search action
      // IconButton(
      //   icon: const Icon(Icons.search),
      //   onPressed: () => Navigator.pushNamed(context, '/education-hub'),
      //   tooltip: 'Search',
      // ),
      // Notifications with badge
      Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _showNotifications(context),
            tooltip: 'Notifications',
          ),
          if (showNotificationBadge && notificationCount > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  notificationCount > 99 ? '99+' : notificationCount.toString(),
                  style: GoogleFonts.inter(
                    color: theme.colorScheme.onError,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      // Profile action (dynamic avatar)
      IconButton(
        icon: ProfileAvatar(
          imageUrl: null, // will be replaced by settings/profile data if wired
          size: 28,
          isOnline: false,
        ),
        onPressed: () => Navigator.pushNamed(context, '/settings'),
        tooltip: 'Profile',
      ),
      // Message action on the right end
      IconButton(
        icon: const Icon(Icons.mail_outline),
        onPressed: () => Navigator.pushNamed(context, '/messages'),
        tooltip: 'Messages',
      ),
    ];
  }

  List<Widget> _buildSearchActions(BuildContext context, ThemeData theme) {
    return [
      IconButton(
        icon: const Icon(Icons.filter_list),
        onPressed: () => _showFilterOptions(context),
        tooltip: 'Filter',
      ),
    ];
  }

  List<Widget> _buildProfileActions(BuildContext context, ThemeData theme) {
    return [
      IconButton(
        icon: const Icon(Icons.edit_outlined),
        onPressed: () => _editProfile(context),
        tooltip: 'Edit Profile',
      ),
      IconButton(
        icon: const Icon(Icons.settings_outlined),
        onPressed: () => Navigator.pushNamed(context, '/settings'),
        tooltip: 'Settings',
      ),
    ];
  }

  List<Widget> _buildSettingsActions(BuildContext context, ThemeData theme) {
    return [
      IconButton(
        icon: const Icon(Icons.help_outline),
        onPressed: () => _showHelp(context),
        tooltip: 'Help',
      ),
    ];
  }

  void _showNotifications(BuildContext context) {
    // Implement notifications panel
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            const Expanded(
              child: Center(
                child: Text('No new notifications'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterOptions(BuildContext context) {
    // Implement filter options
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Options',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Recent'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Popular'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _editProfile(BuildContext context) {
    // Navigate to profile edit screen
    Navigator.pushNamed(context, '/settings');
  }

  void _showHelp(BuildContext context) {
    // Show help dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help'),
        content: const Text('Help information will be displayed here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
