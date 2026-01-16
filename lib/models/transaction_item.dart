import 'package:hive/hive.dart';

part 'transaction_item.g.dart';

@HiveType(typeId: 3)
class TransactionItem {
  @HiveField(0)
  String name;

  @HiveField(1)
  int amount;

  TransactionItem({
    required this.name,
    required this.amount,
  });
}
