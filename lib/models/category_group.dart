import 'package:hive/hive.dart';
import 'transaction_type.dart';

part 'category_group.g.dart';

@HiveType(typeId: 4)
class CategoryGroup extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  TransactionType type;

  @HiveField(3)
  int order;

  CategoryGroup({
    required this.id,
    required this.name,
    required this.type,
    required this.order,
  });
}
