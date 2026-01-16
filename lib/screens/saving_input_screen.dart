import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category_group.dart';
import '../models/saving_record.dart';
import '../models/transaction_type.dart';
import '../services/hive_service.dart';
import '../utils/amount_input_formatter.dart';

class SavingInputScreen extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;

  const SavingInputScreen({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<SavingInputScreen> createState() => _SavingInputScreenState();
}

class _SavingInputScreenState extends State<SavingInputScreen> {
  late List<CategoryGroup> _groups;
  final Map<String, List<SavingRecord>> _recordsByGroup = {};
  late DateTime _selectedDate;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _groups = HiveService.getCategoryGroups(type: TransactionType.saving);
    _selectedDate = DateTime.now();
    _loadRecordsForDate(_selectedDate);
  }

  void _reloadGroups() {
    _groups = HiveService.getCategoryGroups(type: TransactionType.saving);
    _loadRecordsForDate(_selectedDate);
  }

  Future<void> _addCategory() async {
    final nameController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('저축 카테고리 추가'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '카테고리 이름',
            hintText: '예: 여행자금, 결혼자금',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, name);
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );

    nameController.dispose();

    if (result != null && result.isNotEmpty) {
      final exists = _groups.any((g) => g.name == result);
      if (exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미 존재하는 카테고리입니다')),
          );
        }
        return;
      }

      final newGroup = CategoryGroup(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: result,
        type: TransactionType.saving,
        order: _groups.length,
      );
      await HiveService.addCategoryGroup(newGroup);

      setState(() {
        _changed = true;
        _reloadGroups();
      });
    }
  }

  Future<void> _deleteCategory(CategoryGroup group) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('카테고리 삭제'),
        content: Text('\'${group.name}\' 카테고리를 삭제할까요?\n이 카테고리의 저축 기록은 유지됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await HiveService.deleteCategoryGroup(group.id);
      setState(() {
        _changed = true;
        _reloadGroups();
      });
    }
  }

  @override
  void _loadRecordsForDate(DateTime date) {
    _recordsByGroup.clear();
    for (final group in _groups) {
      _recordsByGroup[group.id] =
          HiveService.getSavingRecordsForGroupAndDate(group.id, date);
    }
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
        _loadRecordsForDate(_selectedDate);
      });
    }
  }

  Future<void> _close() async {
    if (mounted) {
      Navigator.pop(context, _changed);
    }
  }

  String _formatAmount(int amount) {
    return NumberFormat('#,###').format(amount);
  }

  Future<void> _openRecordEditor(CategoryGroup group, {SavingRecord? record}) async {
    final amountController = TextEditingController(
      text: record == null ? '' : _formatAmount(record.amount),
    );
    final memoController = TextEditingController(text: record?.memo ?? '');
    final isEditing = record != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEditing ? '저축 내역 수정' : '저축 내역 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [AmountInputFormatter()],
              decoration: const InputDecoration(
                labelText: '금액',
                suffixText: '원',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: memoController,
              decoration: const InputDecoration(
                labelText: '메모',
                hintText: '메모를 입력하세요 (선택)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final amount = parseAmount(amountController.text);
              if (amount <= 0) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('금액을 입력해주세요')),
                  );
                }
                return;
              }
              final memo = memoController.text.trim();
              if (isEditing) {
                await HiveService.updateSavingRecord(
                  record!,
                  amount: amount,
                  memo: memo.isEmpty ? null : memo,
                );
              } else {
                await HiveService.addSavingRecord(
                  group.id,
                  _selectedDate,
                  amount,
                  memo: memo.isEmpty ? null : memo,
                );
              }
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );

    amountController.dispose();
    memoController.dispose();

    if (result == true && mounted) {
      setState(() {
        _changed = true;
        _recordsByGroup[group.id] =
            HiveService.getSavingRecordsForGroupAndDate(group.id, _selectedDate);
      });
    }
  }

  Future<void> _deleteRecord(CategoryGroup group, SavingRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('내역 삭제'),
        content: const Text('해당 내역을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await HiveService.deleteSavingRecord(record.id);
      if (mounted) {
        setState(() {
          _changed = true;
          _recordsByGroup[group.id] =
              HiveService.getSavingRecordsForGroupAndDate(group.id, _selectedDate);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _changed);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('저축 입력'),
          actions: [
            IconButton(
              onPressed: _addCategory,
              icon: const Icon(Icons.add),
              tooltip: '카테고리 추가',
            ),
          ],
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
            ..._groups.map((group) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  group.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _deleteCategory(group),
                                icon: const Icon(Icons.delete_outline, size: 20),
                                tooltip: '카테고리 삭제',
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ..._buildRecordList(group),
                          TextButton.icon(
                            onPressed: () => _openRecordEditor(group),
                            icon: const Icon(Icons.add),
                            label: const Text('내역 추가'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
            if (_groups.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.savings_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        '저축 카테고리가 없습니다',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _addCategory,
                        icon: const Icon(Icons.add),
                        label: const Text('카테고리 추가'),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _groups.isEmpty ? null : _close,
              child: const Text('완료'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRecordList(CategoryGroup group) {
    final records = _recordsByGroup[group.id] ?? [];
    if (records.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '등록된 내역이 없습니다',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ),
      ];
    }

    return records.map((record) {
      final memo = record.memo?.trim() ?? '';
      return InkWell(
        onTap: () => _openRecordEditor(group, record: record),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_formatAmount(record.amount)}원',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    if (memo.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          memo,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _deleteRecord(group, record),
                icon: const Icon(Icons.delete_outline, size: 18),
                tooltip: '내역 삭제',
                color: Colors.grey[600],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
