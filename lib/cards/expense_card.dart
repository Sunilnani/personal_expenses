// lib/widgets/expense_card.dart
import 'package:flutter/material.dart';

class ExpenseCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final VoidCallback onTap;

  const ExpenseCard({
    super.key,
    required this.title,
    required this.amount,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('₹${amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 28)),
            ],
          ),
        ),
      ),
    );
  }
}
