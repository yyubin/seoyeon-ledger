import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/transaction_type.dart';
import '../services/hive_service.dart';
import 'category_color_palette.dart';

class TransactionTile extends StatefulWidget {
  final Transaction transaction;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<TransactionTile> {
  bool _expanded = false;

  String _formatAmount(int amount) {
    return NumberFormat('#,###').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    final category = HiveService.getCategory(transaction.categoryId);
    final isIncome = transaction.type == TransactionType.income;
    final hasItems = transaction.hasItems;
    final categoryColor = CategoryColorPalette.resolve(
      category?.colorIndex ?? CategoryColorPalette.fallbackIndex(transaction.categoryId),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: categoryColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: hasItems ? () => setState(() => _expanded = !_expanded) : null,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
                      color: isIncome ? const Color(0xFF4CAF50) : const Color(0xFFFF5252),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                category?.name ?? '(삭제된 카테고리)',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2D3436),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasItems) ...[
                              const SizedBox(width: 4),
                              Icon(
                                _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                size: 20,
                                color: Colors.grey[400],
                              ),
                            ],
                          ],
                        ),
                        if (transaction.memo?.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            transaction.memo!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${isIncome ? '+' : '-'}${_formatAmount(transaction.amount)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isIncome ? const Color(0xFF4CAF50) : const Color(0xFFFF5252),
                    ),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: Colors.grey[400], size: 20),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (value) {
                      if (value == 'edit') {
                        widget.onEdit?.call();
                      } else if (value == 'delete') {
                        widget.onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('수정'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('삭제', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (hasItems && _expanded)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: transaction.items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '${_formatAmount(item.amount)}원',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
