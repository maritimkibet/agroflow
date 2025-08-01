import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'product.g.dart';

@HiveType(typeId: 3)
class Product extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  double price;

  @HiveField(4)
  ProductType type;

  @HiveField(5)
  ListingType listingType;

  @HiveField(6)
  String sellerId;

  @HiveField(7)
  String? location;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  List<String>? images;

  @HiveField(10)
  bool isAvailable;

  Product({
    String? id,
    required this.name,
    required this.description,
    required this.price,
    required this.type,
    required this.listingType,
    required this.sellerId,
    this.location,
    DateTime? createdAt,
    this.images,
    this.isAvailable = true,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Firestore serialization
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'type': type.index,
        'listingType': listingType.index,
        'sellerId': sellerId,
        'location': location,
        'createdAt': createdAt.toIso8601String(),
        'images': images ?? [],
        'isAvailable': isAvailable,
      };

  /// Firestore deserialization
  static Product fromMap(Map<String, dynamic> data, {required String id}) => Product(
        id: id,
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        price: (data['price'] is int)
            ? (data['price'] as int).toDouble()
            : (data['price'] as double? ?? 0.0),
        type: ProductType.values[(data['type'] ?? 0).clamp(0, ProductType.values.length - 1)],
        listingType: ListingType.values[(data['listingType'] ?? 0).clamp(0, ListingType.values.length - 1)],
        sellerId: data['sellerId'] ?? '',
        location: data['location'],
        createdAt: data['createdAt'] != null
            ? DateTime.tryParse(data['createdAt']) ?? DateTime.now()
            : DateTime.now(),
        images: data['images'] != null ? List<String>.from(data['images']) : [],
        isAvailable: data['isAvailable'] ?? true,
      );

  static Product empty() => Product(
        id: '',
        name: '',
        description: '',
        price: 0.0,
        type: ProductType.other,
        listingType: ListingType.sell,
        sellerId: '',
        location: null,
        createdAt: DateTime.now(),
        images: [],
        isAvailable: false,
      );
}

@HiveType(typeId: 4)
enum ProductType {
  @HiveField(0)
  crop,
  @HiveField(1)
  seed,
  @HiveField(2)
  fertilizer,
  @HiveField(3)
  tool,
  @HiveField(4)
  other,
}

@HiveType(typeId: 5)
enum ListingType {
  @HiveField(0)
  sell,
  @HiveField(1)
  buy,
  @HiveField(2)
  barter,
}
