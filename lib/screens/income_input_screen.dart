import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/category_group.dart';
import '../models/transaction_type.dart';
import '../services/hive_service.dart';

class IncomeInputScreen extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;

  const IncomeInputScreen({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<IncomeInputScreen> createState() => _IncomeInputScreenState();
}

class _IncomeInputScreenState extends State<IncomeInputScreen> {
  late final List<CategoryGroup> _groups;
  final Map<String, TextEditingController> _controllers = {};
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _groups = HiveService.getCategoryGroups(type: TransactionType.income);
    _selectedDate = DateTime.now();
    _loadAmountsForDate(_selectedDate);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _loadAmountsForDate(DateTime date) {
    for (final group in _groups) {
      final record = HiveService.getIncomeRecordForGroupAndDate(group.id, date);
      final amount = record?.amount ?? 0;
      _controllers[group.id] = TextEditingController(
        text: amount == 0 ? '' : amount.toString(),
      );
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
        for (final controller in _controllers.values) {
          controller.dispose();
        }
        _controllers.clear();
        _loadAmountsForDate(_selectedDate);
      });
    }
  }

  Future<void> _save() async {
    for (final group in _groups) {
      final controller = _controllers[group.id]!;
      final amount = int.tryParse(controller.text) ?? 0;
      if (amount > 0) {
        await HiveService.upsertIncomeRecord(
          group.id,
          _selectedDate,
          amount,
        );
      } else {
        await HiveService.deleteIncomeRecordForGroupAndDate(group.id, _selectedDate);
      }
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('수입 입력'),
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
                child: TextField(
                  controller: _controllers[group.id],
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: group.name,
                    suffixText: '원',
                  ),
                ),
              )),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _save,
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}
