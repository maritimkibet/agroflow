import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String userId;
  final String category;
  final String subcategory;
  final String description;
  final double amount;
  final String currency;
  final DateTime date;
  final String? cropType;
  final String? season;
  final List<String> imageUrls;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.userId,
    required this.category,
    this.subcategory = '',
    required this.description,
    required this.amount,
    this.currency = 'USD',
    required this.date,
    this.cropType,
    this.season,
    this.imageUrls = const [],
    this.metadata = const {},
    required this.createdAt,
  });

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      userId: data['userId'] ?? '',
      category: data['category'] ?? '',
      subcategory: data['subcategory'] ?? '',
      description: data['description'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'USD',
      date: (data['date'] as Timestamp).toDate(),
      cropType: data['cropType'],
      season: data['season'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      metadata: data['metadata'] ?? {},
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'category': category,
      'subcategory': subcategory,
      'description': description,
      'amount': amount,
      'currency': currency,
      'date': Timestamp.fromDate(date),
      'cropType': cropType,
      'season': season,
      'imageUrls': imageUrls,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Expense copyWith({
    String? id,
    String? userId,
    String? category,
    String? subcategory,
    String? description,
    double? amount,
    String? currency,
    DateTime? date,
    String? cropType,
    String? season,
    List<String>? imageUrls,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      date: date ?? this.date,
      cropType: cropType ?? this.cropType,
      season: season ?? this.season,
      imageUrls: imageUrls ?? this.imageUrls,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class Income {
  final String id;
  final String userId;
  final String source; // 'crop_sale', 'product_sale', 'service', 'other'
  final String description;
  final double amount;
  final String currency;
  final DateTime date;
  final String? cropType;
  final double? quantity;
  final String? unit;
  final String? buyerInfo;
  final List<String> imageUrls;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  Income({
    required this.id,
    required this.userId,
    required this.source,
    required this.description,
    required this.amount,
    this.currency = 'USD',
    required this.date,
    this.cropType,
    this.quantity,
    this.unit,
    this.buyerInfo,
    this.imageUrls = const [],
    this.metadata = const {},
    required this.createdAt,
  });

  factory Income.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Income(
      id: doc.id,
      userId: data['userId'] ?? '',
      source: data['source'] ?? '',
      description: data['description'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'USD',
      date: (data['date'] as Timestamp).toDate(),
      cropType: data['cropType'],
      quantity: data['quantity']?.toDouble(),
      unit: data['unit'],
      buyerInfo: data['buyerInfo'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      metadata: data['metadata'] ?? {},
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'source': source,
      'description': description,
      'amount': amount,
      'currency': currency,
      'date': Timestamp.fromDate(date),
      'cropType': cropType,
      'quantity': quantity,
      'unit': unit,
      'buyerInfo': buyerInfo,
      'imageUrls': imageUrls,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class FinancialSummary {
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final double profitMargin;
  final Map<String, double> expensesByCategory;
  final Map<String, double> incomeBySource;
  final Map<String, double> profitByCrop;
  final DateTime periodStart;
  final DateTime periodEnd;

  FinancialSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netProfit,
    required this.profitMargin,
    required this.expensesByCategory,
    required this.incomeBySource,
    required this.profitByCrop,
    required this.periodStart,
    required this.periodEnd,
  });

  factory FinancialSummary.empty(DateTime start, DateTime end) {
    return FinancialSummary(
      totalIncome: 0,
      totalExpenses: 0,
      netProfit: 0,
      profitMargin: 0,
      expensesByCategory: {},
      incomeBySource: {},
      profitByCrop: {},
      periodStart: start,
      periodEnd: end,
    );
  }
}

// Predefined expense categories
class ExpenseCategories {
  static const Map<String, List<String>> categories = {
    'Seeds & Planting': [
      'Seeds',
      'Seedlings',
      'Planting Materials',
      'Grafting Materials',
    ],
    'Fertilizers & Nutrients': [
      'Organic Fertilizer',
      'Chemical Fertilizer',
      'Compost',
      'Micronutrients',
    ],
    'Pesticides & Protection': [
      'Insecticides',
      'Fungicides',
      'Herbicides',
      'Organic Pesticides',
    ],
    'Equipment & Tools': [
      'Hand Tools',
      'Machinery',
      'Irrigation Equipment',
      'Storage Equipment',
    ],
    'Labor': [
      'Planting Labor',
      'Harvesting Labor',
      'Maintenance Labor',
      'Skilled Labor',
    ],
    'Utilities': [
      'Water',
      'Electricity',
      'Fuel',
      'Internet/Phone',
    ],
    'Transportation': [
      'Fuel Costs',
      'Vehicle Maintenance',
      'Delivery Costs',
      'Market Transport',
    ],
    'Marketing & Sales': [
      'Packaging',
      'Advertising',
      'Market Fees',
      'Commission',
    ],
    'Other': [
      'Insurance',
      'Taxes',
      'Miscellaneous',
      'Emergency Repairs',
    ],
  };

  static List<String> getAllCategories() {
    return categories.keys.toList();
  }

  static List<String> getSubcategories(String category) {
    return categories[category] ?? [];
  }
}

// Predefined income sources
class IncomeSources {
  static const List<String> sources = [
    'Crop Sale',
    'Product Sale',
    'Equipment Rental',
    'Consulting Service',
    'Government Subsidy',
    'Insurance Payout',
    'Other Income',
  ];
}