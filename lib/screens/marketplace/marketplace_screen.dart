import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/product.dart';
import 'product_detail_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  ProductType? _selectedProductType;
  String? _selectedRegion;
  ListingType? _selectedListingType;
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  List<Product> _productsFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Product.fromMap(data, id: doc.id);
    }).toList();
  }

  List<String> _getUniqueRegions(List<Product> products) {
    final regions = products
        .where((p) => p.location != null && p.location!.isNotEmpty)
        .map((p) => p.location!)
        .toSet()
        .toList();
    regions.sort();
    return regions;
  }

  List<Product> _filterProducts(List<Product> products) {
    return products.where((product) {
      if (_selectedProductType != null && product.type != _selectedProductType) return false;
      if (_selectedListingType != null && product.listingType != _selectedListingType) return false;
      if (_selectedRegion != null &&
          (product.location == null ||
              !product.location!.toLowerCase().contains(_selectedRegion!.toLowerCase()))) {
        return false;
      }
      if (_searchQuery.isNotEmpty &&
          !product.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return product.isAvailable;
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      _selectedProductType = null;
      _selectedListingType = null;
      _selectedRegion = null;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('AgroFlow Marketplace'),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        actions: [
          if (_selectedProductType != null ||
              _selectedListingType != null ||
              _selectedRegion != null ||
              _searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear all filters',
              onPressed: _clearFilters,
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading products: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allProducts = _productsFromSnapshot(snapshot.data!);
          final regions = _getUniqueRegions(allProducts);
          final filteredProducts = _filterProducts(allProducts);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search products',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value.trim()),
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      DropdownButton<ProductType>(
                        value: _selectedProductType,
                        hint: const Text('Filter by Type'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Types')),
                          ...ProductType.values.map(
                            (e) => DropdownMenuItem(value: e, child: Text(_productTypeLabel(e))),
                          ),
                        ],
                        onChanged: (v) => setState(() => _selectedProductType = v),
                      ),
                      DropdownButton<ListingType>(
                        value: _selectedListingType,
                        hint: const Text('Filter by Listing'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Listings')),
                          ...ListingType.values.map(
                            (e) => DropdownMenuItem(value: e, child: Text(_listingTypeLabel(e))),
                          ),
                        ],
                        onChanged: (v) => setState(() => _selectedListingType = v),
                      ),
                      DropdownButton<String>(
                        value: _selectedRegion,
                        hint: const Text('Filter by Region'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Regions')),
                          ...regions.map((r) => DropdownMenuItem(value: r, child: Text(r))),
                        ],
                        onChanged: (v) => setState(() => _selectedRegion = v),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: filteredProducts.isEmpty
                    ? const Center(
                        child: Text(
                          'No products found.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          // Firestore streams update automatically, but you can force rebuild:
                          setState(() {});
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredProducts.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return ListTile(
                              leading: product.images != null && product.images!.isNotEmpty
                                  ? SizedBox(
                                      width: 50,
                                      height: 50,
                                      child: CachedNetworkImage(
                                        imageUrl: product.images!.first,
                                        placeholder: (context, url) =>
                                            const CircularProgressIndicator(strokeWidth: 2),
                                        errorWidget: (context, url, error) =>
                                            const Icon(Icons.error),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(Icons.shopping_bag, size: 50, color: Colors.grey),
                              title: Text(product.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                '${product.description}\nKSh ${product.price.toStringAsFixed(0)}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(_listingTypeLabel(product.listingType)),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(product: product),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
