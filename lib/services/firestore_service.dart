import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/crop_task.dart';
import '../models/product.dart';
import '../models/user.dart' as app_user;

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  // ========== PRODUCTS (Global Marketplace) ==========
  
  Future<void> addOrUpdateProduct(Product product) async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    
    final productData = product.toMap();
    productData['userId'] = _currentUserId;
    productData['createdAt'] = FieldValue.serverTimestamp();
    productData['updatedAt'] = FieldValue.serverTimestamp();
    
    await _firestore
        .collection('products')
        .doc(product.id)
        .set(productData, SetOptions(merge: true));
  }

  Stream<List<Product>> getProductsStream() {
    return _firestore
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  Future<void> deleteProduct(String productId) async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    
    final productDoc = await _firestore.collection('products').doc(productId).get();
    if (!productDoc.exists) return;
    
    final productData = productDoc.data()!;
    if (productData['userId'] != _currentUserId) {
      throw Exception('Unauthorized to delete this product');
    }
    
    await _firestore.collection('products').doc(productId).delete();
  }

  // ========== TASKS (User-specific) ==========
  
  Future<void> addOrUpdateTask(CropTask task) async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    
    final taskData = task.toMap();
    taskData['userId'] = _currentUserId;
    taskData['createdAt'] = FieldValue.serverTimestamp();
    taskData['updatedAt'] = FieldValue.serverTimestamp();
    
    await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('tasks')
        .doc(task.id)
        .set(taskData, SetOptions(merge: true));
  }

  Stream<List<CropTask>> getTasksStream() {
    if (_currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('tasks')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CropTask.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  Future<void> deleteTask(String taskId) async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    
    await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  // ========== USER PROFILE ==========
  
  Future<void> saveUserProfile(app_user.User user) async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    
    final userData = user.toMap();
    userData['updatedAt'] = FieldValue.serverTimestamp();
    
    await _firestore
        .collection('users')
        .doc(_currentUserId)
        .set(userData, SetOptions(merge: true));
  }

  Future<app_user.User?> getUserProfile() async {
    if (_currentUserId == null) return null;
    
    final doc = await _firestore.collection('users').doc(_currentUserId).get();
    if (!doc.exists) return null;
    
    return app_user.User.fromMap(doc.data()!, id: doc.id);
  }

  // ========== MESSAGING ==========
  
  Future<void> sendMessage(String productId, String receiverId, String content) async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    
    final messageData = {
      'senderId': _currentUserId,
      'receiverId': receiverId,
      'productId': productId,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    };
    
    await _firestore.collection('messages').add(messageData);
  }

  Stream<List<Map<String, dynamic>>> getMessagesStream(String productId, String otherUserId) {
    if (_currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection('messages')
        .where('productId', isEqualTo: productId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) {
              final data = doc.data();
              return (data['senderId'] == _currentUserId && data['receiverId'] == otherUserId) ||
                     (data['senderId'] == otherUserId && data['receiverId'] == _currentUserId);
            })
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList());
  }

  // ========== ANALYTICS ==========
  
  Future<void> logEvent(String eventName, Map<String, dynamic> parameters) async {
    if (_currentUserId == null) return;
    
    try {
      await _firestore.collection('analytics').add({
        'userId': _currentUserId,
        'eventName': eventName,
        'parameters': parameters,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Analytics failures shouldn't break the app
    }
  }

  // ========== BATCH OPERATIONS ==========
  
  Future<void> batchSync(List<Map<String, dynamic>> operations) async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    
    final batch = _firestore.batch();
    
    for (final operation in operations) {
      final type = operation['type'] as String;
      final data = operation['data'] as Map<String, dynamic>;
      
      switch (type) {
        case 'task_create':
          final taskRef = _firestore
              .collection('users')
              .doc(_currentUserId)
              .collection('tasks')
              .doc(data['id']);
          batch.set(taskRef, data);
          break;
        case 'task_delete':
          final taskRef = _firestore
              .collection('users')
              .doc(_currentUserId)
              .collection('tasks')
              .doc(data['id']);
          batch.delete(taskRef);
          break;
        case 'product_create':
          final productRef = _firestore.collection('products').doc(data['id']);
          batch.set(productRef, data);
          break;
        case 'product_delete':
          final productRef = _firestore.collection('products').doc(data['id']);
          batch.delete(productRef);
          break;
      }
    }
    
    await batch.commit();
  }
}