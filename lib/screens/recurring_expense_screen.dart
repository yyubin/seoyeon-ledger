import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/recurring_expense.dart';
import '../models/recurring_interval_type.dart';
import '../models/transaction_type.dart';
import '../services/hive_service.dart';
import '../utils/amount_input_formatter.dart';

class RecurringExpenseScreen extends StatefulWidget {
  const RecurringExpenseScreen({super.key});

  @override
  State<RecurringExpenseScreen> createState() => _RecurringExpenseScreenState();
}

class _RecurringExpenseScreenState extends State<RecurringExpenseScreen> {
  bool _changed = false;

  String _scheduleLabel(RecurringExpense expense) {
    switch (expense.intervalType) {
      case RecurringIntervalType.monthly:
        return '매월 ${expense.dayOfMonth ?? 1}일';
      case RecurringIntervalType.weekly:
        return '매주 ${_weekdayLabel(expense.weekday ?? 1)}';
      case RecurringIntervalType.intervalDays:
        return '${expense.intervalDays ?? 1}일마다';
    }
  }

  String _weekdayLabel(int weekday) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    final index = (weekday - 1) % labels.length;
    return labels[index];
  }

  Future<void> _openEditor({RecurringExpense? existing}) async {
    final categories = HiveService.getCategories(type: TransactionType.expense);
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 지출 카테고리를 추가해주세요')),
      );
      return;
    }

    final amountController = TextEditingController(
      text: existing == null ? '' : NumberFormat('#,###').format(existing.amount),
    );
    final memoController = TextEditingController(text: existing?.memo ?? '');
    var selectedCategory =
        categories.firstWhere((c) => c.id == existing?.categoryId, orElse: () => categories.first);
    var intervalType = existing?.intervalType ?? RecurringIntervalType.monthly;
    var startDate = DateTime.fromMillisecondsSinceEpoch(
      existing?.startTimestamp ?? DateTime.now().millisecondsSinceEpoch,
    );
    var dayOfMonth = existing?.dayOfMonth ?? startDate.day;
    var weekday = existing?.weekday ?? startDate.weekday;
    var intervalDays = existing?.intervalDays ?? 7;
    var isActive = existing?.isActive ?? true;

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
                          existing == null ? '고정비 추가' : '고정비 수정',
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
                    keyboardType: TextInputType.number,
                    inputFormatters: [AmountInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: '금액',
                      suffixText: '원',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '카테고리',
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Category>(
                        value: selectedCategory,
                        isExpanded: true,
                        items: [
                          for (final category in categories)
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
                            selectedCategory = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '주기',
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<RecurringIntervalType>(
                        value: intervalType,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: RecurringIntervalType.monthly,
                            child: Text('매월'),
                          ),
                          DropdownMenuItem(
                            value: RecurringIntervalType.weekly,
                            child: Text('매주'),
                          ),
                          DropdownMenuItem(
                            value: RecurringIntervalType.intervalDays,
                            child: Text('N일마다'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setModalState(() {
                            intervalType = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (intervalType == RecurringIntervalType.monthly)
                    TextField(
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: '매월 기준일 (1~31)',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(
                        text: dayOfMonth.toString(),
                      ),
                      onChanged: (value) {
                        final parsed = int.tryParse(value) ?? 1;
                        dayOfMonth = parsed.clamp(1, 31);
                      },
                    ),
                  if (intervalType == RecurringIntervalType.weekly)
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '요일',
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: weekday,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('월요일')),
                            DropdownMenuItem(value: 2, child: Text('화요일')),
                            DropdownMenuItem(value: 3, child: Text('수요일')),
                            DropdownMenuItem(value: 4, child: Text('목요일')),
                            DropdownMenuItem(value: 5, child: Text('금요일')),
                            DropdownMenuItem(value: 6, child: Text('토요일')),
                            DropdownMenuItem(value: 7, child: Text('일요일')),
                          ],
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setModalState(() {
                              weekday = value;
                            });
                          },
                        ),
                      ),
                    ),
                  if (intervalType == RecurringIntervalType.intervalDays)
                    TextField(
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: '간격 (일)',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(
                        text: intervalDays.toString(),
                      ),
                      onChanged: (value) {
                        final parsed = int.tryParse(value) ?? 1;
                        intervalDays = parsed < 1 ? 1 : parsed;
                      },
                    ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setModalState(() {
                          startDate = picked;
                          dayOfMonth = picked.day;
                          weekday = picked.weekday;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '시작일',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(DateFormat('yyyy년 MM월 dd일').format(startDate)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: memoController,
                    decoration: const InputDecoration(
                      labelText: '메모',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('사용'),
                    value: isActive,
                    onChanged: (value) {
                      setModalState(() {
                        isActive = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final amount = parseAmount(amountController.text);
                      if (amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('금액을 입력해주세요')),
                        );
                        return;
                      }

                      final startAt = DateTime(
                        startDate.year,
                        startDate.month,
                        startDate.day,
                      ).millisecondsSinceEpoch;
                      final expense = RecurringExpense(
                        id: existing?.id ??
                            DateTime.now().microsecondsSinceEpoch.toString(),
                        name: selectedCategory.name,
                        amount: amount,
                        categoryId: selectedCategory.id,
                        memo: memoController.text.isEmpty ? null : memoController.text,
                        intervalType: intervalType,
                        dayOfMonth: intervalType == RecurringIntervalType.monthly
                            ? dayOfMonth
                            : null,
                        weekday: intervalType == RecurringIntervalType.weekly
                            ? weekday
                            : null,
                        intervalDays:
                            intervalType == RecurringIntervalType.intervalDays
                                ? intervalDays
                                : null,
                        startTimestamp: startAt,
                        nextRunTimestamp: null,
                        isActive: isActive,
                      );

                      if (existing == null) {
                        await HiveService.addRecurringExpense(expense);
                      } else {
                        await HiveService.updateRecurringExpense(expense);
                      }

                      if (context.mounted) {
                        Navigator.pop(context, true);
                      }
                    },
                    child: const Text('저장'),
                  ),
                  if (existing != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        await HiveService.deleteRecurringExpense(existing.id);
                        if (context.mounted) {
                          Navigator.pop(context, true);
                        }
                      },
                      child: const Text(
                        '삭제',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
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
      _changed = true;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenses = HiveService.getRecurringExpenses();

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _changed);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('고정비/반복지출 관리'),
        ),
        body: expenses.isEmpty
            ? Center(
                child: Text(
                  '등록된 고정비가 없습니다',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              )
            : ListView.builder(
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final expense = expenses[index];
                  final category = HiveService.getCategory(expense.categoryId);
                  final categoryName = category?.name ?? '알 수 없음';
                  final nextRun = expense.nextRunTimestamp == null
                      ? DateTime.fromMillisecondsSinceEpoch(expense.startTimestamp)
                      : DateTime.fromMillisecondsSinceEpoch(expense.nextRunTimestamp!);
                  return ListTile(
                    title: Text(categoryName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_scheduleLabel(expense)} · 다음 ${DateFormat('yyyy.MM.dd').format(nextRun)}',
                        ),
                        if (expense.memo != null && expense.memo!.isNotEmpty)
                          Text(
                            expense.memo!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                    trailing: Text(
                      '${NumberFormat('#,###').format(expense.amount)}원',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () => _openEditor(existing: expense),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openEditor(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
