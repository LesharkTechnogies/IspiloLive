import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class PostContentPage extends StatelessWidget {
  final Map<String, dynamic> postData;

  const PostContentPage({super.key, required this.postData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final String username = postData['username'] as String? ?? 'Unknown User';
    final String timestamp = postData['timestamp'] as String? ?? '';
    final String content = postData['content'] as String? ?? '';

    final int wordCount = content
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Full post'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(4.w, 1.6.h, 4.w, 1.2.h),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 0.4.h),
                  Text(
                    [
                      if (timestamp.isNotEmpty) timestamp,
                      '$wordCount words',
                    ].join(' • '),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
                  child: SelectableText(
                    content.isNotEmpty ? content : 'No content available.',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 1.5,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
