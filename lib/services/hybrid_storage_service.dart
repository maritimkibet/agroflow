import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/crop_task.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../services/hive_service.dart';
import '../services/firestore_service.dart';

class HybridStorageService {
  final HiveService _hiveService = HiveService();
  final FirestoreService _firestoreService = FirestoreService();
  final Connectivity _connectivity = Connectivity();

  // ========== MARKETPLACE (Firebase Primary) ==========
  
  /// Add/Update product - Always goes to Firebase, cached locally
  Future<void> addOrUpdateProduct(Product product) async {
    try {
      // Always save to Firebase first for marketplace visibility
      await _firestoreService.addOrUpdateProduct(product);
      
      // Cache locally for offline viewing
      await _hiveService.addProduct(product);
    } catch (e) {
      // If Firebase fails, save locally and mark for sync
      await _hiveService.addProduct(product);
      await _markForSync('product_${product.id}', 'create_update');
      rethrow;
    }
  }

  /// Get products stream - Firebase with local fallback
  Stream<List<Product>> getProductsStream() {
    return _firestoreService.getProductsStream().handleError((error) {
      // On error, return cached products
      return _hiveService.getAllProducts();
    });
  }

  /// Get products offline - From local cache
  List<Product> getProductsOffline() {
    return _hiveService.getAllProducts();
  }

  /// Delete product - Firebase and local
  Future<void> deleteProduct(String id) async {
    try {
      await _firestoreService.deleteProduct(id);
      await _hiveService.deleteProduct(id);
    } catch (e) {
      // Mark for deletion sync if Firebase fails
      await _hiveService.deleteProduct(id);
      await _markForSync('product_$id', 'delete');
      rethrow;
    }
  }

  // ========== PERSONAL DATA (Hive Primary) ==========

  /// Add/Update task - Hive first, sync to Firebase when online
  Future<void> addOrUpdateTask(CropTask task) async {
    // Always save locally first for offline functionality
    await _hiveService.addOrUpdateTask(task);
    
    // Try to sync to Firebase if online
    if (await _isOnline()) {
      try {
        await _firestoreService.addOrUpdateTask(task);
      } catch (e) {
        // Mark for sync later if Firebase fails
        await _markForSync('task_${task.id}', 'create_update');
      }
    } else {
      // Mark for sync when online
      await _markForSync('task_${task.id}', 'create_update');
    }
  }

  /// Get tasks - Always from local Hive
  List<CropTask> getAllTasks() {
    return _hiveService.getAllTasks();
  }

  /// Get tasks for date - Always from local Hive
  List<CropTask> getTasksForDate(DateTime date) {
    return _hiveService.getTasksForDate(date);
  }

  /// Delete task - Local first, sync to Firebase
  Future<void> deleteTask(String id) async {
    await _hiveService.deleteTask(id);
    
    if (await _isOnline()) {
      try {
        await _firestoreService.deleteTask(id);
      } catch (e) {
        await _markForSync('task_$id', 'delete');
      }
    } else {
      await _markForSync('task_$id', 'delete');
    }
  }

  // ========== USER PROFILE (Hybrid) ==========

  /// Save user profile - Both local and Firebase
  Future<void> saveUserProfile(User user) async {
    // Save locally first
    await _hiveService.saveUser(user);
    
    // Try to sync to Firebase
    if (await _isOnline()) {
      try {
        await _firestoreService.saveUserProfile(user);
      } catch (e) {
        await _markForSync('user_${user.id}', 'create_update');
      }
    } else {
      await _markForSync('user_${user.id}', 'create_update');
    }
  }

  /// Get current user - Always from local
  User? getCurrentUser() {
    return _hiveService.getCurrentUser();
  }

  // ========== SYNC MANAGEMENT ==========

  /// Check if device is online
  Future<bool> _isOnline() async {
    final connectivityResults = await _connectivity.checkConnectivity();
    return !connectivityResults.contains(ConnectivityResult.none);
  }

  /// Mark item for sync when online
  Future<void> _markForSync(String itemId, String operation) async {
    final syncBox = await Hive.openBox('sync_queue');
    await syncBox.put(itemId, {
      'operation': operation,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Sync pending items to Firebase
  Future<void> syncPendingItems() async {
    if (!await _isOnline()) return;

    try {
      final syncBox = await Hive.openBox('sync_queue');
      final pendingItems = syncBox.toMap();

      for (final entry in pendingItems.entries) {
        final itemId = entry.key as String;
        final syncData = entry.value as Map;
        final operation = syncData['operation'] as String;

        try {
          if (itemId.startsWith('task_')) {
            await _syncTask(itemId.substring(5), operation);
          } else if (itemId.startsWith('product_')) {
            await _syncProduct(itemId.substring(8), operation);
          } else if (itemId.startsWith('user_')) {
            await _syncUser(itemId.substring(5), operation);
          }

          // Remove from sync queue after successful sync
          await syncBox.delete(itemId);
        } catch (e) {
          // Keep in queue for next sync attempt
          continue;
        }
      }
    } catch (e) {
      // Sync will be retried later
    }
  }

  Future<void> _syncTask(String taskId, String operation) async {
    if (operation == 'delete') {
      await _firestoreService.deleteTask(taskId);
    } else {
      final task = _hiveService.taskBox.get(taskId);
      if (task != null) {
        await _firestoreService.addOrUpdateTask(task);
      }
    }
  }

  Future<void> _syncProduct(String productId, String operation) async {
    if (operation == 'delete') {
      await _firestoreService.deleteProduct(productId);
    } else {
      final product = _hiveService.productBox.get(productId);
      if (product != null) {
        await _firestoreService.addOrUpdateProduct(product);
      }
    }
  }

  Future<void> _syncUser(String userId, String operation) async {
    final user = _hiveService.getCurrentUser();
    if (user != null) {
      await _firestoreService.saveUserProfile(user);
    }
  }

  /// Initialize sync monitoring
  void startSyncMonitoring() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (!results.contains(ConnectivityResult.none)) {
        // Device came online, sync pending items
        syncPendingItems();
      }
    });
  }

  /// Force sync all local data to Firebase (for manual sync)
  Future<void> forceSyncAll() async {
    if (!await _isOnline()) {
      throw Exception('No internet connection');
    }

    try {
      // Sync all tasks
      final tasks = _hiveService.getAllTasks();
      for (final task in tasks) {
        await _firestoreService.addOrUpdateTask(task);
      }

      // Sync user profile
      final user = _hiveService.getCurrentUser();
      if (user != null) {
        await _firestoreService.saveUserProfile(user);
      }

      // Clear sync queue
      final syncBox = await Hive.openBox('sync_queue');
      await syncBox.clear();
    } catch (e) {
      throw Exception('Sync failed: $e');
    }
  }

  /// Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    final syncBox = await Hive.openBox('sync_queue');
    final isOnline = await _isOnline();
    
    return {
      'isOnline': isOnline,
      'pendingItems': syncBox.length,
      'lastSyncAttempt': DateTime.now(),
    };
  }
}