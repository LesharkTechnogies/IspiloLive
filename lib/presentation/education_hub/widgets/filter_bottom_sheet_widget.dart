import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class FilterBottomSheetWidget extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onFiltersApplied;

  const FilterBottomSheetWidget({
    super.key,
    required this.currentFilters,
    required this.onFiltersApplied,
  });

  @override
  State<FilterBottomSheetWidget> createState() =>
      _FilterBottomSheetWidgetState();
}

class _FilterBottomSheetWidgetState extends State<FilterBottomSheetWidget> {
  late Map<String, dynamic> _filters;

  final List<String> _categories = [
    'All Categories',
    'Network Security',
    'Routing & Switching',
    'Wireless Technologies',
    'Network Management',
    'Cloud Networking',
    'VoIP & Telephony',
    'Fiber Optics',
  ];

  final List<String> _skillLevels = [
    'All Levels',
    'Beginner',
    'Intermediate',
    'Advanced',
    'Expert',
  ];

  final List<String> _durations = [
    'Any Duration',
    'Under 2 hours',
    '2-5 hours',
    '5-10 hours',
    '10+ hours',
  ];

  final List<String> _priceRanges = [
    'Any Price',
    'Free',
    'Under \$50',
    '\$50 - \$100',
    '\$100 - \$200',
    'Over \$200',
  ];

  @override
  void initState() {
    super.initState();
    _filters = Map<String, dynamic>.from(widget.currentFilters);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(context, theme),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterSection(
                    'Category',
                    _categories,
                    _filters['category'] as String? ?? 'All Categories',
                    (value) => setState(() => _filters['category'] = value),
                    theme,
                  ),
                  _buildFilterSection(
                    'Skill Level',
                    _skillLevels,
                    _filters['skillLevel'] as String? ?? 'All Levels',
                    (value) => setState(() => _filters['skillLevel'] = value),
                    theme,
                  ),
                  _buildFilterSection(
                    'Duration',
                    _durations,
                    _filters['duration'] as String? ?? 'Any Duration',
                    (value) => setState(() => _filters['duration'] = value),
                    theme,
                  ),
                  _buildFilterSection(
                    'Price Range',
                    _priceRanges,
                    _filters['priceRange'] as String? ?? 'Any Price',
                    (value) => setState(() => _filters['priceRange'] = value),
                    theme,
                  ),
                  SizedBox(height: 2.h),
                ],
              ),
            ),
          ),
          _buildActionButtons(context, theme),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Filter Courses',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: CustomIconWidget(
              iconName: 'close',
              size: 24.sp,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(
    String title,
    List<String> options,
    String selectedValue,
    ValueChanged<String> onChanged,
    ThemeData theme,
  ) {
    return ExpansionTile(
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        selectedValue,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
      children: options.map((option) {
        final isSelected = option == selectedValue;
        return ListTile(
          title: Text(
            option,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
          trailing: isSelected
              ? CustomIconWidget(
                  iconName: 'check',
                  size: 20.sp,
                  color: theme.colorScheme.primary,
                )
              : null,
          onTap: () => onChanged(option),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _filters = {
                    'category': 'All Categories',
                    'skillLevel': 'All Levels',
                    'duration': 'Any Duration',
                    'priceRange': 'Any Price',
                  };
                });
              },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Clear All',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                widget.onFiltersApplied(_filters);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Apply Filters',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
