import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/transaction_item.dart';
import '../models/transaction_type.dart';
import '../services/hive_service.dart';
import '../widgets/category_color_palette.dart';
import '../widgets/date_range_selector.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_tile.dart';
import 'income_input_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await HiveService.ensureRecurringExpenses(_startDate, _endDate);
      if (mounted) {
        setState(() {});
      }
    });
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

  Future<void> _showIncomeBreakdown(
    int total,
    List<SummaryBreakdownItem> breakdown,
  ) async {
    final visibleItems = breakdown.where((item) => item.amount > 0).toList();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
              if (visibleItems.isEmpty)
                Text(
                  '등록된 수입이 없습니다',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                )
              else
                ...visibleItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item.label, style: const TextStyle(fontSize: 13)),
                        Text(
                          '${_formatAmount(item.amount)}원',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
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
      entry.value.sort((a, b) => b.date.compareTo(a.date));
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
                    ..sort((a, b) => b.compareTo(a));
                  final total = items.fold(0, (sum, t) => sum + t.amount);
                  return ExpansionTile(
                    tilePadding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            category.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: CategoryColorPalette.resolve(
                              category.colorIndex ??
                                  CategoryColorPalette.fallbackIndex(category.id),
                            ),
                            shape: BoxShape.circle,
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
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
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
                            ...dateKeys.map(
                              (date) {
                                final dateItems = dateGrouped[date] ?? [];
                                return ExpansionTile(
                                  tilePadding:
                                      const EdgeInsets.fromLTRB(16, 4, 8, 4),
                                  childrenPadding: const EdgeInsets.only(bottom: 8),
                                  title: Text(
                                    DateFormat('yyyy년 MM월 dd일').format(date),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  children: [
                                    ...dateItems.map(
                                      (t) => TransactionTile(
                                        transaction: t,
                                        onEdit: () => _editTransaction(t),
                                        onDelete: () => _deleteTransaction(t),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openQuickAddModal(Category category) async {
    final amountController = TextEditingController(text: '0');
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
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                final amount = int.tryParse(itemAmountController.text) ?? 0;
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
        amountController.text = itemsTotal().toString();
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
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                                              itemsTotal().toString();
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
                      final amount = int.tryParse(amountController.text) ?? 0;
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
    final amountController = TextEditingController(text: transaction.amount.toString());
    final memoController = TextEditingController(text: transaction.memo ?? '');
    DateTime selectedDate = transaction.date;
    final items = <TransactionItem>[...transaction.items];

    int itemsTotal() => items.fold(0, (sum, item) => sum + item.amount);
    if (items.isNotEmpty) {
      amountController.text = itemsTotal().toString();
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
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                final amount = int.tryParse(itemAmountController.text) ?? 0;
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
        amountController.text = itemsTotal().toString();
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
                        value: selectedCategory,
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
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                                              itemsTotal().toString();
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
                      final amount = int.tryParse(amountController.text) ?? 0;
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
    final incomeRecords = HiveService.getIncomeRecordsByRange(_startDate, _endDate);
    final incomeGroupTotals = <String, int>{};
    for (final record in incomeRecords) {
      incomeGroupTotals[record.groupId] =
          (incomeGroupTotals[record.groupId] ?? 0) + record.amount;
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
    final grouped = _groupByCategory(transactions);

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
            onIncomeTap: () => _showIncomeBreakdown(
              income,
              incomeGroups
                  .map((g) => SummaryBreakdownItem(g.name, incomeGroupTotals[g.id] ?? 0))
                  .toList(),
            ),
            incomeBreakdown: const [],
            expenseBreakdown: [
              ...expenseGroups.map(
                (g) => SummaryBreakdownItem(g.name, expenseGroupTotals[g.id] ?? 0),
              ),
              if (ungroupedExpenseTotal > 0)
                SummaryBreakdownItem('미분류', ungroupedExpenseTotal),
            ],
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
