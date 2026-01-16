import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateRangeSelector extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onSelectRange;

  const DateRangeSelector({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onSelectRange,
  });

  String _formatDate(DateTime date) {
    return DateFormat('yyyy.MM.dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onSelectRange,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.date_range_rounded, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${_formatDate(startDate)} ~ ${_formatDate(endDate)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3436),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
