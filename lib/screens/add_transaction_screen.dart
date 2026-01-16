import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/category_group.dart';
import '../models/transaction.dart';
import '../models/transaction_item.dart';
import '../models/transaction_type.dart';
import '../services/hive_service.dart';
import '../widgets/category_color_palette.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? transaction;
  final DateTime? initialDate;

  const AddTransactionScreen({
    super.key,
    this.transaction,
    this.initialDate,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();
  Category? _selectedCategory;
  CategoryGroup? _selectedGroup;
  late DateTime _selectedDate;
  final List<TransactionItem> _items = [];

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    if (_isEditing) {
      final t = widget.transaction!;
      _amountController.text = t.amount.toString();
      _memoController.text = t.memo ?? '';
      _selectedDate = t.date;
      _selectedCategory = HiveService.getCategory(t.categoryId);
      if (_selectedCategory?.groupId != null) {
        _selectedGroup = HiveService.getCategoryGroup(_selectedCategory!.groupId!);
      }
      _tabController.index = t.type == TransactionType.income ? 0 : 1;
      _items.addAll(t.items);
    } else {
      _selectedDate = widget.initialDate ?? DateTime.now();
      _selectedGroup = _defaultGroupForType(_currentType);
    }

    _tabController.addListener(() {
      setState(() {
        _selectedCategory = null;
        _selectedGroup = _defaultGroupForType(_currentType);
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  TransactionType get _currentType =>
      _tabController.index == 0 ? TransactionType.income : TransactionType.expense;

  int get _itemsTotal => _items.fold(0, (sum, item) => sum + item.amount);

  CategoryGroup? _defaultGroupForType(TransactionType type) {
    final groups = HiveService.getCategoryGroups(type: type);
    if (groups.isNotEmpty) {
      return groups.first;
    }
    return null;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _addCategory(CategoryGroup group) async {
    final nameController = TextEditingController();
    var selectedColorIndex = 0;
    final name = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${group.name} 카테고리 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '카테고리 이름',
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '색상',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < CategoryColorPalette.colors.length; i++)
                    GestureDetector(
                      onTap: () => setDialogState(() => selectedColorIndex = i),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: CategoryColorPalette.colors[i],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColorIndex == i
                                ? Colors.black87
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, nameController.text),
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );

    if (name != null && name.trim().isNotEmpty) {
      final category = Category(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.trim(),
        type: group.type,
        groupId: group.id,
        colorIndex: selectedColorIndex,
      );
      await HiveService.addCategory(category);
      setState(() {
        _selectedCategory = category;
        _selectedGroup = group;
      });
    }
  }

  Future<void> _addItem() async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();

    final result = await showDialog<TransactionItem>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('세부항목 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '항목명',
                hintText: '예: 과자',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
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
              final amount = int.tryParse(amountController.text) ?? 0;
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
      setState(() {
        _items.add(result);
        _amountController.text = _itemsTotal.toString();
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      if (_items.isNotEmpty) {
        _amountController.text = _itemsTotal.toString();
      }
    });
  }

  Future<void> _save() async {
    final amount = int.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('금액을 입력해주세요')),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카테고리를 선택해주세요')),
      );
      return;
    }

    final transaction = Transaction.create(
      id: _isEditing
          ? widget.transaction!.id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      type: _currentType,
      categoryId: _selectedCategory!.id,
      memo: _memoController.text.isEmpty ? null : _memoController.text,
      date: _selectedDate,
      items: _items.isNotEmpty ? _items : null,
    );

    if (_isEditing) {
      await HiveService.updateTransaction(transaction);
    } else {
      await HiveService.addTransaction(transaction);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  String _formatAmount(int amount) {
    return NumberFormat('#,###').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final groups = HiveService.getCategoryGroups(type: _currentType);
    final ungrouped = HiveService.getUngroupedCategories(type: _currentType);
    final categories = _selectedGroup == null
        ? ungrouped
        : HiveService.getCategories(type: _currentType, groupId: _selectedGroup!.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '내역 수정' : '내역 추가'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '수입'),
            Tab(text: '지출'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: '금액',
                suffixText: '원',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDate,
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
            const Text('분류', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...groups.map(
                  (g) => ChoiceChip(
                    label: Text(g.name),
                    selected: _selectedGroup?.id == g.id,
                    onSelected: (selected) {
                      setState(() {
                        _selectedGroup = selected ? g : _selectedGroup;
                        _selectedCategory = null;
                      });
                    },
                  ),
                ),
                if (ungrouped.isNotEmpty)
                  ChoiceChip(
                    label: const Text('미분류'),
                    selected: _selectedGroup == null,
                    onSelected: (selected) {
                      setState(() {
                        _selectedGroup = null;
                        _selectedCategory = null;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('카테고리', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...categories.map(
                  (c) => ChoiceChip(
                    label: Text(c.name),
                    selected: _selectedCategory?.id == c.id,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? c : null;
                      });
                    },
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('추가'),
                  onPressed: _selectedGroup == null ? null : () => _addCategory(_selectedGroup!),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _memoController,
              decoration: const InputDecoration(
                labelText: '메모 (선택)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('세부항목', style: TextStyle(fontSize: 16)),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('추가'),
                ),
              ],
            ),
            if (_items.isNotEmpty) ...[
              Card(
                child: Column(
                  children: [
                    ..._items.asMap().entries.map(
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
                                  onPressed: () => _removeItem(entry.key),
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
                          const Text('합계', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '${_formatAmount(_itemsTotal)}원',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _isEditing ? '수정' : '저장',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
