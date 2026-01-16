import 'package:flutter/material.dart';

class MonthSelector extends StatelessWidget {
  final int year;
  final int month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const MonthSelector({
    super.key,
    required this.year,
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            onPressed: onPrevious,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$year년 $month월',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3436),
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 28),
            onPressed: onNext,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }
}
