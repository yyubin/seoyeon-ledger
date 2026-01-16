import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SummaryCard extends StatelessWidget {
  final int income;
  final int expense;
  final VoidCallback? onIncomeTap;
  final List<SummaryBreakdownItem> incomeBreakdown;
  final List<SummaryBreakdownItem> expenseBreakdown;

  const SummaryCard({
    super.key,
    required this.income,
    required this.expense,
    this.onIncomeTap,
    this.incomeBreakdown = const [],
    this.expenseBreakdown = const [],
  });

  String _formatAmount(int amount) {
    return NumberFormat('#,###').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final balance = income - expense;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C63FF), Color(0xFF8B85FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Text(
              '잔액 ${_formatAmount(balance)}원',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildItem(
                '총수입',
                income,
                Colors.white.withValues(alpha: 0.9),
                onIncomeTap,
                incomeBreakdown,
              ),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 8),
              _buildItem(
                '총지출',
                expense,
                Colors.white.withValues(alpha: 0.9),
                null,
                expenseBreakdown,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    String label,
    int amount,
    Color color,
    VoidCallback? onTap,
    List<SummaryBreakdownItem> breakdown,
  ) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_formatAmount(amount)}원',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        if (breakdown.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...breakdown.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_formatAmount(item.amount)}원',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );

    if (onTap == null) {
      return Expanded(child: content);
    }

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: content,
        ),
      ),
    );
  }
}

class SummaryBreakdownItem {
  final String label;
  final int amount;

  const SummaryBreakdownItem(this.label, this.amount);
}
