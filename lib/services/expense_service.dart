import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense.dart';

class ExpenseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add expense
  static Future<String> addExpense({
    required String category,
    String subcategory = '',
    required String description,
    required double amount,
    String currency = 'USD',
    required DateTime date,
    String? cropType,
    String? season,
    List<File> images = const [],
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Upload images
      List<String> imageUrls = [];
      for (int i = 0; i < images.length; i++) {
        final ref = _storage.ref().child('expenses/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
        await ref.putFile(images[i]);
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }

      final expense = Expense(
        id: '',
        userId: user.uid,
        category: category,
        subcategory: subcategory,
        description: description,
        amount: amount,
        currency: currency,
        date: date,
        cropType: cropType,
        season: season,
        imageUrls: imageUrls,
        metadata: metadata,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('expenses').add(expense.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add expense: $e');
    }
  }

  // Add income
  static Future<String> addIncome({
    required String source,
    required String description,
    required double amount,
    String currency = 'USD',
    required DateTime date,
    String? cropType,
    double? quantity,
    String? unit,
    String? buyerInfo,
    List<File> images = const [],
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Upload images
      List<String> imageUrls = [];
      for (int i = 0; i < images.length; i++) {
        final ref = _storage.ref().child('income/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
        await ref.putFile(images[i]);
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }

      final income = Income(
        id: '',
        userId: user.uid,
        source: source,
        description: description,
        amount: amount,
        currency: currency,
        date: date,
        cropType: cropType,
        quantity: quantity,
        unit: unit,
        buyerInfo: buyerInfo,
        imageUrls: imageUrls,
        metadata: metadata,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('income').add(income.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add income: $e');
    }
  }

  // Get expenses for a period
  static Stream<List<Expense>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? cropType,
  }) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    Query query = _firestore.collection('expenses')
        .where('userId', isEqualTo: user.uid);

    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    if (cropType != null && cropType.isNotEmpty) {
      query = query.where('cropType', isEqualTo: cropType);
    }

    query = query.orderBy('date', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList();
    });
  }

  // Get income for a period
  static Stream<List<Income>> getIncome({
    DateTime? startDate,
    DateTime? endDate,
    String? source,
    String? cropType,
  }) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    Query query = _firestore.collection('income')
        .where('userId', isEqualTo: user.uid);

    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }
    if (source != null && source.isNotEmpty) {
      query = query.where('source', isEqualTo: source);
    }
    if (cropType != null && cropType.isNotEmpty) {
      query = query.where('cropType', isEqualTo: cropType);
    }

    query = query.orderBy('date', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Income.fromFirestore(doc)).toList();
    });
  }

  // Get financial summary for a period
  static Future<FinancialSummary> getFinancialSummary({
    required DateTime startDate,
    required DateTime endDate,
    String? cropType,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get expenses
      Query expenseQuery = _firestore.collection('expenses')
          .where('userId', isEqualTo: user.uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));

      if (cropType != null && cropType.isNotEmpty) {
        expenseQuery = expenseQuery.where('cropType', isEqualTo: cropType);
      }

      final expenseSnapshot = await expenseQuery.get();
      final expenses = expenseSnapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList();

      // Get income
      Query incomeQuery = _firestore.collection('income')
          .where('userId', isEqualTo: user.uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));

      if (cropType != null && cropType.isNotEmpty) {
        incomeQuery = incomeQuery.where('cropType', isEqualTo: cropType);
      }

      final incomeSnapshot = await incomeQuery.get();
      final income = incomeSnapshot.docs.map((doc) => Income.fromFirestore(doc)).toList();

      // Calculate totals
      final totalExpenses = expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
      final totalIncome = income.fold<double>(0, (sum, inc) => sum + inc.amount);
      final netProfit = totalIncome - totalExpenses;
      final profitMargin = totalIncome > 0 ? (netProfit / totalIncome) * 100 : 0.0;

      // Group expenses by category
      final Map<String, double> expensesByCategory = {};
      for (final expense in expenses) {
        expensesByCategory[expense.category] = 
            (expensesByCategory[expense.category] ?? 0) + expense.amount;
      }

      // Group income by source
      final Map<String, double> incomeBySource = {};
      for (final inc in income) {
        incomeBySource[inc.source] = 
            (incomeBySource[inc.source] ?? 0) + inc.amount;
      }

      // Calculate profit by crop
      final Map<String, double> profitByCrop = {};
      final Map<String, double> expensesByCrop = {};
      final Map<String, double> incomeByCrop = {};

      for (final expense in expenses) {
        if (expense.cropType != null && expense.cropType!.isNotEmpty) {
          expensesByCrop[expense.cropType!] = 
              (expensesByCrop[expense.cropType!] ?? 0) + expense.amount;
        }
      }

      for (final inc in income) {
        if (inc.cropType != null && inc.cropType!.isNotEmpty) {
          incomeByCrop[inc.cropType!] = 
              (incomeByCrop[inc.cropType!] ?? 0) + inc.amount;
        }
      }

      final allCrops = {...expensesByCrop.keys, ...incomeByCrop.keys};
      for (final crop in allCrops) {
        final cropIncome = incomeByCrop[crop] ?? 0;
        final cropExpenses = expensesByCrop[crop] ?? 0;
        profitByCrop[crop] = cropIncome - cropExpenses;
      }

      return FinancialSummary(
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        netProfit: netProfit,
        profitMargin: profitMargin,
        expensesByCategory: expensesByCategory,
        incomeBySource: incomeBySource,
        profitByCrop: profitByCrop,
        periodStart: startDate,
        periodEnd: endDate,
      );
    } catch (e) {
      throw Exception('Failed to get financial summary: $e');
    }
  }

  // Get monthly financial data for charts
  static Future<List<Map<String, dynamic>>> getMonthlyFinancialData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final List<Map<String, dynamic>> monthlyData = [];
      
      DateTime current = DateTime(startDate.year, startDate.month, 1);
      final end = DateTime(endDate.year, endDate.month, 1);

      while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
        final monthStart = current;
        final monthEnd = DateTime(current.year, current.month + 1, 0, 23, 59, 59);

        final summary = await getFinancialSummary(
          startDate: monthStart,
          endDate: monthEnd,
        );

        monthlyData.add({
          'month': '${current.year}-${current.month.toString().padLeft(2, '0')}',
          'income': summary.totalIncome,
          'expenses': summary.totalExpenses,
          'profit': summary.netProfit,
        });

        current = DateTime(current.year, current.month + 1, 1);
      }

      return monthlyData;
    } catch (e) {
      throw Exception('Failed to get monthly data: $e');
    }
  }

  // Update expense
  static Future<void> updateExpense(String expenseId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('expenses').doc(expenseId).update(updates);
    } catch (e) {
      throw Exception('Failed to update expense: $e');
    }
  }

  // Update income
  static Future<void> updateIncome(String incomeId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('income').doc(incomeId).update(updates);
    } catch (e) {
      throw Exception('Failed to update income: $e');
    }
  }

  // Delete expense
  static Future<void> deleteExpense(String expenseId) async {
    try {
      await _firestore.collection('expenses').doc(expenseId).delete();
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    }
  }

  // Delete income
  static Future<void> deleteIncome(String incomeId) async {
    try {
      await _firestore.collection('income').doc(incomeId).delete();
    } catch (e) {
      throw Exception('Failed to delete income: $e');
    }
  }

  // Get expense categories with usage count
  static Future<Map<String, int>> getExpenseCategoriesUsage() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final snapshot = await _firestore.collection('expenses')
          .where('userId', isEqualTo: user.uid)
          .get();

      final Map<String, int> usage = {};
      for (final doc in snapshot.docs) {
        final category = doc.data()['category'] as String?;
        if (category != null && category.isNotEmpty) {
          usage[category] = (usage[category] ?? 0) + 1;
        }
      }

      return usage;
    } catch (e) {
      return {};
    }
  }

  // Get crop types with financial data
  static Future<List<String>> getCropTypesWithFinancialData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final expenseSnapshot = await _firestore.collection('expenses')
          .where('userId', isEqualTo: user.uid)
          .where('cropType', isNotEqualTo: null)
          .get();

      final incomeSnapshot = await _firestore.collection('income')
          .where('userId', isEqualTo: user.uid)
          .where('cropType', isNotEqualTo: null)
          .get();

      final Set<String> cropTypes = {};

      for (final doc in expenseSnapshot.docs) {
        final cropType = doc.data()['cropType'] as String?;
        if (cropType != null && cropType.isNotEmpty) {
          cropTypes.add(cropType);
        }
      }

      for (final doc in incomeSnapshot.docs) {
        final cropType = doc.data()['cropType'] as String?;
        if (cropType != null && cropType.isNotEmpty) {
          cropTypes.add(cropType);
        }
      }

      final list = cropTypes.toList();
      list.sort();
      return list;
    } catch (e) {
      return [];
    }
  }

  // Export financial data to CSV format
  static Future<String> exportFinancialData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final expensesStream = getExpenses(
        startDate: startDate,
        endDate: endDate,
      );
      final expenses = await expensesStream.first;

      final incomeStream = getIncome(
        startDate: startDate,
        endDate: endDate,
      );
      final income = await incomeStream.first;

      final StringBuffer csv = StringBuffer();
      
      // Header
      csv.writeln('Type,Date,Category,Description,Amount,Currency,Crop Type');
      
      // Expenses
      for (final expense in expenses) {
        csv.writeln(
          'Expense,${expense.date.toIso8601String().split('T')[0]},'
          '${expense.category},"${expense.description}",${expense.amount},'
          '${expense.currency},${expense.cropType ?? ""}'
        );
      }
      
      // Income
      for (final inc in income) {
        csv.writeln(
          'Income,${inc.date.toIso8601String().split('T')[0]},'
          '${inc.source},"${inc.description}",${inc.amount},'
          '${inc.currency},${inc.cropType ?? ""}'
        );
      }

      return csv.toString();
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  // Get price insights for crops
  static Future<Map<String, dynamic>> getCropPriceInsights(String cropType) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      // Get user's sales for this crop in the last 12 months
      final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
      
      final userSales = await _firestore.collection('income')
          .where('userId', isEqualTo: user.uid)
          .where('cropType', isEqualTo: cropType)
          .where('date', isGreaterThan: Timestamp.fromDate(oneYearAgo))
          .get();

      // Get regional sales data (anonymized)
      final regionalSales = await _firestore.collection('income')
          .where('cropType', isEqualTo: cropType)
          .where('date', isGreaterThan: Timestamp.fromDate(oneYearAgo))
          .limit(100)
          .get();

      final userPrices = <double>[];
      final regionalPrices = <double>[];

      for (final doc in userSales.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0.0).toDouble();
        final quantity = (data['quantity'] ?? 1.0).toDouble();
        if (quantity > 0) {
          userPrices.add(amount / quantity);
        }
      }

      for (final doc in regionalSales.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0.0).toDouble();
        final quantity = (data['quantity'] ?? 1.0).toDouble();
        if (quantity > 0) {
          regionalPrices.add(amount / quantity);
        }
      }

      double userAvgPrice = 0;
      double regionalAvgPrice = 0;

      if (userPrices.isNotEmpty) {
        userAvgPrice = userPrices.reduce((a, b) => a + b) / userPrices.length;
      }

      if (regionalPrices.isNotEmpty) {
        regionalAvgPrice = regionalPrices.reduce((a, b) => a + b) / regionalPrices.length;
      }

      return {
        'userAveragePrice': userAvgPrice,
        'regionalAveragePrice': regionalAvgPrice,
        'priceComparison': regionalAvgPrice > 0 
            ? ((userAvgPrice - regionalAvgPrice) / regionalAvgPrice) * 100 
            : 0,
        'totalSales': userSales.docs.length,
        'regionalSamples': regionalSales.docs.length,
      };
    } catch (e) {
      return {};
    }
  }
}