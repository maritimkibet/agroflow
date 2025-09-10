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

  // New field for contact number
  @HiveField(11)
  String? contactNumber;

  // Admin fields
  @HiveField(12)
  String? imageUrl;

  @HiveField(13)
  bool isFlagged;

  @HiveField(14)
  DateTime? flaggedAt;

  @HiveField(15)
  bool isApproved;

  @HiveField(16)
  DateTime? moderatedAt;

  @HiveField(17)
  String? moderationReason;

  @HiveField(18)
  String? moderatedBy;

  @HiveField(19)
  String category;

  @HiveField(20)
  Map<String, dynamic>? metadata;

  @HiveField(21)
  List<String> tags;

  // ✅ use sellerName (to match admin_service.dart)
  @HiveField(22)
  String sellerName;

  @HiveField(23)
  double? quantity;

  @HiveField(24)
  String? unit;

  @HiveField(25)
  DateTime? harvestDate;

  @HiveField(26)
  DateTime? expiryDate;

  @HiveField(27)
  bool isOrganic;

  @HiveField(28)
  List<String>? certifications;

  @HiveField(29)
  DateTime? updatedAt;

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
    this.contactNumber,
    this.imageUrl,
    this.isFlagged = false,
    this.flaggedAt,
    this.isApproved = true,
    this.moderatedAt,
    this.moderationReason,
    this.moderatedBy,
    required this.category,
    this.metadata,
    required this.tags,
    required this.sellerName,
    this.quantity,
    this.unit,
    this.harvestDate,
    this.expiryDate,
    this.isOrganic = false,
    this.certifications,
    this.updatedAt,
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
        'contactNumber': contactNumber,
        'imageUrl': imageUrl,
        'isFlagged': isFlagged,
        'flaggedAt': flaggedAt?.toIso8601String(),
        'isApproved': isApproved,
        'moderatedAt': moderatedAt?.toIso8601String(),
        'moderationReason': moderationReason,
        'moderatedBy': moderatedBy,
        'category': category,
        'metadata': metadata,
        'tags': tags,
        'sellerName': sellerName,
        'quantity': quantity,
        'unit': unit,
        'harvestDate': harvestDate?.toIso8601String(),
        'expiryDate': expiryDate?.toIso8601String(),
        'isOrganic': isOrganic,
        'certifications': certifications,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  /// Firestore deserialization
  static Product fromMap(Map<String, dynamic> data, {required String id}) =>
      Product(
        id: id,
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        price: (data['price'] is int)
            ? (data['price'] as int).toDouble()
            : (data['price'] as double? ?? 0.0),
        type: ProductType.values[
            (data['type'] ?? 0).clamp(0, ProductType.values.length - 1)],
        listingType: ListingType.values[(data['listingType'] ?? 0)
            .clamp(0, ListingType.values.length - 1)],
        sellerId: data['sellerId'] ?? '',
        location: data['location'],
        createdAt: data['createdAt'] != null
            ? DateTime.tryParse(data['createdAt']) ?? DateTime.now()
            : DateTime.now(),
        images:
            data['images'] != null ? List<String>.from(data['images']) : [],
        isAvailable: data['isAvailable'] ?? true,
        contactNumber: data['contactNumber'],
        imageUrl: data['imageUrl'],
        isFlagged: data['isFlagged'] ?? false,
        flaggedAt: data['flaggedAt'] != null
            ? DateTime.tryParse(data['flaggedAt'])
            : null,
        isApproved: data['isApproved'] ?? true,
        moderatedAt: data['moderatedAt'] != null
            ? DateTime.tryParse(data['moderatedAt'])
            : null,
        moderationReason: data['moderationReason'],
        moderatedBy: data['moderatedBy'],
        category: data['category'] ?? 'Other',
        metadata: data['metadata'] != null
            ? Map<String, dynamic>.from(data['metadata'])
            : null,
        tags: data['tags'] != null ? List<String>.from(data['tags']) : [],
        sellerName: data['sellerName'] ?? '',
        quantity: data['quantity']?.toDouble(),
        unit: data['unit'],
        harvestDate: data['harvestDate'] != null
            ? DateTime.tryParse(data['harvestDate'])
            : null,
        expiryDate: data['expiryDate'] != null
            ? DateTime.tryParse(data['expiryDate'])
            : null,
        isOrganic: data['isOrganic'] ?? false,
        certifications: data['certifications'] != null
            ? List<String>.from(data['certifications'])
            : null,
        updatedAt: data['updatedAt'] != null
            ? DateTime.tryParse(data['updatedAt'])
            : null,
      );

  /// Firestore document deserialization
  static Product fromFirestore(dynamic doc) {
    if (doc == null || !doc.exists) {
      return empty();
    }
    
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return fromMap(data, id: doc.id);
  }

  /// Empty product template
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
        contactNumber: null,
        category: 'Other',
        tags: [],
        sellerName: '',
        quantity: 0,
        unit: 'kg',
        isOrganic: false,
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
