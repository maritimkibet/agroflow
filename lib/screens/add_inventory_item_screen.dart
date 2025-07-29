import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import 'package:hive/hive.dart';

class AddInventoryItemScreen extends StatefulWidget {
  final InventoryItem? existingItem;
  final int? itemIndex;

  const AddInventoryItemScreen({super.key, this.existingItem, this.itemIndex});

  @override
  State<AddInventoryItemScreen> createState() => _AddInventoryItemScreenState();
}

class _AddInventoryItemScreenState extends State<AddInventoryItemScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _quantityController;

  late Box<InventoryItem> _inventoryBox;

  @override
  void initState() {
    super.initState();
    _inventoryBox = Hive.box<InventoryItem>('inventoryBox');

    _nameController = TextEditingController(text: widget.existingItem?.name ?? '');
    _categoryController = TextEditingController(text: widget.existingItem?.category ?? '');
    _quantityController = TextEditingController(text: widget.existingItem?.quantity.toString() ?? '0');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _saveItem() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final category = _categoryController.text.trim();
      final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;

      final newItem = InventoryItem(name: name, category: category, quantity: quantity);

      if (widget.existingItem == null) {
        _inventoryBox.add(newItem);
      } else {
        _inventoryBox.putAt(widget.itemIndex!, newItem);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingItem != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Inventory Item' : 'Add Inventory Item'),
        backgroundColor: Colors.green.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Item Name'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Please enter item name' : null,
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final qty = int.tryParse(value ?? '');
                  if (qty == null || qty < 0) return 'Enter valid quantity';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(isEditing ? 'Update' : 'Add'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
