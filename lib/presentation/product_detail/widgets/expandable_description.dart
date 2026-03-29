import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExpandableDescription extends StatefulWidget {
  final String description;
  final int maxLines;

  const ExpandableDescription({
    super.key,
    required this.description,
    this.maxLines = 3,
  });

  @override
  State<ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<ExpandableDescription> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedCrossFade(
            firstChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                  maxLines: widget.maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_shouldShowReadMore())
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isExpanded = true;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Read More',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = false;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Read Less',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  bool _shouldShowReadMore() {
    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.description,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
      ),
      maxLines: widget.maxLines,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: double.infinity);
    return textPainter.didExceedMaxLines;
  }
}
