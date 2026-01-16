import 'package:hive/hive.dart';
import 'transaction_type.dart';

part 'category.g.dart';

@HiveType(typeId: 1)
class Category extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  TransactionType type;

  @HiveField(3)
  String? groupId;

  @HiveField(4)
  int? colorIndex;

  Category({
    required this.id,
    required this.name,
    required this.type,
    this.groupId,
    this.colorIndex,
  });
}
