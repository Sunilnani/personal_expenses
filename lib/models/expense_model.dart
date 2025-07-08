// lib/models/expense.dart
import 'package:flutter/foundation.dart';

enum ExpenseType { Room, Personal }

class Expense {
  final ExpenseType type;
  final String category;
  final String name;
  final double price;
  final DateTime date;
  final String? imagePath;

  const Expense({
    required this.type,
    required this.category,
    required this.name,
    required this.price,
    required this.date,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
    'type': describeEnum(type),
    'category': category,
    'name': name,
    'price': price,
    'date': date.toIso8601String(),
    'imagePath': imagePath,
  };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    type: ExpenseType.values
        .firstWhere((e) => describeEnum(e) == json['type']),
    category: json['category'] as String,
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(),
    date: DateTime.parse(json['date'] as String),
    imagePath: json['imagePath'] as String?,
  );
}
