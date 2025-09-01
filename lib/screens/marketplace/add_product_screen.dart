import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../models/product.dart';
import '../../services/platform_service.dart';
import '../../services/achievement_service.dart';
import '../../services/growth_analytics_service.dart';
import '../../widgets/achievement_notification.dart';
import '../onboarding_screen.dart';

class AddProductScreen extends StatefulWidget {
  final Product? existingProduct;

  const AddProductScreen({super.key, this.existingProduct});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _locationController;
  late TextEditingController _contactController; // New controller

  ProductType? _selectedType;
  ListingType? _selectedListingType;

  final List<File> _pickedImages = [];
  List<String> _uploadedImageUrls = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final product = widget.existingProduct;

    _nameController = TextEditingController(text: product?.name ?? '');
    _descriptionController = TextEditingController(text: product?.description ?? '');
    _priceController = TextEditingController(text: product?.price.toString() ?? '');
    _locationController = TextEditingController(text: product?.location ?? '');
    _contactController = TextEditingController(text: product?.contactNumber ?? ''); // Init contact number
    _selectedType = product?.type;
    _selectedListingType = product?.listingType;

    if (product?.images?.isNotEmpty ?? false) {
      _uploadedImageUrls = List<String>.from(product!.images!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    // Check if platform supports camera
    if (!PlatformService.instance.supportsFeature(PlatformFeature.camera)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(PlatformService.instance.getPlatformErrorMessage('Camera')),
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _pickedImages.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _pickedImages.addAll(pickedFiles.map((f) => File(f.path)));
      });
    }
  }

  Future<List<String>> _uploadImages() async {
    List<String> urls = [];
    for (final image in _pickedImages) {
      try {
        final fileName = 'products/${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';
        final ref = _firebaseStorage.ref().child(fileName);
        final uploadTask = await ref.putFile(image);
        final url = await uploadTask.ref.getDownloadURL();
        urls.add(url);
      } catch (e) {
        debugPrint('Error uploading image: $e');
      }
    }
    return urls;
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedListingType == ListingType.sell && _pickedImages.isEmpty && _uploadedImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('For selling, you must add at least one photo.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uploadedUrls = await _uploadImages();
      final allImageUrls = [..._uploadedImageUrls, ...uploadedUrls];

      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final price = double.parse(_priceController.text.trim());
      final location = _locationController.text.trim();
      final contactNumber = _contactController.text.trim();

      final isEditing = widget.existingProduct != null;

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final productId = isEditing
          ? widget.existingProduct!.id
          : _firestore.collection('products').doc().id;

      final product = Product(
        id: productId,
        sellerId: currentUser.uid,
        createdAt: isEditing ? widget.existingProduct!.createdAt : DateTime.now(),
        isAvailable: true,
        name: name,
        description: description,
        price: price,
        location: location.isNotEmpty ? location : null,
        images: allImageUrls,
        type: _selectedType ?? ProductType.other,
        listingType: _selectedListingType ?? ListingType.sell,
        contactNumber: contactNumber.isNotEmpty ? contactNumber : null,
        category: _selectedType?.toString().split('.').last ?? 'Other',
        tags: [], // Empty tags for now
        userName: currentUser.displayName ?? 'Unknown User',
      );

      await _firestore.collection('products').doc(product.id).set(product.toMap());

      // Track achievement and analytics
      if (!isEditing) {
        final achievementService = AchievementService();
        final analyticsService = GrowthAnalyticsService();
        
        await analyticsService.trackProductListed();
        final unlockedAchievement = await achievementService.updateProgress('first_product');
        final marketplaceAchievement = await achievementService.updateProgress('marketplace_seller');
        
        if (unlockedAchievement != null && mounted) {
          AchievementNotification.show(context, unlockedAchievement);
        } else if (marketplaceAchievement != null && mounted) {
          AchievementNotification.show(context, marketplaceAchievement);
        }
      }

      setState(() => _isSaving = false);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ProductPreviewScreen(product: product)),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save product: $e')),
      );
    }
  }

  Future<void> _confirmNavigateToOnboarding() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm'),
        content: const Text('Do you want to go back to onboarding? Unsaved changes will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (route) => false,
      );
    }
  }

  void _removePickedImage(int index) {
    setState(() {
      _pickedImages.removeAt(index);
    });
  }

  void _removeUploadedImage(int index) {
    setState(() {
      _uploadedImageUrls.removeAt(index);
    });
  }

  String _productTypeLabel(ProductType type) {
    switch (type) {
      case ProductType.crop:
        return 'Crop';
      case ProductType.seed:
        return 'Seed';
      case ProductType.fertilizer:
        return 'Fertilizer';
      case ProductType.tool:
        return 'Tool';
      case ProductType.other:
        return 'Other';
    }
  }

  String _listingTypeLabel(ListingType type) {
    switch (type) {
      case ListingType.sell:
        return 'Selling';
      case ListingType.buy:
        return 'Buying';
      case ListingType.barter:
        return 'Barter';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingProduct != null;

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: const Color.fromARGB(255, 132, 156, 133),
      minimumSize: const Size.fromHeight(50),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
        backgroundColor: const Color.fromARGB(255, 129, 159, 130),
      ),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Product Name'),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Please enter a name' : null,
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Please enter a description' : null,
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Price (KSh)'),
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      final price = double.tryParse(val ?? '');
                      if (price == null || price <= 0) return 'Enter a valid price';
                      return null;
                    },
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: 'Location (optional)'),
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contactController,
                    decoration: const InputDecoration(labelText: 'Contact Number'),
                    keyboardType: TextInputType.phone,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Please enter a contact number';
                      return null;
                    },
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ProductType>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(labelText: 'Product Type'),
                    items: ProductType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(_productTypeLabel(type)),
                          ),
                        )
                        .toList(),
                    onChanged: _isSaving ? null : (val) => setState(() => _selectedType = val),
                    validator: (val) => val == null ? 'Please select a product type' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ListingType>(
                    initialValue: _selectedListingType,
                    decoration: const InputDecoration(labelText: 'Listing Type'),
                    items: ListingType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(_listingTypeLabel(type)),
                          ),
                        )
                        .toList(),
                    onChanged: _isSaving ? null : (val) => setState(() => _selectedListingType = val),
                    validator: (val) => val == null ? 'Please select a listing type' : null,
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Product Photos", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  if (_pickedImages.isNotEmpty || _uploadedImageUrls.isNotEmpty)
                    SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ..._pickedImages.asMap().entries.map(
                            (entry) {
                              final idx = entry.key;
                              final file = entry.value;
                              return GestureDetector(
                                onLongPress: () => _removePickedImage(idx),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          file,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => _removePickedImage(idx),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          ..._uploadedImageUrls.asMap().entries.map(
                            (entry) {
                              final idx = entry.key;
                              final url = entry.value;
                              return GestureDetector(
                                onLongPress: () => _removeUploadedImage(idx),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          url,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Container(
                                              width: 120,
                                              height: 120,
                                              color: Colors.grey.shade200,
                                              child: const Center(
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              ),
                                            );
                                          },
                                          errorBuilder: (context, error, stackTrace) {
                                            debugPrint('Image load error: $error');
                                            return Container(
                                              width: 120,
                                              height: 120,
                                              color: Colors.grey.shade200,
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(Icons.broken_image, color: Colors.grey),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Image failed',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => _removeUploadedImage(idx),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    )
                  else
                    const Text("No photos selected."),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _takePicture,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text("Camera"),
                          style: buttonStyle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _pickFromGallery,
                          icon: const Icon(Icons.photo_library),
                          label: const Text("Gallery"),
                          style: buttonStyle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveProduct,
                    onLongPress: _confirmNavigateToOnboarding,
                    style: buttonStyle,
                    child: _isSaving
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : Text(isEditing ? 'Save Changes' : 'Add Product'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductPreviewScreen extends StatelessWidget {
  final Product product;
  const ProductPreviewScreen({super.key, required this.product});

  String _productTypeLabel(ProductType type) {
    switch (type) {
      case ProductType.crop:
        return 'Crop';
      case ProductType.seed:
        return 'Seed';
      case ProductType.fertilizer:
        return 'Fertilizer';
      case ProductType.tool:
        return 'Tool';
      case ProductType.other:
        return 'Other';
    }
  }

  String _listingTypeLabel(ListingType type) {
    switch (type) {
      case ListingType.sell:
        return 'Selling';
      case ListingType.buy:
        return 'Buying';
      case ListingType.barter:
        return 'Barter';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Preview'),
        backgroundColor: const Color.fromARGB(255, 163, 182, 164),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${product.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Description: ${product.description}'),
            const SizedBox(height: 8),
            Text('Price: KSh ${product.price.toStringAsFixed(2)}'),
            if (product.location != null) ...[
              const SizedBox(height: 8),
              Text('Location: ${product.location}'),
            ],
            if (product.contactNumber != null && product.contactNumber!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Contact Number: ${product.contactNumber}'),
            ],
            const SizedBox(height: 8),
            Text('Type: ${_productTypeLabel(product.type)}'),
            const SizedBox(height: 8),
            Text('Listing: ${_listingTypeLabel(product.listingType)}'),
            const SizedBox(height: 16),
            const Text('Images:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: product.images?.length ?? 0,
                itemBuilder: (_, index) {
                  final url = product.images![index];
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Image.network(url, width: 200, height: 200, fit: BoxFit.cover),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 143, 173, 145),
                minimumSize: const Size.fromHeight(50),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
