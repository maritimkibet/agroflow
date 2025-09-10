import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../models/product.dart';
import '../../services/hive_service.dart';
import '../../services/hybrid_storage_service.dart';
import '../../services/marketplace_service.dart';
import '../messaging/chat_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Product product;
  late HiveService hiveService;
  bool isDeleting = false;
  bool _isSellerOnline = false;

  @override
  void initState() {
    super.initState();
    product = widget.product;
    hiveService = HiveService();
    _checkSellerStatus();
  }

  Future<void> _checkSellerStatus() async {
    // Simulate seller status check - replace with actual implementation
    _isSellerOnline = true;
    if (mounted) setState(() {});
  }

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Delete Product'),
            content: const Text(
              'Are you sure you want to delete this product?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
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
    final result = await Navigator.pushNamed(
      context,
      '/add-product',
      arguments: product,
    );
    if (mounted && result != null) setState(() {});
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
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
                  _buildSellerInfo(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildChip('For Sale', Colors.green.shade100),
                      const SizedBox(width: 8),
                      _buildChip(product.category, Colors.blue.shade100),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  if (product.location != null &&
                      product.location!.isNotEmpty) ...[
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
                    'Quantity Available',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${product.quantity} ${product.unit}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Listed on',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(formattedDate, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildContactButtons(),
    );
  }

  Widget _buildSellerInfo() {
    final storageService = HybridStorageService();
    final seller = storageService.getUserById(product.sellerId);

    if (seller == null) return const SizedBox.shrink();

    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: const Icon(Icons.person, color: Colors.black54),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              seller.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              _isSellerOnline ? "Online" : "Offline",
              style: TextStyle(
                color: _isSellerOnline ? Colors.green : Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactButtons() {
    final currentUser = hiveService.getCurrentUser();
    final isSeller = currentUser != null && currentUser.id == product.sellerId;

    if (isSeller) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _startChat,
              icon: const Icon(Icons.message),
              label: Text(
                _isSellerOnline ? 'Message Seller' : 'Message (Offline)',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _contactSeller,
              icon: const Icon(Icons.phone),
              label: const Text('Call'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green.shade700,
                side: BorderSide(color: Colors.green.shade700),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startChat() async {
    final currentUser = hiveService.getCurrentUser();
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to start a conversation'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final storageService = HybridStorageService();
    final seller = storageService.getUserById(product.sellerId);
    if (seller == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seller information not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(product: product, otherUser: seller),
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildProductImage(BuildContext context) {
    if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.35,
        width: double.infinity,
        child: CachedNetworkImage(
          imageUrl: product.imageUrl!,
          fit: BoxFit.cover,
          placeholder:
              (context, url) =>
                  const Center(child: CircularProgressIndicator()),
          errorWidget:
              (context, url, error) => Container(
                color: Colors.grey.shade200,
                child: Center(
                  child: Icon(
                    _getProductTypeIcon(product.category),
                    size: 80,
                    color: Colors.grey,
                  ),
                ),
              ),
        ),
      );
    } else {
      return Container(
        height: MediaQuery.of(context).size.height * 0.35,
        width: double.infinity,
        color: Colors.grey.shade200,
        child: Center(
          child: Icon(
            _getProductTypeIcon(product.category),
            size: 80,
            color: Colors.grey,
          ),
        ),
      );
    }
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
      children: [
        Expanded(
          child: Text(
            product.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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

  IconData _getProductTypeIcon(String category) {
    switch (category.toLowerCase()) {
      case 'vegetables':
        return Icons.eco;
      case 'fruits':
        return Icons.apple;
      case 'grains':
        return Icons.grain;
      case 'seeds':
        return Icons.grass;
      case 'fertilizers':
        return Icons.science;
      case 'tools':
        return Icons.handyman;
      default:
        return Icons.shopping_bag;
    }
  }

  Future<void> _contactSeller() async {
    final success = await MarketplaceService().contactSeller(
      product.id,
      'Hi, I\'m interested in your ${product.name}. Is it still available?',
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message sent to seller successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
