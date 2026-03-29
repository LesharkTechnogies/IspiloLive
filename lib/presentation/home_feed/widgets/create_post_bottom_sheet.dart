import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../model/social_model.dart';
import '../../../model/repository/social_repository.dart';

class CreatePostBottomSheet extends StatefulWidget {
  final VoidCallback onPostCreated;
  final PostModel? existingPost;

  const CreatePostBottomSheet({
    super.key,
    required this.onPostCreated,
    this.existingPost,
  });

  /// Helper to statically show the bottom sheet globally
  static void show(BuildContext context, {required VoidCallback onPostCreated, PostModel? existingPost}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreatePostBottomSheet(
        onPostCreated: onPostCreated,
        existingPost: existingPost,
      ),
    );
  }

  @override
  State<CreatePostBottomSheet> createState() => _CreatePostBottomSheetState();
}

class _CreatePostBottomSheetState extends State<CreatePostBottomSheet> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  
  bool _isLoading = false;
  bool _showImageInput = false;

  @override
  void initState() {
    super.initState();
    // If we're editing an existing post, populate the fields
    if (widget.existingPost != null) {
      _contentController.text = widget.existingPost!.content;
      if (widget.existingPost!.images.isNotEmpty) {
        _imageUrlController.text = widget.existingPost!.images.first;
        _showImageInput = true;
      } else if (widget.existingPost!.imageUrl != null && widget.existingPost!.imageUrl!.isNotEmpty) {
        _imageUrlController.text = widget.existingPost!.imageUrl!;
        _showImageInput = true;
      }
    }
  }

  Future<void> _submitPost() async {
    final text = _contentController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post content cannot be empty.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final imgUrl = _imageUrlController.text.trim();
      final mediaUrls = imgUrl.isNotEmpty ? [imgUrl] : <String>[];

      if (widget.existingPost != null) {
        // Edit existing post
        await PostRepository.updatePost(
          postId: widget.existingPost!.id,
          content: text,
          images: mediaUrls,
        );
      } else {
        // Create new post
        await PostRepository.createPost(
          description: text,
          mediaUrls: mediaUrls,
        );
      }

      widget.onPostCreated();
      if (mounted) {
        Navigator.pop(context); // Close the sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.existingPost != null ? 'Post updated successfully!' : 'Post created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish post: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInsets = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: 60.h + bottomInsets,
      padding: EdgeInsets.only(bottom: bottomInsets),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 1.5.h),
              height: 5,
              width: 40,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withAlpha(50),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 5.w),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.existingPost != null ? 'Edit Post' : 'Create Post',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : Text(widget.existingPost != null ? 'Update' : 'Post', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),

                // Text Input
                TextField(
                  controller: _contentController,
                  maxLines: 5,
                  minLines: 3,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'What do you want to talk about?',
                    border: InputBorder.none,
                    hintStyle: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withAlpha(120),
                    ),
                  ),
                ),
                SizedBox(height: 2.h),

                // Image URL Input visibility toggle
                if (_showImageInput)
                  Container(
                    margin: EdgeInsets.only(bottom: 2.h),
                    padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(100),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _imageUrlController,
                      decoration: InputDecoration(
                        hintText: 'Paste an image link here (https://...)',
                        border: InputBorder.none,
                        icon: Icon(Icons.link, color: colorScheme.primary),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.close, color: colorScheme.onSurface.withAlpha(100)),
                          onPressed: () {
                            _imageUrlController.clear();
                            setState(() => _showImageInput = false);
                          },
                        ),
                      ),
                    ),
                  ),

                const Divider(),
                
                // Toolbar
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.image_outlined, color: _showImageInput ? colorScheme.primary : colorScheme.onSurfaceVariant),
                      tooltip: 'Attach Image via URL',
                      onPressed: () {
                        setState(() => _showImageInput = !_showImageInput);
                      },
                    ),
                    const Spacer(),
                    Text(
                      'More attachment formats coming soon',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface.withAlpha(100),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
