import 'package:hive/hive.dart';
import 'transaction_type.dart';
import 'transaction_item.dart';

part 'transaction.g.dart';

@HiveType(typeId: 2)
class Transaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  int amount;

  @HiveField(2)
  TransactionType type;

  @HiveField(3)
  String categoryId;

  @HiveField(4)
  String? memo;

  @HiveField(5)
  int dateTimestamp;

  @HiveField(6)
  List<TransactionItem> items;

  @HiveField(7)
  String? source;

  @HiveField(8)
  String? recurringId;

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(dateTimestamp);
  set date(DateTime value) => dateTimestamp = value.millisecondsSinceEpoch;

  bool get hasItems => items.isNotEmpty;

  Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.memo,
    this.dateTimestamp = 0,
    List<TransactionItem>? items,
    this.source,
    this.recurringId,
  }) : items = items ?? [];

  factory Transaction.create({
    required String id,
    required int amount,
    required TransactionType type,
    required String categoryId,
    String? memo,
    required DateTime date,
    List<TransactionItem>? items,
    String? source,
    String? recurringId,
  }) {
    return Transaction(
      id: id,
      amount: amount,
      type: type,
      categoryId: categoryId,
      memo: memo,
      dateTimestamp: date.millisecondsSinceEpoch,
      items: items,
      source: source,
      recurringId: recurringId,
    );
  }
}
