import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:image_picker/image_picker.dart';
import '../../../model/social_model.dart';

import '../../../model/repository/social_repository.dart';
import '../../../core/services/cloudinary_service.dart';

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
  final List<String> _mediaUrls = [];
  
  bool _isLoading = false;
  bool _isUploadingFile = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // If we're editing an existing post, populate the fields
    if (widget.existingPost != null) {
      _contentController.text = widget.existingPost!.content;
      if (widget.existingPost!.images.isNotEmpty) {
        _mediaUrls.addAll(widget.existingPost!.images);
      } else if (widget.existingPost!.imageUrl != null && widget.existingPost!.imageUrl!.isNotEmpty) {
        _mediaUrls.add(widget.existingPost!.imageUrl!);
      }
    }
  }

  Future<void> _pickAndUploadImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isEmpty) return;
    
    setState(() => _isUploadingFile = true);
    try {
      for (final image in images) {
        final url = await CloudinaryService.uploadFile(image.path);
        if (url != null) {
          if (!mounted) return;
          setState(() {
            _mediaUrls.add(url);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploadingFile = false);
    }
  }

  Future<void> _pickAndUploadVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;
    
    setState(() => _isUploadingFile = true);
    try {
      final url = await CloudinaryService.uploadFile(video.path, isVideo: true);
      if (url != null) {
        setState(() {
          _mediaUrls.add(url);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploadingFile = false);
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
      if (widget.existingPost != null) {
        // Edit existing post
        await PostRepository.updatePost(
          postId: widget.existingPost!.id,
          content: text,
          images: _mediaUrls,
        );
      } else {
        // Create new post
        await PostRepository.createPost(
          description: text,
          mediaUrls: _mediaUrls,
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

                // Media previews
                if (_mediaUrls.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _mediaUrls.map((url) {
                        return SizedBox(
                          width: 80,
                          height: 80,
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  url,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _mediaUrls.remove(url));
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                const Divider(),
                
                // Toolbar
                Row(
                  children: [
                    if (_isUploadingFile)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else ...[
                      IconButton(
                        icon: Icon(Icons.image, color: colorScheme.onSurfaceVariant),
                        tooltip: 'Upload Image',
                        onPressed: _pickAndUploadImages,
                      ),
                      IconButton(
                        icon: Icon(Icons.videocam, color: colorScheme.onSurfaceVariant),
                        tooltip: 'Upload Video',
                        onPressed: _pickAndUploadVideo,
                      ),
                    ],
                    const Spacer(),
                    Text(
                      'Attachments',
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
