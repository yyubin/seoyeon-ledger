import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/transaction_type.dart';
import 'models/category.dart';
import 'models/category_group.dart';
import 'models/fixed_expense_record.dart';
import 'models/income_record.dart';
import 'models/recurring_expense.dart';
import 'models/recurring_interval_type.dart';
import 'models/saving_record.dart';
import 'models/transaction.dart';
import 'models/transaction_item.dart';
import 'screens/home_screen.dart';
import 'services/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(TransactionTypeAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(CategoryGroupAdapter());
  Hive.registerAdapter(IncomeRecordAdapter());
  Hive.registerAdapter(SavingRecordAdapter());
  Hive.registerAdapter(FixedExpenseRecordAdapter());
  Hive.registerAdapter(RecurringIntervalTypeAdapter());
  Hive.registerAdapter(RecurringExpenseAdapter());
  Hive.registerAdapter(TransactionItemAdapter());
  Hive.registerAdapter(TransactionAdapter());

  await Hive.openBox<Category>('categories');
  await Hive.openBox<CategoryGroup>('category_groups');
  await Hive.openBox<IncomeRecord>('income_records');
  await Hive.openBox<SavingRecord>('saving_records');
  await Hive.openBox<FixedExpenseRecord>('fixed_expense_records');
  await Hive.openBox<RecurringExpense>('recurring_expenses');
  await Hive.openBox<Transaction>('transactions');
  await HiveService.ensureDefaultGroups();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '동댕돈지킴이',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Pretendard',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      home: const HomeScreen(),
    );
  }
}
