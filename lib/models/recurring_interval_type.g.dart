// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_interval_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurringIntervalTypeAdapter extends TypeAdapter<RecurringIntervalType> {
  @override
  final int typeId = 6;

  @override
  RecurringIntervalType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RecurringIntervalType.monthly;
      case 1:
        return RecurringIntervalType.weekly;
      case 2:
        return RecurringIntervalType.intervalDays;
      default:
        return RecurringIntervalType.monthly;
    }
  }

  @override
  void write(BinaryWriter writer, RecurringIntervalType obj) {
    switch (obj) {
      case RecurringIntervalType.monthly:
        writer.writeByte(0);
        break;
      case RecurringIntervalType.weekly:
        writer.writeByte(1);
        break;
      case RecurringIntervalType.intervalDays:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringIntervalTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
