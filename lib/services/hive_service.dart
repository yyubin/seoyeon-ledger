import 'package:hive/hive.dart';
import '../models/category.dart';
import '../models/category_group.dart';
import '../models/fixed_expense_record.dart';
import '../models/income_record.dart';
import '../models/recurring_expense.dart';
import '../models/recurring_interval_type.dart';
import '../models/saving_record.dart';
import '../models/transaction.dart';
import '../models/transaction_item.dart';
import '../models/transaction_type.dart';

class HiveService {
  static Box<Category> get categoryBox => Hive.box<Category>('categories');
  static Box<CategoryGroup> get categoryGroupBox =>
      Hive.box<CategoryGroup>('category_groups');
  static Box<IncomeRecord> get incomeRecordBox =>
      Hive.box<IncomeRecord>('income_records');
  static Box<SavingRecord> get savingRecordBox =>
      Hive.box<SavingRecord>('saving_records');
  static Box<FixedExpenseRecord> get fixedExpenseRecordBox =>
      Hive.box<FixedExpenseRecord>('fixed_expense_records');
  static Box<RecurringExpense> get recurringExpenseBox =>
      Hive.box<RecurringExpense>('recurring_expenses');
  static Box<Transaction> get transactionBox => Hive.box<Transaction>('transactions');

  static Future<void> ensureDefaultGroups() async {
    const defaults = [
      {'type': TransactionType.income, 'name': '고정수입'},
      {'type': TransactionType.income, 'name': '변동수입'},
      {'type': TransactionType.expense, 'name': '고정지출'},
      {'type': TransactionType.expense, 'name': '생활지출'},
      {'type': TransactionType.saving, 'name': '정기저축'},
      {'type': TransactionType.saving, 'name': '비상금'},
    ];

    for (var i = 0; i < defaults.length; i++) {
      final entry = defaults[i];
      final type = entry['type'] as TransactionType;
      final name = entry['name'] as String;
      final exists = categoryGroupBox.values.any(
        (g) => g.type == type && g.name == name,
      );
      if (!exists) {
        final order = categoryGroupBox.values
            .where((g) => g.type == type)
            .map((g) => g.order)
            .fold<int>(-1, (max, value) => value > max ? value : max) +
            1;
        final group = CategoryGroup(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: name,
          type: type,
          order: order,
        );
        await categoryGroupBox.put(group.id, group);
      }
    }

    await _ensureGroupOrders(TransactionType.income);
    await _ensureGroupOrders(TransactionType.expense);
    await _ensureGroupOrders(TransactionType.saving);
  }

  // Category CRUD
  static Future<void> addCategory(Category category) async {
    await categoryBox.put(category.id, category);
  }

  static List<Category> getCategories({TransactionType? type, String? groupId}) {
    if (type == null) {
      return categoryBox.values.toList();
    }
    return categoryBox.values
        .where((c) =>
            c.type == type && (groupId == null || c.groupId == groupId))
        .toList();
  }

  static List<Category> getUngroupedCategories({required TransactionType type}) {
    return categoryBox.values.where((c) => c.type == type && c.groupId == null).toList();
  }

  static Category? getCategory(String id) {
    return categoryBox.get(id);
  }

  static Future<void> deleteCategory(String id) async {
    await categoryBox.delete(id);
  }

  // Category Group CRUD
  static Future<void> addCategoryGroup(CategoryGroup group) async {
    await categoryGroupBox.put(group.id, group);
  }

  static Future<void> updateCategoryGroup(CategoryGroup group) async {
    await categoryGroupBox.put(group.id, group);
  }

  static CategoryGroup? getCategoryGroup(String id) {
    return categoryGroupBox.get(id);
  }

  static List<CategoryGroup> getCategoryGroups({TransactionType? type}) {
    if (type == null) {
      final all = categoryGroupBox.values.toList();
      all.sort(_compareGroupOrder);
      return all;
    }
    final groups = categoryGroupBox.values.where((g) => g.type == type).toList();
    groups.sort(_compareGroupOrder);
    return groups;
  }

  static Future<void> deleteCategoryGroup(String id) async {
    await categoryGroupBox.delete(id);
    final categoriesToUpdate = categoryBox.values.where((c) => c.groupId == id);
    for (final category in categoriesToUpdate) {
      category.groupId = null;
      await categoryBox.put(category.id, category);
    }
  }

  static int _compareGroupOrder(CategoryGroup a, CategoryGroup b) {
    if (a.order != b.order) {
      return a.order.compareTo(b.order);
    }
    return a.name.compareTo(b.name);
  }

  static int _compareRecordId(dynamic a, dynamic b) {
    final aId = int.tryParse(a.id) ?? 0;
    final bId = int.tryParse(b.id) ?? 0;
    return aId.compareTo(bId);
  }

  static Future<void> _ensureGroupOrders(TransactionType type) async {
    final groups = categoryGroupBox.values.where((g) => g.type == type).toList();
    groups.sort((a, b) => a.order.compareTo(b.order));
    for (var i = 0; i < groups.length; i++) {
      if (groups[i].order != i) {
        groups[i].order = i;
        await categoryGroupBox.put(groups[i].id, groups[i]);
      }
    }
  }

  static Future<void> updateGroupOrder(
    TransactionType type,
    List<CategoryGroup> orderedGroups,
  ) async {
    for (var i = 0; i < orderedGroups.length; i++) {
      orderedGroups[i].order = i;
      await categoryGroupBox.put(orderedGroups[i].id, orderedGroups[i]);
    }
    await _ensureGroupOrders(type);
  }

  // Transaction CRUD
  static Future<void> addTransaction(Transaction transaction) async {
    await transactionBox.put(transaction.id, transaction);
  }

  static Future<void> updateTransaction(Transaction transaction) async {
    await transactionBox.put(transaction.id, transaction);
  }

  static Future<void> deleteTransaction(String id) async {
    await transactionBox.delete(id);
  }

  static DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime _endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  static IncomeRecord? getIncomeRecordForGroupAndDate(
    String groupId,
    DateTime date,
  ) {
    final dayStart = _startOfDay(date).millisecondsSinceEpoch;
    for (final record in incomeRecordBox.values) {
      final recordDate = record.dateTimestamp ?? record.startTimestamp;
      if (record.groupId == groupId && recordDate == dayStart) {
        return record;
      }
    }
    return null;
  }

  static List<IncomeRecord> getIncomeRecordsForGroupAndDate(
    String groupId,
    DateTime date,
  ) {
    final dayStart = _startOfDay(date).millisecondsSinceEpoch;
    final records = incomeRecordBox.values.where((record) {
      final recordDate = record.dateTimestamp ?? record.startTimestamp;
      return record.groupId == groupId && recordDate == dayStart;
    }).toList();
    records.sort(_compareRecordId);
    return records;
  }

  static List<IncomeRecord> getIncomeRecordsByRange(DateTime start, DateTime end) {
    final startAt = _startOfDay(start).millisecondsSinceEpoch;
    final endAt = _endOfDay(end).millisecondsSinceEpoch;
    return incomeRecordBox.values.where((r) {
      final recordDate = r.dateTimestamp ?? r.startTimestamp;
      return recordDate >= startAt && recordDate <= endAt;
    }).toList();
  }

  static Future<void> upsertIncomeRecord(
    String groupId,
    DateTime date,
    int amount, {
    String? memo,
  }) async {
    final existing = getIncomeRecordForGroupAndDate(groupId, date);
    if (existing != null) {
      existing.amount = amount;
      existing.dateTimestamp = _startOfDay(date).millisecondsSinceEpoch;
      existing.memo = memo;
      await incomeRecordBox.put(existing.id, existing);
      return;
    }

    final startAt = _startOfDay(date).millisecondsSinceEpoch;
    final endAt = _endOfDay(date).millisecondsSinceEpoch;
    final record = IncomeRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      groupId: groupId,
      amount: amount,
      startTimestamp: startAt,
      endTimestamp: endAt,
      dateTimestamp: startAt,
      memo: memo,
    );
    await incomeRecordBox.put(record.id, record);
  }

  static Future<void> addIncomeRecord(
    String groupId,
    DateTime date,
    int amount, {
    String? memo,
  }) async {
    final startAt = _startOfDay(date).millisecondsSinceEpoch;
    final endAt = _endOfDay(date).millisecondsSinceEpoch;
    final record = IncomeRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      groupId: groupId,
      amount: amount,
      startTimestamp: startAt,
      endTimestamp: endAt,
      dateTimestamp: startAt,
      memo: memo,
    );
    await incomeRecordBox.put(record.id, record);
  }

  static Future<void> updateIncomeRecord(
    IncomeRecord record, {
    required int amount,
    String? memo,
  }) async {
    record.amount = amount;
    record.memo = memo;
    await incomeRecordBox.put(record.id, record);
  }

  static Future<void> deleteIncomeRecord(String id) async {
    await incomeRecordBox.delete(id);
  }

  static Future<void> deleteIncomeRecordForGroupAndDate(
    String groupId,
    DateTime date,
  ) async {
    final existing = getIncomeRecordForGroupAndDate(groupId, date);
    if (existing != null) {
      await incomeRecordBox.delete(existing.id);
    }
  }

  // Saving Record CRUD
  static SavingRecord? getSavingRecordForGroupAndDate(
    String groupId,
    DateTime date,
  ) {
    final dayStart = _startOfDay(date).millisecondsSinceEpoch;
    for (final record in savingRecordBox.values) {
      final recordDate = record.dateTimestamp ?? record.startTimestamp;
      if (record.groupId == groupId && recordDate == dayStart) {
        return record;
      }
    }
    return null;
  }

  static List<SavingRecord> getSavingRecordsForGroupAndDate(
    String groupId,
    DateTime date,
  ) {
    final dayStart = _startOfDay(date).millisecondsSinceEpoch;
    final records = savingRecordBox.values.where((record) {
      final recordDate = record.dateTimestamp ?? record.startTimestamp;
      return record.groupId == groupId && recordDate == dayStart;
    }).toList();
    records.sort(_compareRecordId);
    return records;
  }

  static List<SavingRecord> getSavingRecordsByRange(DateTime start, DateTime end) {
    final startAt = _startOfDay(start).millisecondsSinceEpoch;
    final endAt = _endOfDay(end).millisecondsSinceEpoch;
    return savingRecordBox.values.where((r) {
      final recordDate = r.dateTimestamp ?? r.startTimestamp;
      return recordDate >= startAt && recordDate <= endAt;
    }).toList();
  }

  static Future<void> upsertSavingRecord(
    String groupId,
    DateTime date,
    int amount, {
    String? memo,
  }) async {
    final existing = getSavingRecordForGroupAndDate(groupId, date);
    if (existing != null) {
      existing.amount = amount;
      existing.dateTimestamp = _startOfDay(date).millisecondsSinceEpoch;
      existing.memo = memo;
      await savingRecordBox.put(existing.id, existing);
      return;
    }

    final startAt = _startOfDay(date).millisecondsSinceEpoch;
    final endAt = _endOfDay(date).millisecondsSinceEpoch;
    final record = SavingRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      groupId: groupId,
      amount: amount,
      startTimestamp: startAt,
      endTimestamp: endAt,
      dateTimestamp: startAt,
      memo: memo,
    );
    await savingRecordBox.put(record.id, record);
  }

  static Future<void> addSavingRecord(
    String groupId,
    DateTime date,
    int amount, {
    String? memo,
  }) async {
    final startAt = _startOfDay(date).millisecondsSinceEpoch;
    final endAt = _endOfDay(date).millisecondsSinceEpoch;
    final record = SavingRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      groupId: groupId,
      amount: amount,
      startTimestamp: startAt,
      endTimestamp: endAt,
      dateTimestamp: startAt,
      memo: memo,
    );
    await savingRecordBox.put(record.id, record);
  }

  static Future<void> updateSavingRecord(
    SavingRecord record, {
    required int amount,
    String? memo,
  }) async {
    record.amount = amount;
    record.memo = memo;
    await savingRecordBox.put(record.id, record);
  }

  static Future<void> deleteSavingRecord(String id) async {
    await savingRecordBox.delete(id);
  }

  static Future<void> deleteSavingRecordForGroupAndDate(
    String groupId,
    DateTime date,
  ) async {
    final existing = getSavingRecordForGroupAndDate(groupId, date);
    if (existing != null) {
      await savingRecordBox.delete(existing.id);
    }
  }

  // Fixed Expense Record CRUD
  static FixedExpenseRecord? getFixedExpenseRecordForDate(DateTime date) {
    final dayStart = _startOfDay(date).millisecondsSinceEpoch;
    for (final record in fixedExpenseRecordBox.values) {
      if (record.dateTimestamp == dayStart) {
        return record;
      }
    }
    return null;
  }

  static List<FixedExpenseRecord> getFixedExpenseRecordsByRange(DateTime start, DateTime end) {
    final startAt = _startOfDay(start).millisecondsSinceEpoch;
    final endAt = _endOfDay(end).millisecondsSinceEpoch;
    return fixedExpenseRecordBox.values.where((r) {
      return r.dateTimestamp >= startAt && r.dateTimestamp <= endAt;
    }).toList();
  }

  static Future<void> upsertFixedExpenseRecord(
    DateTime date,
    int amount,
    List<TransactionItem> items, {
    String? memo,
  }) async {
    final existing = getFixedExpenseRecordForDate(date);
    if (existing != null) {
      existing.amount = amount;
      existing.items = items;
      existing.memo = memo;
      await fixedExpenseRecordBox.put(existing.id, existing);
      return;
    }

    final record = FixedExpenseRecord.create(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      amount: amount,
      date: _startOfDay(date),
      items: items,
      memo: memo,
    );
    await fixedExpenseRecordBox.put(record.id, record);
  }

  static Future<void> deleteFixedExpenseRecordForDate(DateTime date) async {
    final existing = getFixedExpenseRecordForDate(date);
    if (existing != null) {
      await fixedExpenseRecordBox.delete(existing.id);
    }
  }

  // Recurring Expense CRUD
  static List<RecurringExpense> getRecurringExpenses() {
    final items = recurringExpenseBox.values.toList();
    items.sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  static Future<void> addRecurringExpense(RecurringExpense expense) async {
    await recurringExpenseBox.put(expense.id, expense);
  }

  static Future<void> updateRecurringExpense(RecurringExpense expense) async {
    await recurringExpenseBox.put(expense.id, expense);
  }

  static Future<void> deleteRecurringExpense(String id) async {
    await recurringExpenseBox.delete(id);
  }

  static DateTime _resolveMonthlyDate(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    final safeDay = day > lastDay ? lastDay : day;
    return DateTime(year, month, safeDay);
  }

  static DateTime _initialNextRun(RecurringExpense expense) {
    final start = _startOfDay(
      DateTime.fromMillisecondsSinceEpoch(expense.startTimestamp),
    );
    switch (expense.intervalType) {
      case RecurringIntervalType.monthly:
        final day = expense.dayOfMonth ?? start.day;
        var candidate = _resolveMonthlyDate(start.year, start.month, day);
        if (candidate.isBefore(start)) {
          candidate = _resolveMonthlyDate(start.year, start.month + 1, day);
        }
        return candidate;
      case RecurringIntervalType.weekly:
        final targetWeekday = expense.weekday ?? start.weekday;
        var candidate = start;
        while (candidate.weekday != targetWeekday) {
          candidate = candidate.add(const Duration(days: 1));
        }
        return candidate;
      case RecurringIntervalType.intervalDays:
        return start;
    }
  }

  static DateTime _nextOccurrence(RecurringExpense expense, DateTime from) {
    final base = _startOfDay(from);
    switch (expense.intervalType) {
      case RecurringIntervalType.monthly:
        final day = expense.dayOfMonth ?? base.day;
        return _resolveMonthlyDate(base.year, base.month + 1, day);
      case RecurringIntervalType.weekly:
        return base.add(const Duration(days: 7));
      case RecurringIntervalType.intervalDays:
        final interval = expense.intervalDays ?? 1;
        return base.add(Duration(days: interval));
    }
  }

  static Future<void> ensureRecurringExpenses(DateTime start, DateTime end) async {
    final rangeStart = _startOfDay(start);
    final rangeEnd = _endOfDay(end);

    for (final expense in recurringExpenseBox.values) {
      if (!expense.isActive) {
        continue;
      }

      DateTime nextRun;
      if (expense.nextRunTimestamp != null) {
        nextRun = DateTime.fromMillisecondsSinceEpoch(expense.nextRunTimestamp!);
      } else {
        nextRun = _initialNextRun(expense);
      }

      final endDate = expense.endTimestamp == null
          ? null
          : _endOfDay(DateTime.fromMillisecondsSinceEpoch(expense.endTimestamp!));

      while (nextRun.isBefore(rangeStart)) {
        nextRun = _nextOccurrence(expense, nextRun);
        if (endDate != null && nextRun.isAfter(endDate)) {
          break;
        }
      }

      while (!nextRun.isAfter(rangeEnd)) {
        if (endDate != null && nextRun.isAfter(endDate)) {
          break;
        }

        final id = '${expense.id}_${nextRun.millisecondsSinceEpoch}';
        if (!transactionBox.containsKey(id)) {
          final transaction = Transaction.create(
            id: id,
            amount: expense.amount,
            type: TransactionType.expense,
            categoryId: expense.categoryId,
            memo: expense.memo,
            date: nextRun,
            items: expense.items.isNotEmpty ? List.of(expense.items) : null,
            source: 'recurring',
            recurringId: expense.id,
          );
          await transactionBox.put(id, transaction);
        }

        nextRun = _nextOccurrence(expense, nextRun);
      }

      expense.nextRunTimestamp = nextRun.millisecondsSinceEpoch;
      await recurringExpenseBox.put(expense.id, expense);
    }
  }

  static List<Transaction> getTransactionsByDateRange(DateTime start, DateTime end) {
    final startAt = _startOfDay(start);
    final endAt = _endOfDay(end);
    return transactionBox.values.where((t) {
      return !t.date.isBefore(startAt) && !t.date.isAfter(endAt);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static int getTotalIncomeByDateRange(DateTime start, DateTime end) {
    final startAt = _startOfDay(start).millisecondsSinceEpoch;
    final endAt = _endOfDay(end).millisecondsSinceEpoch;
    return incomeRecordBox.values
        .where((r) => r.startTimestamp == startAt && r.endTimestamp == endAt)
        .fold(0, (sum, r) => sum + r.amount);
  }

  static int getTotalExpenseByDateRange(DateTime start, DateTime end) {
    final startAt = _startOfDay(start);
    final endAt = _endOfDay(end);
    return transactionBox.values
        .where((t) =>
            !t.date.isBefore(startAt) &&
            !t.date.isAfter(endAt) &&
            t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount);
  }

  static Map<String, int> getCategoryTotalsByDateRange(
    DateTime start,
    DateTime end,
    TransactionType type,
  ) {
    final startAt = _startOfDay(start);
    final endAt = _endOfDay(end);
    final totals = <String, int>{};
    final transactions = transactionBox.values.where((t) =>
        !t.date.isBefore(startAt) && !t.date.isAfter(endAt) && t.type == type);

    for (final t in transactions) {
      totals[t.categoryId] = (totals[t.categoryId] ?? 0) + t.amount;
    }
    return totals;
  }
}
