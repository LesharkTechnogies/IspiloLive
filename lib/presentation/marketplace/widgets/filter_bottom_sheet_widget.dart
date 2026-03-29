import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class FilterBottomSheetWidget extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onApplyFilters;

  const FilterBottomSheetWidget({
    super.key,
    required this.currentFilters,
    required this.onApplyFilters,
  });

  @override
  State<FilterBottomSheetWidget> createState() =>
      _FilterBottomSheetWidgetState();
}

class _FilterBottomSheetWidgetState extends State<FilterBottomSheetWidget> {
  late Map<String, dynamic> _filters;
  RangeValues _priceRange = const RangeValues(0, 10000);

  final List<String> _categories = [
    'All Categories',
    'Hardware',
    'Software',
    'Services',
    'Tools',
  ];

  final List<String> _conditions = [
    'Any Condition',
    'New',
    'Like New',
    'Good',
    'Fair',
  ];

  // legacy placeholder removed in favor of county list

  // Countries and their regions (small curated lists for selection)
  final Map<String, List<String>> _countryRegions = {
    'Kenya': [
      'Mombasa',
      'Kwale',
      'Kilifi',
      'Tana River',
      'Lamu',
      'Taita-Taveta',
      'Garissa',
      'Wajir',
      'Mandera',
      'Marsabit',
      'Isiolo',
      'Meru',
      'Tharaka-Nithi',
      'Embu',
      'Kitui',
      'Machakos',
      'Makueni',
      'Nyandarua',
      'Nyeri',
      'Kirinyaga',
      'Murang\'a',
      'Kiambu',
      'Turkana',
      'West Pokot',
      'Samburu',
      'Trans Nzoia',
      'Uasin Gishu',
      'Elgeyo-Marakwet',
      'Nandi',
      'Baringo',
      'Laikipia',
      'Nakuru',
      'Narok',
      'Kajiado',
      'Kericho',
      'Bomet',
      'Kakamega',
      'Vihiga',
      'Bungoma',
      'Busia',
      'Siaya',
      'Kisumu',
      'Homa Bay',
      'Migori',
      'Kisii',
      'Nyamira',
      'Nairobi'
    ],
    'Uganda': [
      'Kampala',
      'Wakiso',
      'Mukono',
      'Jinja',
      'Mbale',
      'Gulu',
      'Lira',
      'Mbarara',
      'Masaka',
      'Fort Portal',
      'Hoima',
      'Soroti',
      'Kabale'
    ],
    'Tanzania': [
      'Dar es Salaam',
      'Dodoma',
      'Arusha',
      'Mwanza',
      'Zanzibar',
      'Kilimanjaro',
      'Mbeya',
      'Iringa',
      'Morogoro',
      'Tanga',
      'Kigoma',
      'Ruvuma',
      'Kagera'
    ],
  };

  String _selectedCountry = 'Kenya';
  final TextEditingController _locationSearchController =
      TextEditingController();
  List<String> _filteredLocations = [];

  @override
  void initState() {
    super.initState();
    _filters = Map<String, dynamic>.from(widget.currentFilters);
    _priceRange = RangeValues(
      (_filters['minPrice'] ?? 0).toDouble(),
      (_filters['maxPrice'] ?? 10000).toDouble(),
    );
    // initialize filtered locations with full counties list
    _filteredLocations = List<String>.from(_countryRegions[_selectedCountry]!);
    // if a location was preselected, ensure it's in the filters
    if (_filters['location'] == null) {
      _filters['location'] = 'Any Location';
    }
  }

  @override
  void dispose() {
    _locationSearchController.dispose();
    super.dispose();
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
          // Handle Bar
          Container(
            margin: EdgeInsets.only(top: 1.h),
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: _resetFilters,
                  child: Text(
                    'Reset',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategorySection(colorScheme),
                  SizedBox(height: 3.h),
                  _buildPriceRangeSection(colorScheme),
                  SizedBox(height: 3.h),
                  _buildConditionSection(colorScheme),
                  SizedBox(height: 3.h),
                  _buildLocationSection(colorScheme),
                  SizedBox(height: 3.h),
                  _buildRatingSection(colorScheme),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
          ),

          // Apply Button
          Container(
            padding: EdgeInsets.all(4.w),
            child: SizedBox(
              width: double.infinity,
              height: 6.h,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Apply Filters',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: _categories.map((category) {
            final isSelected = _filters['category'] == category;
            return GestureDetector(
              onTap: () => setState(() => _filters['category'] = category),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceRangeSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        RangeSlider(
          values: _priceRange,
          min: 0,
          max: 10000,
          divisions: 100,
          labels: RangeLabels(
            '\$${_priceRange.start.round()}',
            '\$${_priceRange.end.round()}',
          ),
          onChanged: (values) => setState(() => _priceRange = values),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '\$${_priceRange.start.round()}',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            Text(
              '\$${_priceRange.end.round()}',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConditionSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Condition',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        // Wrap with RadioGroup to avoid deprecation warnings
        RadioGroup<String>(
          groupValue: _filters['condition'] as String?,
          onChanged: (value) => setState(() => _filters['condition'] = value),
          child: Column(
            children: _conditions.map((condition) {
              return RadioListTile<String>(
                title: Text(
                  condition,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: colorScheme.onSurface,
                  ),
                ),
                value: condition,
                activeColor: colorScheme.primary,
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),

        // Country selector chips
        Wrap(
          spacing: 3.w,
          runSpacing: 1.h,
          children: _countryRegions.keys.map((country) {
            final isSelected = _selectedCountry == country;
            return ChoiceChip(
              label: Text(country, style: GoogleFonts.inter(fontSize: 12.sp)),
              selected: isSelected,
              onSelected: (sel) {
                if (!sel) return;
                setState(() {
                  _selectedCountry = country;
                  _locationSearchController.clear();
                  _filteredLocations =
                      List<String>.from(_countryRegions[country]!);
                });
              },
              selectedColor: colorScheme.primary,
              backgroundColor: colorScheme.surface,
              labelStyle: GoogleFonts.inter(
                fontSize: 12.sp,
                color:
                    isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 1.h),

        // Search field for regions
        TextField(
          controller: _locationSearchController,
          decoration: InputDecoration(
            hintText: 'Search region (e.g. Machakos)',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          ),
          onChanged: (q) {
            setState(() {
              final query = q.trim().toLowerCase();
              final regions = _countryRegions[_selectedCountry]!;
              if (query.isEmpty) {
                _filteredLocations = List<String>.from(regions);
              } else {
                _filteredLocations = regions
                    .where((c) => c.toLowerCase().contains(query))
                    .toList();
              }
            });
          },
        ),

        SizedBox(height: 1.h),

        // 'Any Location' quick option
        ListTile(
          title: Text(
            'Any Location',
            style: GoogleFonts.inter(fontSize: 14.sp),
          ),
          trailing: _filters['location'] == 'Any Location'
              ? Icon(Icons.check, color: colorScheme.primary)
              : null,
          onTap: () => setState(() => _filters['location'] = 'Any Location'),
          contentPadding: EdgeInsets.zero,
        ),

        // Filtered counties list (searchable)
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 28.h),
          child: _filteredLocations.isEmpty
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  child: Text(
                    'No matches',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredLocations.length,
                  itemBuilder: (context, idx) {
                    final loc = _filteredLocations[idx];
                    final composed = '$_selectedCountry - $loc';
                    final selected = _filters['location'] == composed;
                    return ListTile(
                      title: Text(
                        loc,
                        style: GoogleFonts.inter(fontSize: 14.sp),
                      ),
                      trailing: selected
                          ? Icon(Icons.check, color: colorScheme.primary)
                          : null,
                      onTap: () =>
                          setState(() => _filters['location'] = composed),
                      contentPadding: EdgeInsets.zero,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRatingSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minimum Rating',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        Slider(
          value: (_filters['minRating'] ?? 0).toDouble(),
          min: 0,
          max: 5,
          divisions: 5,
          label: '${(_filters['minRating'] ?? 0).toDouble()} stars',
          onChanged: (value) => setState(() => _filters['minRating'] = value),
        ),
      ],
    );
  }

  void _resetFilters() {
    setState(() {
      _filters.clear();
      _priceRange = const RangeValues(0, 10000);
    });
  }

  void _applyFilters() {
    _filters['minPrice'] = _priceRange.start.round();
    _filters['maxPrice'] = _priceRange.end.round();
    widget.onApplyFilters(_filters);
    Navigator.pop(context);
  }
}
