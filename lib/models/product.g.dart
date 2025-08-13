// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductAdapter extends TypeAdapter<Product> {
  @override
  final int typeId = 3;

  @override
  Product read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Product(
      id: fields[0] as String?,
      name: fields[1] as String,
      description: fields[2] as String,
      price: fields[3] as double,
      type: fields[4] as ProductType,
      listingType: fields[5] as ListingType,
      sellerId: fields[6] as String,
      location: fields[7] as String?,
      createdAt: fields[8] as DateTime?,
      images: (fields[9] as List?)?.cast<String>(),
      isAvailable: fields[10] as bool,
      contactNumber: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Product obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.price)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.listingType)
      ..writeByte(6)
      ..write(obj.sellerId)
      ..writeByte(7)
      ..write(obj.location)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.images)
      ..writeByte(10)
      ..write(obj.isAvailable)
      ..writeByte(11)
      ..write(obj.contactNumber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProductTypeAdapter extends TypeAdapter<ProductType> {
  @override
  final int typeId = 4;

  @override
  ProductType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ProductType.crop;
      case 1:
        return ProductType.seed;
      case 2:
        return ProductType.fertilizer;
      case 3:
        return ProductType.tool;
      case 4:
        return ProductType.other;
      default:
        return ProductType.crop;
    }
  }

  @override
  void write(BinaryWriter writer, ProductType obj) {
    switch (obj) {
      case ProductType.crop:
        writer.writeByte(0);
        break;
      case ProductType.seed:
        writer.writeByte(1);
        break;
      case ProductType.fertilizer:
        writer.writeByte(2);
        break;
      case ProductType.tool:
        writer.writeByte(3);
        break;
      case ProductType.other:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ListingTypeAdapter extends TypeAdapter<ListingType> {
  @override
  final int typeId = 5;

  @override
  ListingType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ListingType.sell;
      case 1:
        return ListingType.buy;
      case 2:
        return ListingType.barter;
      default:
        return ListingType.sell;
    }
  }

  @override
  void write(BinaryWriter writer, ListingType obj) {
    switch (obj) {
      case ListingType.sell:
        writer.writeByte(0);
        break;
      case ListingType.buy:
        writer.writeByte(1);
        break;
      case ListingType.barter:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListingTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
