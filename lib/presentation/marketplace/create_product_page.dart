import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/cloudinary_service.dart';
import '../../core/services/marketplace_service.dart';

class CreateProductPage extends StatefulWidget {
  const CreateProductPage({super.key});

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _locationController = TextEditingController();
  
  String _selectedCategory = 'Electronics';
  String _selectedCondition = 'New';
  
    final List<String> _categories = [
          'Wireless Solutions',
          'Fiber Optic Solutions',
          'Network Infrastructure & Cabling',
          'IT Systems & Software',
          'Electronics & Power',
          'Installation & Technical Services',
          'Managed Services & Support'
        ];
          
 final List<String> _conditions = [
  'New',
  'Refurbished - Like New',
  'Refurbished - Good',
  'Refurbished - Fair'
];
  
  final List<XFile> _selectedImages = [];
  bool _isLoading = false;
  
  Future<void> _pickImages() async {
    if (_selectedImages.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only select up to 4 images.')),
      );
      return;
    }
    
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    
    if (pickedFiles.isNotEmpty) {
      setState(() {
        final remainingSlots = 4 - _selectedImages.length;
        _selectedImages.addAll(pickedFiles.take(remainingSlots));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Widget _buildImagePreview(XFile image) {
    if (kIsWeb) {
      return Image.network(image.path, fit: BoxFit.cover);
    } else {
      return Image.file(File(image.path), fit: BoxFit.cover);
    }
  }

  Future<void> _submitProduct() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one product image')),
        );
        return;
      }
      
      setState(() => _isLoading = true);
      
      try {
        List<String> uploadedUrls = [];
        for (var image in _selectedImages) {
          final imageUrl = await CloudinaryService.uploadFile(image.path);
          if (imageUrl != null) {
            uploadedUrls.add(imageUrl);
          }
        }
        
        if (uploadedUrls.isEmpty) {
          throw Exception('Failed to upload any images');
        }
        
        final mainImage = uploadedUrls.first;
        
        final productData = {
          "title": _titleController.text.trim(),
          "description": _descController.text.trim(),
          "price": double.tryParse(_priceController.text) ?? 0.0,
          "stockQuantity": int.tryParse(_stockController.text) ?? 1,
          "mainImage": mainImage,
          "images": uploadedUrls,
          if (uploadedUrls.length > 1) "imageUrl1": uploadedUrls[1],
          if (uploadedUrls.length > 2) "imageUrl2": uploadedUrls[2],
          if (uploadedUrls.length > 3) "imageUrl3": uploadedUrls[3],
          "category": _selectedCategory,
          "condition": _selectedCondition,
          "location": _locationController.text.trim(),
        };
        
        await MarketplaceService.createProduct(productData);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product posted successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        debugPrint('Product creation error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to post product. Please try again.')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Product Images (${_selectedImages.length}/4)', 
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  if (_selectedImages.length < 4)
                    TextButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Iconsax.add, size: 18),
                      label: const Text('Add Images'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              
              if (_selectedImages.isEmpty)
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.primary.withAlpha(100), width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.image, size: 48, color: colorScheme.primary),
                        const SizedBox(height: 8),
                        Text('Tap to select up to 4 images', 
                            style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length + (_selectedImages.length < 4 ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _selectedImages.length) {
                        return GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colorScheme.primary.withAlpha(100), width: 1, style: BorderStyle.solid),
                            ),
                            child: Icon(Iconsax.add, color: colorScheme.primary, size: 32),
                          ),
                        );
                      }

                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: index == 0 ? colorScheme.primary : colorScheme.outline.withAlpha(100),
                                width: index == 0 ? 2 : 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(index == 0 ? 10 : 11),
                              child: SizedBox.expand(
                                child: _buildImagePreview(_selectedImages[index]),
                              ),
                            ),
                          ),
                          if (index == 0)
                            Positioned(
                              bottom: 4,
                              left: 4,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Main',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          Positioned(
                            top: 4,
                            right: 16,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                
              const SizedBox(height: 24),
              
              // Product Details
              Text('Product Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'What are you selling?',
                  prefixIcon: Icon(Iconsax.box),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter product title' : null,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        hintText: '0.00',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Enter price' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stock',
                        hintText: '1',
                        prefixIcon: Icon(Iconsax.layer),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Enter stock' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Iconsax.category),
                ),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedCategory = v);
                },
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedCondition,
                decoration: const InputDecoration(
                  labelText: 'Condition',
                  prefixIcon: Icon(Iconsax.info_circle),
                ),
                items: _conditions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedCondition = v);
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'e.g. Nairobi',
                  prefixIcon: Icon(Iconsax.location),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter location' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe your product in detail...',
                  prefixIcon: Icon(Iconsax.document_text),
                ),
                minLines: 3,
                maxLines: 5,
                validator: (v) => v == null || v.isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitProduct,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Post Product', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
