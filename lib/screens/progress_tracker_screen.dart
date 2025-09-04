import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../services/hybrid_storage_service.dart';

class ProgressTrackerScreen extends StatefulWidget {
  const ProgressTrackerScreen({super.key});

  @override
  State<ProgressTrackerScreen> createState() => _ProgressTrackerScreenState();
}

class _ProgressTrackerScreenState extends State<ProgressTrackerScreen> {
  final HybridStorageService _storageService = HybridStorageService();
  User? _currentUser;
  List<Product> _userProducts = [];
  
  @override
  void initState() {
    super.initState();
    _currentUser = _storageService.getCurrentUser();
    _loadUserProgress();
  }

  void _loadUserProgress() {
    if (_currentUser != null) {
      final allProducts = _storageService.getProductsOffline();
      _userProducts = allProducts.where((p) => p.sellerId == _currentUser!.id).toList();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress'),
        backgroundColor: Colors.green.shade700,
      ),
      body: _currentUser == null
          ? const Center(child: Text('Please log in to view progress'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgressSummary(),
                  const SizedBox(height: 20),
                  if (_currentUser!.role == UserRole.farmer || _currentUser!.role == UserRole.both)
                    _buildFarmingProgress(),
                  if (_currentUser!.role == UserRole.buyer || _currentUser!.role == UserRole.both)
                    _buildBuyingProgress(),
                  const SizedBox(height: 20),
                  _buildProductsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildProgressSummary() {
    final totalProducts = _userProducts.length;
    final availableProducts = _userProducts.where((p) => p.isAvailable).length;
    final soldProducts = totalProducts - availableProducts;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Products Listed',
                    totalProducts.toString(),
                    Icons.inventory,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Available',
                    availableProducts.toString(),
                    Icons.store,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Sold',
                    soldProducts.toString(),
                    Icons.sell,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFarmingProgress() {
    final tasks = _storageService.getAllTasks();
    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final totalTasks = tasks.length;
    final completionRate = totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Farming Progress',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: completionRate,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Tasks Completed: $completedTasks / $totalTasks (${(completionRate * 100).toInt()}%)',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyingProgress() {
    // For buyers, show wishlist and purchase tracking
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buying Activity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.red),
              title: const Text('Wishlist'),
              subtitle: const Text('Save products you want to buy'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Navigate to wishlist
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Wishlist feature coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.blue),
              title: const Text('Purchase History'),
              subtitle: const Text('Track your buying activity'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Navigate to purchase history
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Purchase history coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection() {
    if (_userProducts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.inventory_2, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No products listed yet',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/add_product');
                },
                child: const Text('List Your First Product'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Products',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _userProducts.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final product = _userProducts[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: product.isAvailable ? Colors.green : Colors.grey,
                    child: Icon(
                      product.isAvailable ? Icons.store : Icons.remove_shopping_cart,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(product.name),
                  subtitle: Text('KSh ${product.price.toStringAsFixed(2)}'),
                  trailing: Chip(
                    label: Text(
                      product.isAvailable ? 'Available' : 'Sold',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: product.isAvailable 
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}