// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 2;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction(
      id: fields[0] as String,
      amount: fields[1] as int,
      type: fields[2] as TransactionType,
      categoryId: fields[3] as String,
      memo: fields[4] as String?,
      dateTimestamp: fields[5] as int,
      items: (fields[6] as List?)?.cast<TransactionItem>(),
      source: fields[7] as String?,
      recurringId: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.categoryId)
      ..writeByte(4)
      ..write(obj.memo)
      ..writeByte(5)
      ..write(obj.dateTimestamp)
      ..writeByte(6)
      ..write(obj.items)
      ..writeByte(7)
      ..write(obj.source)
      ..writeByte(8)
      ..write(obj.recurringId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
