import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product.dart';

class FirebaseService {
  final CollectionReference _productsRef =
      FirebaseFirestore.instance.collection('products');

  Future<void> addProduct(Product product) async {
    try {
      await _productsRef.add(product.toMap());
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  Stream<List<Product>> getProductsStream() {
    return _productsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Product.fromMap(data, id: '');
      }).toList().cast<Product>();
    });
  }
}
