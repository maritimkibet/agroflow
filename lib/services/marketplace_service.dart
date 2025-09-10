import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import 'hive_service.dart';

class MarketplaceService {
  static final MarketplaceService _instance = MarketplaceService._internal();
  factory MarketplaceService() => _instance;
  MarketplaceService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mock products for presentation
  static List<Product> _getMockProducts() {
    final now = DateTime.now();
    return [
      Product(
        id: '1',
        name: 'Fresh Organic Tomatoes',
        description: 'Premium quality organic tomatoes, freshly harvested. Perfect for cooking and salads. Grown without pesticides.',
        price: 250.0,
        type: ProductType.crop,
        listingType: ListingType.sell,
        category: 'Vegetables',
        sellerId: 'farmer_1',
        sellerName: 'John Smith',
        tags: ['organic', 'tomatoes', 'vegetables'],
        imageUrl: 'https://images.unsplash.com/photo-1546470427-e5b89b618b84?w=400',
        isAvailable: true,
        quantity: 50,
        unit: 'kg',
        location: 'Nairobi, Kenya',
        harvestDate: now.subtract(const Duration(days: 2)),
        expiryDate: now.add(const Duration(days: 7)),
        isOrganic: true,
        certifications: ['Organic Certified'],
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now.subtract(const Duration(hours: 6)),
      ),
      Product(
        id: '2',
        type: ProductType.crop,
        listingType: ListingType.sell,
        name: 'Sweet Yellow Corn',
        description: 'Fresh sweet corn, perfect for grilling or boiling. Locally grown and harvested this morning.',
        price: 150.0,
        category: 'Vegetables',
        sellerId: 'farmer_2',
        tags: [],
        sellerName: 'Maria Rodriguez',
        imageUrl: 'https://images.unsplash.com/photo-1551754655-cd27e38d2076?w=400',
        isAvailable: true,
        quantity: 100,
        unit: 'pieces',
        location: 'Eldoret, Kenya',
        harvestDate: now.subtract(const Duration(hours: 12)),
        expiryDate: now.add(const Duration(days: 5)),
        isOrganic: false,
        certifications: [],
        createdAt: now.subtract(const Duration(hours: 12)),
        updatedAt: now.subtract(const Duration(hours: 12)),
      ),
      Product(
        id: '3',
        type: ProductType.crop,
        listingType: ListingType.sell,
        name: 'Premium Avocados',
        description: 'Large, creamy avocados ready to eat. Rich in healthy fats and perfect for export quality.',
        price: 80.0,
        category: 'Fruits',
        sellerId: 'farmer_3',
        tags: [],
        sellerName: 'David Kimani',
        imageUrl: 'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=400',
        isAvailable: true,
        quantity: 200,
        unit: 'pieces',
        location: 'Murang\'a, Kenya',
        harvestDate: now.subtract(const Duration(days: 1)),
        expiryDate: now.add(const Duration(days: 10)),
        isOrganic: true,
        certifications: ['Export Quality', 'Organic'],
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      Product(
        id: '4',
        type: ProductType.crop,
        listingType: ListingType.sell,
        name: 'Fresh Spinach Leaves',
        description: 'Tender, fresh spinach leaves. Rich in iron and vitamins. Perfect for salads and cooking.',
        price: 120.0,
        category: 'Vegetables',
        sellerId: 'farmer_4',
        tags: [],
        sellerName: 'Grace Wanjiku',
        imageUrl: 'https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=400',
        isAvailable: true,
        quantity: 30,
        unit: 'bunches',
        location: 'Kiambu, Kenya',
        harvestDate: now.subtract(const Duration(hours: 8)),
        expiryDate: now.add(const Duration(days: 3)),
        isOrganic: true,
        certifications: ['Organic Certified'],
        createdAt: now.subtract(const Duration(hours: 8)),
        updatedAt: now.subtract(const Duration(hours: 8)),
      ),
      Product(
        id: '5',
        type: ProductType.crop,
        listingType: ListingType.sell,
        name: 'Red Bell Peppers',
        description: 'Crisp, sweet red bell peppers. Great for cooking, salads, and stuffing. Greenhouse grown.',
        price: 300.0,
        category: 'Vegetables',
        sellerId: 'farmer_5',
        tags: [],
        sellerName: 'Peter Mwangi',
        imageUrl: 'https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?w=400',
        isAvailable: true,
        quantity: 25,
        unit: 'kg',
        location: 'Nakuru, Kenya',
        harvestDate: now.subtract(const Duration(days: 1)),
        expiryDate: now.add(const Duration(days: 8)),
        isOrganic: false,
        certifications: ['Greenhouse Grown'],
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      Product(
        id: '6',
        type: ProductType.crop,
        listingType: ListingType.sell,
        name: 'Organic Carrots',
        description: 'Sweet, crunchy organic carrots. Perfect for cooking, juicing, or eating raw. Rich in beta-carotene.',
        price: 180.0,
        category: 'Vegetables',
        sellerId: 'farmer_6',
        tags: [],
        sellerName: 'Anne Njeri',
        imageUrl: 'https://images.unsplash.com/photo-1445282768818-728615cc910a?w=400',
        isAvailable: true,
        quantity: 40,
        unit: 'kg',
        location: 'Meru, Kenya',
        harvestDate: now.subtract(const Duration(days: 3)),
        expiryDate: now.add(const Duration(days: 14)),
        isOrganic: true,
        certifications: ['Organic Certified'],
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      Product(
        id: '7',
        type: ProductType.crop,
        listingType: ListingType.sell,
        name: 'Fresh Bananas',
        description: 'Sweet, ripe bananas perfect for eating fresh or cooking. Locally grown and naturally ripened.',
        price: 60.0,
        category: 'Fruits',
        sellerId: 'farmer_7',
        tags: [],
        sellerName: 'Samuel Ochieng',
        imageUrl: 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=400',
        isAvailable: true,
        quantity: 150,
        unit: 'bunches',
        location: 'Kisumu, Kenya',
        harvestDate: now.subtract(const Duration(days: 2)),
        expiryDate: now.add(const Duration(days: 6)),
        isOrganic: false,
        certifications: [],
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      Product(
        id: '8',
        type: ProductType.crop,
        listingType: ListingType.sell,
        name: 'Quality Wheat Seeds',
        description: 'High-yield wheat seeds suitable for various soil types. Drought-resistant variety with excellent germination rate.',
        price: 450.0,
        category: 'Seeds',
        sellerId: 'supplier_1',
        tags: [],
        sellerName: 'AgroSeeds Ltd',
        imageUrl: 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=400',
        isAvailable: true,
        quantity: 500,
        unit: 'kg',
        location: 'Nairobi, Kenya',
        harvestDate: null,
        expiryDate: now.add(const Duration(days: 365)),
        isOrganic: false,
        certifications: ['Certified Seeds'],
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      Product(
        id: '9',
        type: ProductType.crop,
        listingType: ListingType.sell,
        name: 'Organic Fertilizer',
        description: 'Premium organic fertilizer made from composted materials. Improves soil health and crop yield naturally.',
        price: 800.0,
        category: 'Fertilizers',
        sellerId: 'supplier_2',
        tags: [],
        sellerName: 'Green Earth Supplies',
        imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=400',
        isAvailable: true,
        quantity: 100,
        unit: '50kg bags',
        location: 'Thika, Kenya',
        harvestDate: null,
        expiryDate: now.add(const Duration(days: 730)),
        isOrganic: true,
        certifications: ['Organic Certified'],
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      Product(
        id: '10',
        type: ProductType.crop,
        listingType: ListingType.sell,
        name: 'Farm Hand Tools Set',
        description: 'Complete set of essential farm hand tools including hoes, spades, and pruning shears. Durable and long-lasting.',
        price: 2500.0,
        category: 'Tools',
        sellerId: 'supplier_3',
        tags: [],
        sellerName: 'Farm Tools Kenya',
        imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=400',
        isAvailable: true,
        quantity: 20,
        unit: 'sets',
        location: 'Nairobi, Kenya',
        harvestDate: null,
        expiryDate: null,
        isOrganic: false,
        certifications: ['Quality Assured'],
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 7)),
      ),
    ];
  }

  // Stream of products for the marketplace
  Stream<List<Product>> getProducts() {
    return Stream.periodic(const Duration(seconds: 1), (index) {
      return _getAllProducts();
    }).asyncMap((products) async => products);
  }

  // Get all products from both Firestore and local storage
  List<Product> _getAllProducts() {
    final List<Product> allProducts = [];
    
    // Add mock products for demo
    allProducts.addAll(_getMockProducts());
    
    // Add locally stored products
    try {
      final hiveService = HiveService();
      final localProducts = hiveService.getAllProducts();
      allProducts.addAll(localProducts);
    } catch (e) {
      debugPrint('Error getting local products: $e');
    }
    
    // Sort by creation date (newest first)
    allProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return allProducts.where((product) => product.isAvailable).toList();
  }

  // Get product by ID
  Product? getProductById(String id) {
    try {
      return _getMockProducts().firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  // Search products
  List<Product> searchProducts(String query) {
    final products = _getMockProducts();
    if (query.isEmpty) return products;
    
    return products.where((product) {
      return product.name.toLowerCase().contains(query.toLowerCase()) ||
             product.description.toLowerCase().contains(query.toLowerCase()) ||
             product.category.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Filter products by category
  List<Product> getProductsByCategory(String category) {
    return _getMockProducts().where((product) => 
        product.category.toLowerCase() == category.toLowerCase()).toList();
  }

  // Get products by seller
  List<Product> getProductsBySeller(String sellerId) {
    return _getMockProducts().where((product) => 
        product.sellerId == sellerId).toList();
  }

  // Get available categories
  List<String> getCategories() {
    final products = _getMockProducts();
    return products.map((product) => product.category).toSet().toList()..sort();
  }

  // Get available locations
  List<String> getLocations() {
    final products = _getMockProducts();
    return products.map((product) => product.location ?? '').where((location) => 
        location.isNotEmpty).toSet().toList()..sort();
  }

  // Contact seller (mock implementation)
  Future<bool> contactSeller(String productId, String message) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    return true; // Always successful for demo
  }

  // Add to favorites (mock implementation)
  Future<bool> addToFavorites(String productId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  // Remove from favorites (mock implementation)
  Future<bool> removeFromFavorites(String productId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  // Check if product is in favorites (mock implementation)
  bool isInFavorites(String productId) {
    // For demo, return true for some products
    return ['1', '3', '5'].contains(productId);
  }
}