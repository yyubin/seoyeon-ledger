// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fixed_expense_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FixedExpenseRecordAdapter extends TypeAdapter<FixedExpenseRecord> {
  @override
  final int typeId = 9;

  @override
  FixedExpenseRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FixedExpenseRecord(
      id: fields[0] as String,
      amount: fields[1] as int,
      dateTimestamp: fields[2] as int,
      items: (fields[3] as List?)?.cast<TransactionItem>(),
      memo: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FixedExpenseRecord obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.dateTimestamp)
      ..writeByte(3)
      ..write(obj.items)
      ..writeByte(4)
      ..write(obj.memo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FixedExpenseRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
