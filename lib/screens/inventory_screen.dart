import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/inventory_item.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late Box<InventoryItem> _inventoryBox;

  @override
  void initState() {
    super.initState();
    _inventoryBox = Hive.box<InventoryItem>('inventoryBox');
  }

  void _showAddDialog({InventoryItem? item, int? index}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final quantityController =
        TextEditingController(text: item?.quantity.toString() ?? '');
    final categoryController = TextEditingController(text: item?.category ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item == null ? 'Add Item' : 'Edit Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
            TextField(controller: quantityController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final itemName = nameController.text.trim();
              final itemCategory = categoryController.text.trim();
              final itemQty = int.tryParse(quantityController.text.trim()) ?? 0;

              if (itemName.isNotEmpty) {
                final newItem = InventoryItem(
                  name: itemName,
                  category: itemCategory,
                  quantity: itemQty,
                );
                if (item == null) {
                  _inventoryBox.add(newItem);
                } else {
                  _inventoryBox.putAt(index!, newItem);
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _inventoryBox.deleteAt(index);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        backgroundColor: Colors.green.shade700,
      ),
      body: ValueListenableBuilder(
        valueListenable: _inventoryBox.listenable(),
        builder: (context, Box<InventoryItem> box, _) {
          if (box.isEmpty) {
            return const Center(child: Text('No items in inventory.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: box.length,
            itemBuilder: (context, index) {
              final item = box.getAt(index)!;
              return Card(
                child: ListTile(
                  title: Text(item.name),
                  subtitle: Text('${item.category} • ${item.quantity} pcs'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit), onPressed: () => _showAddDialog(item: item, index: index)),
                      IconButton(icon: const Icon(Icons.delete), onPressed: () => _confirmDelete(index)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add),
        onPressed: () => _showAddDialog(),
      ),
    );
  }
}
