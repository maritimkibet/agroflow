import 'package:hive/hive.dart';

part 'inventory_item.g.dart';

@HiveType(typeId: 4)
class InventoryItem extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String category;

  @HiveField(2)
  int quantity;

  InventoryItem({
    required this.name,
    required this.category,
    required this.quantity,
  });
}
