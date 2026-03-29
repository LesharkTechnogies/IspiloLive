import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom tab bar widget implementing professional social minimalism
/// with smooth transitions and enterprise-grade reliability
enum CustomTabBarVariant {
  standard,
  pills,
  underline,
  segmented,
}

class CustomTabBar extends StatefulWidget {
  final List<String> tabs;
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final CustomTabBarVariant variant;
  final bool isScrollable;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? indicatorColor;
  final EdgeInsetsGeometry? padding;
  final double? height;

  const CustomTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    this.onTap,
    this.variant = CustomTabBarVariant.standard,
    this.isScrollable = false,
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
    this.indicatorColor,
    this.padding,
    this.height,
  });

  @override
  State<CustomTabBar> createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    // scale animation removed: kept the controller for timing/haptic sync
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.variant) {
      case CustomTabBarVariant.pills:
        return _buildPillsTabBar(context);
      case CustomTabBarVariant.underline:
        return _buildUnderlineTabBar(context);
      case CustomTabBarVariant.segmented:
        return _buildSegmentedTabBar(context);
      case CustomTabBarVariant.standard:
        return _buildStandardTabBar(context);
    }
  }

  Widget _buildStandardTabBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: widget.height ?? 48,
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withAlpha(51),
            width: 1,
          ),
        ),
      ),
      child: widget.isScrollable
          ? _buildScrollableTabBar(context, theme)
          : _buildFixedTabBar(context, theme),
    );
  }

  Widget _buildPillsTabBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: widget.height ?? 40,
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? colorScheme.surface,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: widget.tabs.asMap().entries.map((entry) {
            final index = entry.key;
            final tab = entry.value;
            final isSelected = index == widget.currentIndex;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildPillTab(context, tab, index, isSelected, theme),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildUnderlineTabBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: widget.height ?? 48,
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? colorScheme.surface,
      ),
      child: Row(
        children: widget.tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = index == widget.currentIndex;

          return Expanded(
            child: _buildUnderlineTab(context, tab, index, isSelected, theme),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSegmentedTabBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: widget.height ?? 40,
      margin: widget.padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withAlpha(77),
        ),
      ),
      child: Row(
        children: widget.tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = index == widget.currentIndex;
          final isFirst = index == 0;
          final isLast = index == widget.tabs.length - 1;

          return Expanded(
            child: _buildSegmentedTab(
              context,
              tab,
              index,
              isSelected,
              isFirst,
              isLast,
              theme,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScrollableTabBar(BuildContext context, ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: widget.tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = index == widget.currentIndex;

          return _buildStandardTab(context, tab, index, isSelected, theme);
        }).toList(),
      ),
    );
  }

  Widget _buildFixedTabBar(BuildContext context, ThemeData theme) {
    return Row(
      children: widget.tabs.asMap().entries.map((entry) {
        final index = entry.key;
        final tab = entry.value;
        final isSelected = index == widget.currentIndex;

        return Expanded(
          child: _buildStandardTab(context, tab, index, isSelected, theme),
        );
      }).toList(),
    );
  }

  Widget _buildStandardTab(
    BuildContext context,
    String tab,
    int index,
    bool isSelected,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;
    final selectedColor = widget.selectedColor ?? colorScheme.primary;
    final unselectedColor =
        widget.unselectedColor ?? colorScheme.onSurface.withAlpha(153);

    return GestureDetector(
      onTap: () => _handleTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? (widget.indicatorColor ?? selectedColor)
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          tab,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? selectedColor : unselectedColor,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildPillTab(
    BuildContext context,
    String tab,
    int index,
    bool isSelected,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;
    final selectedColor = widget.selectedColor ?? colorScheme.primary;
    final unselectedColor =
        widget.unselectedColor ?? colorScheme.onSurface.withAlpha(153);

    return GestureDetector(
      onTap: () => _handleTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? selectedColor : colorScheme.outline.withAlpha(77),
          ),
        ),
        child: Text(
          tab,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            color: isSelected ? colorScheme.onPrimary : unselectedColor,
          ),
        ),
      ),
    );
  }

  Widget _buildUnderlineTab(
    BuildContext context,
    String tab,
    int index,
    bool isSelected,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;
    final selectedColor = widget.selectedColor ?? colorScheme.primary;
    final unselectedColor =
        widget.unselectedColor ?? colorScheme.onSurface.withAlpha(153);

    return GestureDetector(
      onTap: () => _handleTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? (widget.indicatorColor ?? selectedColor)
                  : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          tab,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? selectedColor : unselectedColor,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSegmentedTab(
    BuildContext context,
    String tab,
    int index,
    bool isSelected,
    bool isFirst,
    bool isLast,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;
    final selectedColor = widget.selectedColor ?? colorScheme.primary;
    final unselectedColor =
        widget.unselectedColor ?? colorScheme.onSurface.withAlpha(153);

    return GestureDetector(
      onTap: () => _handleTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isFirst ? 7 : 0),
            bottomLeft: Radius.circular(isFirst ? 7 : 0),
            topRight: Radius.circular(isLast ? 7 : 0),
            bottomRight: Radius.circular(isLast ? 7 : 0),
          ),
        ),
        child: Center(
          child: Text(
            tab,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              color: isSelected ? colorScheme.onPrimary : unselectedColor,
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(int index) {
    // Provide haptic feedback for micro-feedback animations
    HapticFeedback.lightImpact();

    // Trigger scale animation
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Call the onTap callback
    widget.onTap?.call(index);
  }
}
