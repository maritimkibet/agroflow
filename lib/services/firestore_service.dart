import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/crop_task.dart';
import '../models/product.dart';

class FirestoreService {
  final _taskCollection = FirebaseFirestore.instance.collection('crop_tasks');
  final _productCollection = FirebaseFirestore.instance.collection('products');

  // Crop Tasks
  Future<void> addOrUpdateTask(CropTask task) async {
    await _taskCollection.doc(task.id).set(task.toJson());
  }

  Stream<List<CropTask>> getTasksStream() {
    return _taskCollection.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => CropTask.fromJson(doc.data())).toList());
  }

  Future<void> deleteTask(String id) async {
    await _taskCollection.doc(id).delete();
  }

  // 🔥 Products
  Future<void> addOrUpdateProduct(Product product) async {
    await _productCollection.doc(product.id).set(product.toMap());
  }

  Stream<List<Product>> getProductsStream() {
    return _productCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  Future<void> deleteProduct(String id) async {
    await _productCollection.doc(id).delete();
  }

  Future<Product?> getProductById(String id) async {
    final doc = await _productCollection.doc(id).get();
    if (doc.exists) {
      return Product.fromMap(doc.data()!, id: doc.id);
    }
    return null;
  }
}
