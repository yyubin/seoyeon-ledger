// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_expense.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurringExpenseAdapter extends TypeAdapter<RecurringExpense> {
  @override
  final int typeId = 7;

  @override
  RecurringExpense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurringExpense(
      id: fields[0] as String,
      name: fields[1] as String,
      amount: fields[2] as int,
      categoryId: fields[3] as String,
      memo: fields[4] as String?,
      items: (fields[5] as List?)?.cast<TransactionItem>(),
      intervalType: fields[6] as RecurringIntervalType,
      dayOfMonth: fields[7] as int?,
      weekday: fields[8] as int?,
      intervalDays: fields[9] as int?,
      startTimestamp: fields[10] as int,
      endTimestamp: fields[11] as int?,
      nextRunTimestamp: fields[12] as int?,
      isActive: fields[13] as bool? ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringExpense obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.categoryId)
      ..writeByte(4)
      ..write(obj.memo)
      ..writeByte(5)
      ..write(obj.items)
      ..writeByte(6)
      ..write(obj.intervalType)
      ..writeByte(7)
      ..write(obj.dayOfMonth)
      ..writeByte(8)
      ..write(obj.weekday)
      ..writeByte(9)
      ..write(obj.intervalDays)
      ..writeByte(10)
      ..write(obj.startTimestamp)
      ..writeByte(11)
      ..write(obj.endTimestamp)
      ..writeByte(12)
      ..write(obj.nextRunTimestamp)
      ..writeByte(13)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
