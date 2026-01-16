import 'package:hive/hive.dart';
import 'transaction_item.dart';
import 'recurring_interval_type.dart';

part 'recurring_expense.g.dart';

@HiveType(typeId: 7)
class RecurringExpense extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int amount;

  @HiveField(3)
  String categoryId;

  @HiveField(4)
  String? memo;

  @HiveField(5)
  List<TransactionItem> items;

  @HiveField(6)
  RecurringIntervalType intervalType;

  @HiveField(7)
  int? dayOfMonth;

  @HiveField(8)
  int? weekday;

  @HiveField(9)
  int? intervalDays;

  @HiveField(10)
  int startTimestamp;

  @HiveField(11)
  int? endTimestamp;

  @HiveField(12)
  int? nextRunTimestamp;

  @HiveField(13)
  bool isActive;

  RecurringExpense({
    required this.id,
    required this.name,
    required this.amount,
    required this.categoryId,
    required this.intervalType,
    required this.startTimestamp,
    this.memo,
    List<TransactionItem>? items,
    this.dayOfMonth,
    this.weekday,
    this.intervalDays,
    this.endTimestamp,
    this.nextRunTimestamp,
    this.isActive = true,
  }) : items = items ?? [];
}
