/// Model for a friend expense with unique ID
class FriendExpense {
  final String id;
  final String name;
  final String reason;
  final double amount;
  final DateTime date;
  String? imagePath; // Optional receipt image path

  FriendExpense({
    required this.id,
    required this.name,
    required this.reason,
    required this.amount,
    required this.date,
    this.imagePath,
  });

  factory FriendExpense.fromJson(Map<String, dynamic> json) => FriendExpense(
    id: json['id'] as String,
    name: json['name'] as String,
    reason: json['reason'] as String,
    amount: (json['amount'] as num).toDouble(),
    date: DateTime.parse(json['date'] as String),
    imagePath: json['imagePath'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'reason': reason,
    'amount': amount,
    'date': date.toIso8601String(),
    'imagePath': imagePath,
  };
}

/// Summary total for a friend
class FriendTotal {
  final String name;
  final double total;
  FriendTotal(this.name, this.total);
}



//
// /// Model for a friend expense
// class FriendExpense {
//   final String name;
//   final String reason;
//   final double amount;
//   final DateTime date;
//   String? imagePath; // Optional receipt image path
//
//   FriendExpense({
//     required this.name,
//     required this.reason,
//     required this.amount,
//     required this.date,
//     this.imagePath,
//   });
//
//   factory FriendExpense.fromJson(Map<String, dynamic> json) => FriendExpense(
//     name: json['name'],
//     reason: json['reason'],
//     amount: (json['amount'] as num).toDouble(),
//     date: DateTime.parse(json['date']),
//     imagePath: json['imagePath'] as String?,
//   );
//
//   Map<String, dynamic> toJson() => {
//     'name': name,
//     'reason': reason,
//     'amount': amount,
//     'date': date.toIso8601String(),
//     'imagePath': imagePath,
//   };
// }
//
// /// Summary total for a friend
// class FriendTotal {
//   final String name;
//   final double total;
//   FriendTotal(this.name, this.total);
// }