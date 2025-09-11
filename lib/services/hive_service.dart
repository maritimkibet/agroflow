import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/crop_task.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/crop_data.dart';

class HiveService {
  // Box names
  static const String taskBoxName = 'crop_tasks';
  static const String userBoxName = 'users';
  static const String productBoxName = 'products';
  static const String cropDataBoxName = 'crop_data';
  static const String settingsBoxName = 'settings';

  // Initialize Hive and register adapters
  Future<void> initializeHive() async {
    try {
      // Register type adapters if not already registered
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(CropTaskAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(UserAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(UserRoleAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(ProductAdapter());
      }
      if (!Hive.isAdapterRegistered(6)) {
        Hive.registerAdapter(CropDataAdapter());
      }

      // Open boxes
      await Hive.openBox<CropTask>(taskBoxName);
      await Hive.openBox<User>(userBoxName);
      await Hive.openBox<Product>(productBoxName);
      await Hive.openBox<CropData>(cropDataBoxName);
      await Hive.openBox(settingsBoxName);
    } catch (e) {
      // If boxes are already open, continue
      debugPrint('Hive initialization warning: $e');
    }
  }

  // Hive boxes
  Box<CropTask> get taskBox => Hive.box<CropTask>(taskBoxName);
  Box<User> get userBox => Hive.box<User>(userBoxName);
  Box<Product> get productBox => Hive.box<Product>(productBoxName);
  Box<CropData> get cropDataBox => Hive.box<CropData>(cropDataBoxName);
  Box get settingsBox => Hive.box(settingsBoxName);

  // ========== Crop Task Methods ==========
  Future<void> addOrUpdateTask(CropTask task) async {
    await taskBox.put(task.id, task);
  }

  Future<void> deleteTask(String id) async {
    await taskBox.delete(id);
  }

  List<CropTask> getAllTasks() {
    return taskBox.values.toList();
  }

  List<CropTask> getTasksSortedByDate() {
    final tasks = getAllTasks();
    tasks.sort((a, b) => a.date.compareTo(b.date));
    return tasks;
  }

  List<CropTask> getTasksForDate(DateTime date) {
    return taskBox.values.where((task) =>
      task.date.year == date.year &&
      task.date.month == date.month &&
      task.date.day == date.day
    ).toList();
  }

  // ========== User Methods ==========
  Future<void> saveUser(User user) async {
    await userBox.put(user.id, user);
  }

  User? getCurrentUser() {
    final currentUserId = settingsBox.get('current_user_id');
    if (currentUserId != null) {
      return userBox.get(currentUserId);
    }
    return null;
  }

  Future<void> setCurrentUser(User user) async {
    await settingsBox.put('current_user_id', user.id);
  }

  Future<User?> getUserByEmail(String email) async {
    final users = userBox.values.toList();
    try {
      return users.firstWhere(
        (user) => user.email?.toLowerCase() == email.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    await settingsBox.delete('current_user_id');
  }

  List<String> getAllCrops() {
    final user = getCurrentUser();
    return user?.crops ?? [];
  }

  // ========== Product Methods ==========
  Future<void> addProduct(Product product) async {
    await productBox.put(product.id, product);
  }

  Future<void> deleteProduct(String id) async {
    await productBox.delete(id);
  }

  List<Product> getAllProducts() {
    return productBox.values.toList();
  }

  Product? getProductById(String productId) {
    return productBox.values.firstWhere(
      (product) => product.id == productId,
      orElse: () => Product.empty(),
    );
  }

  List<Product> getProductsByType(ProductType type) {
    return productBox.values
        .where((product) => product.type == type)
        .toList();
  }

  List<Product> getProductsByListingType(ListingType listingType) {
    return productBox.values
        .where((product) => product.listingType == listingType)
        .toList();
  }

  List<Product> getProductsByLocation(String location) {
    return productBox.values.where((product) =>
      product.location != null &&
      product.location!.toLowerCase().contains(location.toLowerCase())
    ).toList();
  }

  // ========== Crop Data Methods ==========
  Future<void> saveCropData(CropData cropData) async {
    await cropDataBox.put(cropData.id, cropData);
  }

  CropData? getCropDataById(String id) {
    return cropDataBox.get(id);
  }

  List<CropData> getAllCropData() {
    return cropDataBox.values.toList();
  }

  Future<void> initializeCropData() async {
    if (cropDataBox.isEmpty) {
      final predefinedCrops = CropDataRepository.getCropData();
      for (var cropData in predefinedCrops.values) {
        await saveCropData(cropData);
      }
    }
  }

  // ========== Settings Methods ==========
  Future<void> setFirstLaunch(bool value) async {
    await settingsBox.put('first_launch', value);
  }

  bool isFirstLaunch() {
    return settingsBox.get('first_launch', defaultValue: true);
  }

  Future<void> saveTask(CropTask newTask) async {}

  void init() {}

  // ========== Generic Data Methods ==========
  Future<void> saveData(String key, dynamic value) async {
    await settingsBox.put(key, value);
  }

  Future<dynamic> getData(String key) async {
    return settingsBox.get(key);
  }

  Future<void> removeData(String key) async {
    await settingsBox.delete(key);
  }

  // ========== Data Management Methods ==========
  
  /// Clear all user data (for logout or role reset)
  Future<void> clearAllData() async {
    await taskBox.clear();
    await userBox.clear();
    await productBox.clear();
    await settingsBox.clear();
  }

  /// Clear only user-specific data (keep products for marketplace)
  Future<void> clearUserData() async {
    await taskBox.clear();
    await userBox.clear();
    await settingsBox.delete('current_user_id');
  }

  /// Get storage statistics
  Map<String, int> getStorageStats() {
    return {
      'tasks': taskBox.length,
      'users': userBox.length,
      'products': productBox.length,
      'cropData': cropDataBox.length,
      'settings': settingsBox.length,
    };
  }
}
