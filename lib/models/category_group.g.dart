// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_group.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CategoryGroupAdapter extends TypeAdapter<CategoryGroup> {
  @override
  final int typeId = 4;

  @override
  CategoryGroup read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoryGroup(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as TransactionType,
      order: (fields[3] as int?) ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, CategoryGroup obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.order);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryGroupAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
