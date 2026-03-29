import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom bottom navigation bar implementing adaptive tab persistence
/// with professional social minimalism design for ISP community
enum CustomBottomBarVariant {
  standard,
  floating,
  minimal,
}

class CustomBottomBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final CustomBottomBarVariant variant;
  final bool showLabels;
  final double? elevation;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    this.onTap,
    this.variant = CustomBottomBarVariant.standard,
    this.showLabels = true,
    this.elevation,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
  });

  @override
  State<CustomBottomBar> createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends State<CustomBottomBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Navigation items with routes
  final List<_BottomNavItem> _navItems = [
    _BottomNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
      route: '/home-feed',
    ),
    _BottomNavItem(
      icon: Icons.school_outlined,
      activeIcon: Icons.school,
      label: 'Education',
      route: '/education-hub',
    ),
    _BottomNavItem(
      icon: Icons.store_outlined,
      activeIcon: Icons.store,
      label: 'Marketplace',
      route: '/marketplace',
    ),
    _BottomNavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Settings',
      route: '/settings',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.variant) {
      case CustomBottomBarVariant.floating:
        return _buildFloatingBottomBar(context);
      case CustomBottomBarVariant.minimal:
        return _buildMinimalBottomBar(context);
      case CustomBottomBarVariant.standard:
        return _buildStandardBottomBar(context);
    }
  }

  Widget _buildStandardBottomBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final safeHeight = kBottomNavigationBarHeight + bottomPadding;

    return Container(
      height: safeHeight,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Container(
        height: kBottomNavigationBarHeight,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _navItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = index == widget.currentIndex;

            return _buildNavItem(
              context,
              item,
              index,
              isSelected,
              theme,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFloatingBottomBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final safeHeight = kBottomNavigationBarHeight + bottomPadding;

    return Container(
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: safeHeight,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withAlpha(38),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            height: kBottomNavigationBarHeight,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _navItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = index == widget.currentIndex;

                return _buildNavItem(
                  context,
                  item,
                  index,
                  isSelected,
                  theme,
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalBottomBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final safeHeight = kBottomNavigationBarHeight + bottomPadding;

    return Container(
      height: safeHeight,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withAlpha(51),
            width: 1,
          ),
        ),
      ),
      child: Container(
        height: kBottomNavigationBarHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _navItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = index == widget.currentIndex;

            return _buildMinimalNavItem(
              context,
              item,
              index,
              isSelected,
              theme,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    _BottomNavItem item,
    int index,
    bool isSelected,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;
    final selectedColor = widget.selectedItemColor ?? colorScheme.primary;
    final unselectedColor =
        widget.unselectedItemColor ?? colorScheme.onSurface.withAlpha(153);

    return Expanded(
      child: GestureDetector(
        onTap: () => _handleTap(index, item.route),
        onTapDown: (_) => _animationController.forward(),
        onTapUp: (_) => _animationController.reverse(),
        onTapCancel: () => _animationController.reverse(),
        child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale:
                    index == widget.currentIndex ? _scaleAnimation.value : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  // Flexible is not valid here because its parent is not a Flex (Row/Column).
                  // Use Column directly and let the surrounding Expanded control sizing.
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? selectedColor.withAlpha(26)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: isSelected ? selectedColor : unselectedColor,
                          size: 16,
                        ),
                      ),
                      if (widget.showLabels) ...[
                        const SizedBox(height: 0),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight:
                                isSelected ? FontWeight.w500 : FontWeight.w400,
                            color: isSelected ? selectedColor : unselectedColor,
                          ),
                          child: Text(item.label),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
      ),
    );
  }

  Widget _buildMinimalNavItem(
    BuildContext context,
    _BottomNavItem item,
    int index,
    bool isSelected,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;
    final selectedColor = widget.selectedItemColor ?? colorScheme.primary;
    final unselectedColor =
        widget.unselectedItemColor ?? colorScheme.onSurface.withAlpha(153);

    return GestureDetector(
      onTap: () => _handleTap(index, item.route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              color: isSelected ? selectedColor : unselectedColor,
              size: 22,
            ),
            if (widget.showLabels) ...[
              const SizedBox(height: 0),
              Text(
                item.label,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  color: isSelected ? selectedColor : unselectedColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleTap(int index, String route) {
    // Provide haptic feedback
    HapticFeedback.lightImpact();

    // Call the onTap callback
    widget.onTap?.call(index);

    // Navigate to the route if different from current
    if (index != widget.currentIndex) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        route,
        (route) => false,
      );
    }
  }
}

/// Internal class to represent bottom navigation items
class _BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const _BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}
