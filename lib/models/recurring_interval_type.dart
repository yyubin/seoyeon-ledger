import 'package:hive/hive.dart';

part 'recurring_interval_type.g.dart';

@HiveType(typeId: 6)
enum RecurringIntervalType {
  @HiveField(0)
  monthly,

  @HiveField(1)
  weekly,

  @HiveField(2)
  intervalDays,
}
