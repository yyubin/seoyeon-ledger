import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_item.dart';
import '../services/hive_service.dart';
import '../utils/amount_input_formatter.dart';

class FixedExpenseInputScreen extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;

  const FixedExpenseInputScreen({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<FixedExpenseInputScreen> createState() => _FixedExpenseInputScreenState();
}

class _FixedExpenseInputScreenState extends State<FixedExpenseInputScreen> {
  late DateTime _selectedDate;
  List<TransactionItem> _items = [];
  final _memoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadDataForDate(_selectedDate);
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  void _loadDataForDate(DateTime date) {
    final record = HiveService.getFixedExpenseRecordForDate(date);
    if (record != null) {
      _items = List.from(record.items);
      _memoController.text = record.memo ?? '';
    } else {
      _items = [];
      _memoController.text = '';
    }
  }

  int get _totalAmount => _items.fold(0, (sum, item) => sum + item.amount);

  String _formatAmount(int amount) {
    return NumberFormat('#,###').format(amount);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _loadDataForDate(_selectedDate);
      });
    }
  }

  Future<void> _addItem() async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();

    final result = await showDialog<TransactionItem>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('고정비 항목 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '항목명',
                hintText: '예: 관리비, 통신비, 보험료',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
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
              final amount = parseAmount(amountController.text);
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

    nameController.dispose();
    amountController.dispose();

    if (result != null) {
      setState(() {
        _items.add(result);
      });
    }
  }

  Future<void> _editItem(int index) async {
    final item = _items[index];
    final nameController = TextEditingController(text: item.name);
    final amountController = TextEditingController(text: _formatAmount(item.amount));

    final result = await showDialog<TransactionItem>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('항목 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '항목명',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
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
              final amount = parseAmount(amountController.text);
              if (name.isNotEmpty && amount > 0) {
                Navigator.pop(
                  context,
                  TransactionItem(name: name, amount: amount),
                );
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );

    nameController.dispose();
    amountController.dispose();

    if (result != null) {
      setState(() {
        _items[index] = result;
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (_items.isEmpty) {
      await HiveService.deleteFixedExpenseRecordForDate(_selectedDate);
    } else {
      final memo = _memoController.text.trim();
      await HiveService.upsertFixedExpenseRecord(
        _selectedDate,
        _totalAmount,
        _items,
        memo: memo.isEmpty ? null : memo,
      );
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('고정비 입력'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: '날짜',
                border: OutlineInputBorder(),
              ),
              child: Text(
                DateFormat('yyyy년 MM월 dd일').format(_selectedDate),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '고정비 항목',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('항목 추가'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              '고정비 항목이 없습니다',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '관리비, 통신비, 보험료 등을 추가하세요',
                              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        ..._items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.name),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${_formatAmount(item.amount)}원',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  onPressed: () => _editItem(index),
                                  color: Colors.grey[600],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () => _removeItem(index),
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          );
                        }),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '합계',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_formatAmount(_totalAmount)}원',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE53935),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _memoController,
            decoration: const InputDecoration(
              labelText: '메모',
              hintText: '메모를 입력하세요 (선택)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _save,
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}
