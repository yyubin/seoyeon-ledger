import 'package:hive/hive.dart';
import 'transaction_item.dart';

part 'fixed_expense_record.g.dart';

@HiveType(typeId: 9)
class FixedExpenseRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  int amount;

  @HiveField(2)
  final int dateTimestamp;

  @HiveField(3)
  List<TransactionItem> items;

  @HiveField(4)
  String? memo;

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(dateTimestamp);

  bool get hasItems => items.isNotEmpty;

  FixedExpenseRecord({
    required this.id,
    required this.amount,
    required this.dateTimestamp,
    List<TransactionItem>? items,
    this.memo,
  }) : items = items ?? [];

  factory FixedExpenseRecord.create({
    required String id,
    required int amount,
    required DateTime date,
    List<TransactionItem>? items,
    String? memo,
  }) {
    return FixedExpenseRecord(
      id: id,
      amount: amount,
      dateTimestamp: date.millisecondsSinceEpoch,
      items: items,
      memo: memo,
    );
  }
}
