import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/category_group.dart';
import '../models/income_record.dart';
import '../models/saving_record.dart';
import '../models/transaction.dart';
import '../models/transaction_item.dart';
import '../models/transaction_type.dart';
import '../services/hive_service.dart';
import '../utils/amount_input_formatter.dart';
import '../widgets/category_color_palette.dart';
import '../widgets/date_range_selector.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_tile.dart';
import 'income_input_screen.dart';
import 'saving_input_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _startDate;
  late DateTime _endDate;

  Box get _settingsBox => Hive.box('settings');

  @override
  void initState() {
    super.initState();
    _loadSavedDateRange();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await HiveService.ensureRecurringExpenses(_startDate, _endDate);
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _loadSavedDateRange() {
    final savedStartTimestamp = _settingsBox.get('startDate') as int?;
    final savedEndTimestamp = _settingsBox.get('endDate') as int?;

    if (savedStartTimestamp != null && savedEndTimestamp != null) {
      _startDate = DateTime.fromMillisecondsSinceEpoch(savedStartTimestamp);
      _endDate = DateTime.fromMillisecondsSinceEpoch(savedEndTimestamp);
    } else {
      final now = DateTime.now();
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = DateTime(now.year, now.month + 1, 0);
    }
  }

  Future<void> _saveDateRange() async {
    await _settingsBox.put('startDate', _startDate.millisecondsSinceEpoch);
    await _settingsBox.put('endDate', _endDate.millisecondsSinceEpoch);
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6C63FF),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      await _saveDateRange();
      await HiveService.ensureRecurringExpenses(_startDate, _endDate);
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _editTransaction(Transaction transaction) async {
    await _openQuickEditModal(transaction);
  }

  Future<void> _openIncomeInput() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => IncomeInputScreen(
          startDate: _startDate,
          endDate: _endDate,
        ),
      ),
    );
    if (result == true) {
      setState(() {});
    }
  }

  Future<void> _openSavingInput() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SavingInputScreen(
          startDate: _startDate,
          endDate: _endDate,
        ),
      ),
    );
    if (result == true) {
      setState(() {});
    }
  }

  Future<void> _showIncomeBreakdown(
    int total,
    List<SummaryBreakdownItem> breakdown,
    List<IncomeRecord> incomeRecords,
    List<CategoryGroup> incomeGroups,
  ) async {
    final visibleItems = breakdown.where((item) => item.amount > 0).toList();

    final recordsByGroup = <String, List<IncomeRecord>>{};
    for (final record in incomeRecords) {
      recordsByGroup.putIfAbsent(record.groupId, () => []).add(record);
    }
    for (final records in recordsByGroup.values) {
      records.sort((a, b) => a.date.compareTo(b.date));
    }

    // groupId -> groupName 맵 생성
    final groupNameMap = <String, String>{};
    for (final group in incomeGroups) {
      groupNameMap[group.id] = group.name;
    }
    final unknownRecords = incomeRecords
        .where((record) => !groupNameMap.containsKey(record.groupId))
        .toList();
    unknownRecords.sort((a, b) => a.date.compareTo(b.date));

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '총수입 상세',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '총수입',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${_formatAmount(total)}원',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 그룹별 합계
                  if (visibleItems.isNotEmpty)
                    ...visibleItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item.label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                            Text(
                              '${_formatAmount(item.amount)}원',
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  // 카테고리별 상세 내역 (내부는 날짜 오름차순)
                  Expanded(
                    child: incomeRecords.isEmpty
                        ? Center(
                            child: Text(
                              '등록된 수입이 없습니다',
                              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                            ),
                          )
                        : ListView(
                            controller: scrollController,
                            children: [
                              ...incomeGroups
                                  .where((group) => recordsByGroup[group.id]?.isNotEmpty ?? false)
                                  .map((group) {
                                final records = recordsByGroup[group.id]!;
                                final groupTotal =
                                    records.fold(0, (sum, r) => sum + r.amount);
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              group.name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              '${_formatAmount(groupTotal)}원',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF4CAF50),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ...records.map((record) {
                                          final memo = record.memo?.trim() ?? '';
                                          final dateLabel =
                                              DateFormat('yyyy.MM.dd').format(record.date);
                                          final detailLabel =
                                              memo.isEmpty ? dateLabel : '$dateLabel - $memo';
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      detailLabel,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    Text(
                                                      '${_formatAmount(record.amount)}원',
                                                      style: const TextStyle(fontSize: 13),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              if (unknownRecords.isNotEmpty)
                                Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '알 수 없음',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...unknownRecords.map((record) {
                                          final memo = record.memo?.trim() ?? '';
                                          final dateLabel =
                                              DateFormat('yyyy.MM.dd').format(record.date);
                                          final detailLabel =
                                              memo.isEmpty ? dateLabel : '$dateLabel - $memo';
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      detailLabel,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    Text(
                                                      '${_formatAmount(record.amount)}원',
                                                      style: const TextStyle(fontSize: 13),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _openIncomeInput();
                    },
                    child: const Text('수입 입력'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showSavingBreakdown(
    int total,
    List<SummaryBreakdownItem> breakdown,
    List<SavingRecord> savingRecords,
    List<CategoryGroup> savingGroups,
  ) async {
    final visibleItems = breakdown.where((item) => item.amount > 0).toList();

    final recordsByGroup = <String, List<SavingRecord>>{};
    for (final record in savingRecords) {
      recordsByGroup.putIfAbsent(record.groupId, () => []).add(record);
    }
    for (final records in recordsByGroup.values) {
      records.sort((a, b) => a.date.compareTo(b.date));
    }

    final groupNameMap = <String, String>{};
    for (final group in savingGroups) {
      groupNameMap[group.id] = group.name;
    }
    final unknownRecords = savingRecords
        .where((record) => !groupNameMap.containsKey(record.groupId))
        .toList();
    unknownRecords.sort((a, b) => a.date.compareTo(b.date));

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '총저축 상세',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '총저축',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${_formatAmount(total)}원',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (visibleItems.isNotEmpty)
                    ...visibleItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item.label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                            Text(
                              '${_formatAmount(item.amount)}원',
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: savingRecords.isEmpty
                        ? Center(
                            child: Text(
                              '등록된 저축이 없습니다',
                              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                            ),
                          )
                        : ListView(
                            controller: scrollController,
                            children: [
                              ...savingGroups
                                  .where((group) => recordsByGroup[group.id]?.isNotEmpty ?? false)
                                  .map((group) {
                                final records = recordsByGroup[group.id]!;
                                final groupTotal =
                                    records.fold(0, (sum, r) => sum + r.amount);
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              group.name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              '${_formatAmount(groupTotal)}원',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF2196F3),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ...records.map((record) {
                                          final memo = record.memo?.trim() ?? '';
                                          final dateLabel =
                                              DateFormat('yyyy.MM.dd').format(record.date);
                                          final detailLabel =
                                              memo.isEmpty ? dateLabel : '$dateLabel - $memo';
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      detailLabel,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    Text(
                                                      '${_formatAmount(record.amount)}원',
                                                      style: const TextStyle(fontSize: 13),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              if (unknownRecords.isNotEmpty)
                                Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '알 수 없음',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...unknownRecords.map((record) {
                                          final memo = record.memo?.trim() ?? '';
                                          final dateLabel =
                                              DateFormat('yyyy.MM.dd').format(record.date);
                                          final detailLabel =
                                              memo.isEmpty ? dateLabel : '$dateLabel - $memo';
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      detailLabel,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    Text(
                                                      '${_formatAmount(record.amount)}원',
                                                      style: const TextStyle(fontSize: 13),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _openSavingInput();
                    },
                    child: const Text('저축 입력'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showExpenseBreakdown(
    int total,
    List<SummaryBreakdownItem> breakdown,
    List<Transaction> expenseTransactions,
    List<Category> categories,
  ) async {
    final visibleItems = breakdown.where((item) => item.amount > 0).toList();
    final recordsByCategory = <String, List<Transaction>>{};
    for (final transaction in expenseTransactions) {
      recordsByCategory.putIfAbsent(transaction.categoryId, () => []).add(transaction);
    }
    for (final records in recordsByCategory.values) {
      records.sort((a, b) => a.date.compareTo(b.date));
    }
    final categoryMap = <String, Category>{};
    for (final category in categories) {
      categoryMap[category.id] = category;
    }
    final unknownRecords = expenseTransactions
        .where((transaction) => !categoryMap.containsKey(transaction.categoryId))
        .toList();
    unknownRecords.sort((a, b) => a.date.compareTo(b.date));

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '총지출 상세',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '총지출',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${_formatAmount(total)}원',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (visibleItems.isNotEmpty)
                    ...visibleItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item.label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                            Text(
                              '${_formatAmount(item.amount)}원',
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: expenseTransactions.isEmpty
                        ? Center(
                            child: Text(
                              '등록된 지출이 없습니다',
                              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                            ),
                          )
                        : ListView(
                            controller: scrollController,
                            children: [
                              ...categories
                                  .where((category) =>
                                      recordsByCategory[category.id]?.isNotEmpty ?? false)
                                  .map((category) {
                                final records = recordsByCategory[category.id]!;
                                final categoryTotal =
                                    records.fold(0, (sum, t) => sum + t.amount);
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              category.name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              '${_formatAmount(categoryTotal)}원',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFFFF5252),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ...records.map((transaction) {
                                          final memo = transaction.memo?.trim() ?? '';
                                          final dateLabel =
                                              DateFormat('yyyy.MM.dd')
                                                  .format(transaction.date);
                                          final detailLabel =
                                              memo.isEmpty ? dateLabel : '$dateLabel - $memo';
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      detailLabel,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    Text(
                                                      '${_formatAmount(transaction.amount)}원',
                                                      style: const TextStyle(fontSize: 13),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              if (unknownRecords.isNotEmpty)
                                Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '알 수 없음',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...unknownRecords.map((transaction) {
                                          final memo = transaction.memo?.trim() ?? '';
                                          final dateLabel =
                                              DateFormat('yyyy.MM.dd')
                                                  .format(transaction.date);
                                          final detailLabel =
                                              memo.isEmpty ? dateLabel : '$dateLabel - $memo';
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      detailLabel,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    Text(
                                                      '${_formatAmount(transaction.amount)}원',
                                                      style: const TextStyle(fontSize: 13),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('내역 삭제'),
        content: const Text('이 내역을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await HiveService.deleteTransaction(transaction.id);
      setState(() {});
    }
  }

  Map<String, List<Transaction>> _groupByCategory(List<Transaction> transactions) {
    final grouped = <String, List<Transaction>>{};
    for (final t in transactions) {
      grouped.putIfAbsent(t.categoryId, () => []).add(t);
    }
    for (final entry in grouped.entries) {
      entry.value.sort((a, b) => b.date.compareTo(a.date));
    }
    return grouped;
  }

  Map<DateTime, List<Transaction>> _groupByDay(List<Transaction> transactions) {
    final grouped = <DateTime, List<Transaction>>{};
    for (final t in transactions) {
      final key = DateTime(t.date.year, t.date.month, t.date.day);
      grouped.putIfAbsent(key, () => []).add(t);
    }
    for (final entry in grouped.entries) {
      entry.value.sort((a, b) => a.date.compareTo(b.date));
    }
    return grouped;
  }

  String _formatAmount(int amount) {
    return NumberFormat('#,###').format(amount);
  }

  Widget _buildGroupSection(
    String title,
    List<Category> categories,
    Map<String, List<Transaction>> grouped,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              if (categories.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '카테고리가 없습니다',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                )
              else
                ...categories.map((category) {
                  final items = grouped[category.id] ?? [];
                  final dateGrouped = _groupByDay(items);
                  final dateKeys = dateGrouped.keys.toList()
                    ..sort((a, b) => a.compareTo(b));
                  final total = items.fold(0, (sum, t) => sum + t.amount);
                  final categoryColor = CategoryColorPalette.resolve(
                    category.colorIndex ??
                        CategoryColorPalette.fallbackIndex(category.id),
                  );
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: categoryColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
                      childrenPadding: const EdgeInsets.only(bottom: 8),
                      title: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: categoryColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              category.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 20),
                            onPressed: () => _openQuickAddModal(category),
                          ),
                        ],
                      ),
                      trailing: Text(
                        '${_formatAmount(total)}원',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    children: items.isEmpty
                        ? [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                              child: Text(
                                '내역이 없습니다',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                          ]
                        : [
                            ...dateKeys.expand(
                              (date) {
                                final dateItems = dateGrouped[date] ?? [];
                                return [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                                    child: Text(
                                      DateFormat('yyyy년 MM월 dd일').format(date),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ),
                                  ...dateItems.map(
                                    (t) => TransactionTile(
                                      transaction: t,
                                      showDate: true,
                                      useCategoryColor: false,
                                      onEdit: () => _editTransaction(t),
                                      onDelete: () => _deleteTransaction(t),
                                    ),
                                  ),
                                ];
                              },
                            ),
                          ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openQuickAddModal(Category category) async {
    final amountController = TextEditingController(text: _formatAmount(0));
    final memoController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final items = <TransactionItem>[];

    int itemsTotal() => items.fold(0, (sum, item) => sum + item.amount);

    Future<void> addItem(BuildContext dialogContext, VoidCallback refresh) async {
      final nameController = TextEditingController();
      final itemAmountController = TextEditingController();

      final result = await showDialog<TransactionItem>(
        context: dialogContext,
        builder: (context) => AlertDialog(
          title: const Text('세부내역 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '항목명',
                  hintText: '예: 교통비',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: itemAmountController,
                keyboardType: TextInputType.number,
                inputFormatters: [AmountInputFormatter()],
                decoration: const InputDecoration(
                  labelText: '금액',
                  suffixText: '원',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                final amount = parseAmount(itemAmountController.text);
                if (name.isNotEmpty && amount > 0) {
                  Navigator.pop(
                    context,
                    TransactionItem(name: name, amount: amount),
                  );
                }
              },
              child: const Text('추가'),
            ),
          ],
        ),
      );

      if (result != null) {
        items.add(result);
        amountController.text = _formatAmount(itemsTotal());
        refresh();
      }
    }

    Future<void> pickDate(BuildContext dialogContext, VoidCallback refresh) async {
      final picked = await showDatePicker(
        context: dialogContext,
        initialDate: selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        selectedDate = picked;
        refresh();
      }
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final hasItems = items.isNotEmpty;
            final formattedDate = DateFormat('yyyy년 MM월 dd일').format(selectedDate);

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${category.name} 내역 추가',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context, false),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    readOnly: hasItems,
                    keyboardType: TextInputType.number,
                    inputFormatters: [AmountInputFormatter()],
                    decoration: InputDecoration(
                      labelText: '금액',
                      suffixText: '원',
                      helperText: hasItems ? '세부내역 합산 금액입니다' : null,
                    ),
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => pickDate(context, () => setModalState(() {})),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '날짜',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(formattedDate),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: memoController,
                    decoration: const InputDecoration(
                      labelText: '메모',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('세부내역', style: TextStyle(fontSize: 16)),
                      TextButton.icon(
                        onPressed: () => addItem(context, () => setModalState(() {})),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('추가'),
                      ),
                    ],
                  ),
                  if (items.isNotEmpty)
                    Card(
                      child: Column(
                        children: [
                          ...items.asMap().entries.map(
                                (entry) => ListTile(
                                  dense: true,
                                  title: Text(entry.value.name),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${_formatAmount(entry.value.amount)}원',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 18),
                                        onPressed: () {
                                          items.removeAt(entry.key);
                                          amountController.text =
                                              _formatAmount(itemsTotal());
                                          setModalState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '합계',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${_formatAmount(itemsTotal())}원',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final amount = parseAmount(amountController.text);
                      if (amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('금액을 입력해주세요')),
                        );
                        return;
                      }

                      final transaction = Transaction.create(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        amount: amount,
                        type: TransactionType.expense,
                        categoryId: category.id,
                        memo: memoController.text.isEmpty ? null : memoController.text,
                        date: selectedDate,
                        items: items.isNotEmpty ? List.of(items) : null,
                      );

                      await HiveService.addTransaction(transaction);
                      if (context.mounted) {
                        Navigator.pop(context, true);
                      }
                    },
                    child: const Text('저장'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    amountController.dispose();
    memoController.dispose();

    if (result == true) {
      setState(() {});
    }
  }

  Future<void> _openQuickEditModal(Transaction transaction) async {
    final selectedCategory =
        HiveService.getCategory(transaction.categoryId);
    if (selectedCategory == null) {
      return;
    }
    final groupId = selectedCategory.groupId;
    final allCategories = HiveService.getCategories(
      type: TransactionType.expense,
      groupId: groupId,
    )..sort((a, b) => a.name.compareTo(b.name));
    var currentCategory = selectedCategory;
    final amountController = TextEditingController(text: _formatAmount(transaction.amount));
    final memoController = TextEditingController(text: transaction.memo ?? '');
    DateTime selectedDate = transaction.date;
    final items = <TransactionItem>[...transaction.items];

    int itemsTotal() => items.fold(0, (sum, item) => sum + item.amount);
    if (items.isNotEmpty) {
      amountController.text = _formatAmount(itemsTotal());
    }

    Future<void> addItem(BuildContext dialogContext, VoidCallback refresh) async {
      final nameController = TextEditingController();
      final itemAmountController = TextEditingController();

      final result = await showDialog<TransactionItem>(
        context: dialogContext,
        builder: (context) => AlertDialog(
          title: const Text('세부내역 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '항목명',
                  hintText: '예: 교통비',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: itemAmountController,
                keyboardType: TextInputType.number,
                inputFormatters: [AmountInputFormatter()],
                decoration: const InputDecoration(
                  labelText: '금액',
                  suffixText: '원',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                final amount = parseAmount(itemAmountController.text);
                if (name.isNotEmpty && amount > 0) {
                  Navigator.pop(
                    context,
                    TransactionItem(name: name, amount: amount),
                  );
                }
              },
              child: const Text('추가'),
            ),
          ],
        ),
      );

      if (result != null) {
        items.add(result);
        amountController.text = _formatAmount(itemsTotal());
        refresh();
      }
    }

    Future<void> pickDate(BuildContext dialogContext, VoidCallback refresh) async {
      final picked = await showDatePicker(
        context: dialogContext,
        initialDate: selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        selectedDate = picked;
        refresh();
      }
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final hasItems = items.isNotEmpty;
            final formattedDate = DateFormat('yyyy년 MM월 dd일').format(selectedDate);

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${currentCategory.name} 내역 수정',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context, false),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '카테고리',
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Category>(
                        value: currentCategory,
                        isExpanded: true,
                        items: [
                          for (final category in allCategories)
                            DropdownMenuItem(
                              value: category,
                              child: Text(category.name),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setModalState(() {
                            currentCategory = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    readOnly: hasItems,
                    keyboardType: TextInputType.number,
                    inputFormatters: [AmountInputFormatter()],
                    decoration: InputDecoration(
                      labelText: '금액',
                      suffixText: '원',
                      helperText: hasItems ? '세부내역 합산 금액입니다' : null,
                    ),
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => pickDate(context, () => setModalState(() {})),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '날짜',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(formattedDate),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: memoController,
                    decoration: const InputDecoration(
                      labelText: '메모',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('세부내역', style: TextStyle(fontSize: 16)),
                      TextButton.icon(
                        onPressed: () => addItem(context, () => setModalState(() {})),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('추가'),
                      ),
                    ],
                  ),
                  if (items.isNotEmpty)
                    Card(
                      child: Column(
                        children: [
                          ...items.asMap().entries.map(
                                (entry) => ListTile(
                                  dense: true,
                                  title: Text(entry.value.name),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${_formatAmount(entry.value.amount)}원',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 18),
                                        onPressed: () {
                                          items.removeAt(entry.key);
                                          amountController.text =
                                              _formatAmount(itemsTotal());
                                          setModalState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '합계',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${_formatAmount(itemsTotal())}원',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final amount = parseAmount(amountController.text);
                      if (amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('금액을 입력해주세요')),
                        );
                        return;
                      }

                      final updated = Transaction.create(
                        id: transaction.id,
                        amount: amount,
                        type: transaction.type,
                        categoryId: currentCategory.id,
                        memo: memoController.text.isEmpty ? null : memoController.text,
                        date: selectedDate,
                        items: items.isNotEmpty ? List.of(items) : null,
                      );

                      await HiveService.updateTransaction(updated);
                      if (context.mounted) {
                        Navigator.pop(context, true);
                      }
                    },
                    child: const Text('저장'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    amountController.dispose();
    memoController.dispose();

    if (result == true) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactions = HiveService.getTransactionsByDateRange(_startDate, _endDate)
        .where((t) => t.type == TransactionType.expense)
        .toList();
    final categories = HiveService.getCategories(type: TransactionType.expense)
      ..sort((a, b) => a.name.compareTo(b.name));
    final incomeGroups = HiveService.getCategoryGroups(type: TransactionType.income);
    final expenseGroups = HiveService.getCategoryGroups(type: TransactionType.expense);
    final savingGroups = HiveService.getCategoryGroups(type: TransactionType.saving);
    final incomeRecords = HiveService.getIncomeRecordsByRange(_startDate, _endDate);
    final savingRecords = HiveService.getSavingRecordsByRange(_startDate, _endDate);
    final incomeGroupTotals = <String, int>{};
    for (final record in incomeRecords) {
      incomeGroupTotals[record.groupId] =
          (incomeGroupTotals[record.groupId] ?? 0) + record.amount;
    }
    final savingGroupTotals = <String, int>{};
    for (final record in savingRecords) {
      savingGroupTotals[record.groupId] =
          (savingGroupTotals[record.groupId] ?? 0) + record.amount;
    }
    final expenseGroupTotals = <String, int>{};
    var ungroupedExpenseTotal = 0;
    for (final t in transactions) {
      final category = HiveService.getCategory(t.categoryId);
      final groupId = category?.groupId;
      if (groupId == null) {
        ungroupedExpenseTotal += t.amount;
      } else {
        expenseGroupTotals[groupId] = (expenseGroupTotals[groupId] ?? 0) + t.amount;
      }
    }
    final income = incomeRecords.fold(0, (sum, r) => sum + r.amount);
    final expense = HiveService.getTotalExpenseByDateRange(_startDate, _endDate);
    final saving = savingRecords.fold(0, (sum, r) => sum + r.amount);
    final grouped = _groupByCategory(transactions);

    final expenseBreakdownItems = [
      ...expenseGroups.map(
        (g) => SummaryBreakdownItem(g.name, expenseGroupTotals[g.id] ?? 0),
      ),
      if (ungroupedExpenseTotal > 0) SummaryBreakdownItem('미분류', ungroupedExpenseTotal),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '동댕돈지킴이',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFFF8F9FA),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              if (result == true) {
                await HiveService.ensureRecurringExpenses(_startDate, _endDate);
                if (mounted) {
                  setState(() {});
                }
              }
            },
            tooltip: '설정',
          ),
        ],
      ),
      body: Column(
        children: [
          DateRangeSelector(
            startDate: _startDate,
            endDate: _endDate,
            onSelectRange: _pickDateRange,
          ),
          SummaryCard(
            income: income,
            expense: expense,
            saving: saving,
            onIncomeTap: () => _showIncomeBreakdown(
              income,
              incomeGroups
                  .map((g) => SummaryBreakdownItem(g.name, incomeGroupTotals[g.id] ?? 0))
                  .toList(),
              incomeRecords,
              incomeGroups,
            ),
            onSavingTap: () => _showSavingBreakdown(
              saving,
              savingGroups
                  .map((g) => SummaryBreakdownItem(g.name, savingGroupTotals[g.id] ?? 0))
                  .toList(),
              savingRecords,
              savingGroups,
            ),
            onExpenseTap: () => _showExpenseBreakdown(
              expense,
              expenseBreakdownItems,
              transactions,
              categories,
            ),
            expenseBreakdown: expenseBreakdownItems,
          ),
          Expanded(
            child: categories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          '카테고리가 없습니다',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 80),
                    children: [
                      ...expenseGroups.map((group) {
                        final groupCategories = categories
                            .where((c) => c.groupId == group.id)
                            .toList()
                          ..sort((a, b) => a.name.compareTo(b.name));
                        return _buildGroupSection(group.name, groupCategories, grouped);
                      }),
                      if (categories.any((c) => c.groupId == null))
                        _buildGroupSection(
                          '미분류',
                          categories.where((c) => c.groupId == null).toList(),
                          grouped,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
