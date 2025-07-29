// ignore_for_file: dead_code

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../models/product.dart';
import '../../services/hive_service.dart';
import 'add_product_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Product product;
  late HiveService hiveService;
  bool isDeleting = false;

  @override
  void initState() {
    super.initState();
    product = widget.product;
    hiveService = HiveService();
  }

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => isDeleting = true);
      await product.delete();
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _editProduct() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddProductScreen(existingProduct: product),
      ),
    );
    // Reload product after editing (in case it was updated)
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = hiveService.getCurrentUser();
    final isSeller = currentUser != null && currentUser.id == product.sellerId;
    final formattedDate = DateFormat.yMMMMd().format(product.createdAt);

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (isSeller) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Product',
              onPressed: _editProduct,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete Product',
              onPressed: isDeleting ? null : _deleteProduct,
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductImage(context),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderRow(context, product),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildChip(
                            _getListingTypeLabel(product.listingType),
                            _getListingTypeColor(product.listingType),
                          ),
                          const SizedBox(width: 8),
                          _buildChip(
                            _getProductTypeLabel(product.type),
                            Colors.blue.shade100,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      if (product.location != null && product.location!.isNotEmpty) ...[
                        const Text(
                          'Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.grey),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                product.location!,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                      const Text(
                        'Listed on',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formattedDate,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isSeller)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildContactSellerButton(context),
            ),
        ],
      ),
    );
  }

  Widget _buildProductImage(BuildContext context) {
    return Hero(
      tag: 'product_image_${product.id}',
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.35,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: product.images != null && product.images!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: product.images!.first,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => Center(
                  child: Icon(
                    _getProductTypeIcon(product.type),
                    size: 80,
                    color: Colors.grey,
                  ),
                ),
              )
            : Center(
                child: Icon(
                  _getProductTypeIcon(product.type),
                  size: 80,
                  color: Colors.grey,
                ),
              ),
      ),
    );
  }

  Widget _buildContactSellerButton(BuildContext context) {
    // You can add real contact logic here
    bool hasContactInfo = true; // TODO: Replace with real check

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: hasContactInfo
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contact functionality coming soon')),
                );
              }
            : null,
        icon: const Icon(Icons.message),
        label: Text(
          product.listingType == ListingType.buy ? 'Contact Buyer' : 'Contact Seller',
          style: const TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: hasContactInfo
              ? Theme.of(context).colorScheme.primary
              : Colors.grey,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context, Product product) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            product.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'KSh ${product.price.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  String _getProductTypeLabel(ProductType type) {
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

  IconData _getProductTypeIcon(ProductType type) {
    switch (type) {
      case ProductType.crop:
        return Icons.grass;
      case ProductType.seed:
        return Icons.grain;
      case ProductType.fertilizer:
        return Icons.science;
      case ProductType.tool:
        return Icons.handyman;
      case ProductType.other:
        return Icons.category;
    }
  }

  String _getListingTypeLabel(ListingType type) {
    switch (type) {
      case ListingType.sell:
        return 'Selling';
      case ListingType.buy:
        return 'Buying';
      case ListingType.barter:
        return 'Barter';
    }
  }

  Color _getListingTypeColor(ListingType type) {
    switch (type) {
      case ListingType.sell:
        return Colors.green.shade100;
      case ListingType.buy:
        return Colors.orange.shade100;
      case ListingType.barter:
        return Colors.purple.shade100;
    }
  }
}
