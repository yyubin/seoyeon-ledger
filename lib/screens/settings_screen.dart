import 'package:flutter/material.dart';
import 'category_screen.dart';
import 'recurring_expense_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _changed = false;

  Future<void> _openCategory() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const CategoryScreen()),
    );
    if (result == true) {
      _changed = true;
    }
  }

  Future<void> _openRecurring() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const RecurringExpenseScreen()),
    );
    if (result == true) {
      _changed = true;
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
          title: const Text('설정'),
        ),
        body: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('카테고리 관리'),
              onTap: _openCategory,
            ),
            ListTile(
              leading: const Icon(Icons.repeat_rounded),
              title: const Text('고정비/반복지출 관리'),
              onTap: _openRecurring,
            ),
          ],
        ),
      ),
    );
  }
}
