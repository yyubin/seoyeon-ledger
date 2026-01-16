// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'income_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IncomeRecordAdapter extends TypeAdapter<IncomeRecord> {
  @override
  final int typeId = 5;

  @override
  IncomeRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IncomeRecord(
      id: fields[0] as String,
      groupId: fields[1] as String,
      amount: fields[2] as int,
      startTimestamp: fields[3] as int,
      endTimestamp: fields[4] as int,
      dateTimestamp: fields[5] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, IncomeRecord obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.groupId)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.startTimestamp)
      ..writeByte(4)
      ..write(obj.endTimestamp)
      ..writeByte(5)
      ..write(obj.dateTimestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IncomeRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
