// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saving_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavingRecordAdapter extends TypeAdapter<SavingRecord> {
  @override
  final int typeId = 8;

  @override
  SavingRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavingRecord(
      id: fields[0] as String,
      groupId: fields[1] as String,
      amount: fields[2] as int,
      startTimestamp: fields[3] as int,
      endTimestamp: fields[4] as int,
      dateTimestamp: fields[5] as int?,
      memo: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SavingRecord obj) {
    writer
      ..writeByte(7)
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
      ..write(obj.dateTimestamp)
      ..writeByte(6)
      ..write(obj.memo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
