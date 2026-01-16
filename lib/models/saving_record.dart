import 'package:hive/hive.dart';

part 'saving_record.g.dart';

@HiveType(typeId: 8)
class SavingRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String groupId;

  @HiveField(2)
  int amount;

  @HiveField(3)
  final int startTimestamp;

  @HiveField(4)
  final int endTimestamp;

  @HiveField(5)
  int? dateTimestamp;

  @HiveField(6)
  String? memo;

  DateTime get startDate => DateTime.fromMillisecondsSinceEpoch(startTimestamp);
  DateTime get endDate => DateTime.fromMillisecondsSinceEpoch(endTimestamp);
  DateTime get date =>
      DateTime.fromMillisecondsSinceEpoch(dateTimestamp ?? startTimestamp);

  SavingRecord({
    required this.id,
    required this.groupId,
    required this.amount,
    required this.startTimestamp,
    required this.endTimestamp,
    this.dateTimestamp,
    this.memo,
  });
}
