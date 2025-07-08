// lib/screens/friend_expense_detail_page.dart
import 'dart:io';
import 'package:expenses_tracker/models/friend_expense_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import 'package:expenses_tracker/pages/friend/add_friend_expenses_page.dart';
import '../../providers/expense_provider.dart';

/// Shows detailed expenses for a single friend with PDF export/share
class FriendExpenseDetailPage extends StatelessWidget {
  final String friendName;
  const FriendExpenseDetailPage({Key? key, required this.friendName})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ExpenseProvider>();
    final list = prov.expensesForFriend(friendName);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          friendName,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Export to PDF',
            onPressed: () => _exportPdf(context, list),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: list.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'No expenses for $friendName yet',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        )
            : ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) {
            final e = list[i];
            final bgColor = e.amount < 100
                ? Colors.green.shade50
                : e.amount < 500
                ? Colors.blue.shade50
                : e.amount < 1000
                ? Colors.orange.shade50
                : Colors.pink.shade50;
            return Card(
              color: bgColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (e.imagePath != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(e.imagePath!),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                    if (e.imagePath != null) const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.reason,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat.yMMMd().add_jm().format(e.date),
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2)),
                        ],
                      ),
                      child: Text(
                        '₹${e.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addExpense(context),
        child: const Icon(Icons.add),
        tooltip: 'Add Expense',
      ),
    );
  }

  void _addExpense(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddFriendExpensePage(defaultFriend: friendName),
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context, List<FriendExpense> list) async {
    final doc = pw.Document();
    final total = list.fold<double>(0, (sum, e) => sum + e.amount);
    final now = DateTime.now();
    final dateStr = DateFormat.yMMMd().add_jm().format(now);

    final headers = ['Date', 'Reason', 'Amount'];
    final data = list
        .map((e) => [
      DateFormat.yMMMd().add_jm().format(e.date),
      e.reason,
      '₹${e.amount.toStringAsFixed(2)}',
    ])
        .toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
              level: 0,
              child: pw.Text('Expense Report: $friendName',
                  style: pw.TextStyle(fontSize: 18))),
          pw.Paragraph(text: 'Generated on $dateStr'),
          pw.Table.fromTextArray(headers: headers, data: data),
          pw.SizedBox(height: 12),
          pw.Text('Total Amount: ₹${total.toStringAsFixed(2)}',
              style: pw.TextStyle(
                  fontSize: 16, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );

    final bytes = await doc.save();
    await Printing.sharePdf(bytes: bytes, filename: '$friendName-expenses.pdf');
  }
}




// // lib/screens/friend_expense_detail_page.dart
// import 'dart:io';
// import 'package:expenses_tracker/pages/friend/add_friend_expenses_page.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// import '../../providers/expense_provider.dart';
//
// /// Shows detailed expenses for a single friend with polished cards
// class FriendExpenseDetailPage extends StatelessWidget {
//   final String friendName;
//   const FriendExpenseDetailPage({Key? key, required this.friendName})
//     : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final prov = context.watch<ExpenseProvider>();
//     final list = prov.expensesForFriend(friendName);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           friendName,
//           style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child:
//             list.isEmpty
//                 ? Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Icon(
//                         Icons.history,
//                         size: 64,
//                         color: Colors.grey.shade300,
//                       ),
//                       const SizedBox(height: 16),
//                       Text(
//                         'No expenses for $friendName yet',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                       const SizedBox(height: 24),
//                       // ElevatedButton.icon(
//                       //   onPressed: () => _addExpense(context),
//                       //   icon: const Icon(Icons.add),
//                       //   label: const Text('Add Expense'),
//                       //   style: ElevatedButton.styleFrom(
//                       //     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                       //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                       //   ),
//                       // ),
//                     ],
//                   ),
//                 )
//                 : ListView.separated(
//                   itemCount: list.length,
//                   separatorBuilder: (_, __) => const SizedBox(height: 12),
//                   itemBuilder: (ctx, i) {
//                     final e = list[i];
//                     // Choose a light color based on amount
//                     final bgColor =
//                         e.amount < 100
//                             ? Colors.green.shade50
//                             : e.amount < 500
//                             ? Colors.blue.shade50
//                             : e.amount < 1000
//                             ? Colors.orange.shade50
//                             : Colors.pink.shade50;
//
//                     return Card(
//                       color: bgColor,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       elevation: 2,
//                       child: Padding(
//                         padding: const EdgeInsets.all(16),
//                         child: Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             if (e.imagePath != null)
//                               ClipRRect(
//                                 borderRadius: BorderRadius.circular(8),
//                                 child: Image.file(
//                                   File(e.imagePath!),
//                                   width: 60,
//                                   height: 60,
//                                   fit: BoxFit.cover,
//                                 ),
//                               ),
//                             // else
//                             //   Container(
//                             //     width: 60,
//                             //     height: 60,
//                             //     decoration: BoxDecoration(
//                             //       color: Colors.grey.shade200,
//                             //       borderRadius: BorderRadius.circular(8),
//                             //     ),
//                             //     child: const Icon(Icons.receipt_long, color: Colors.grey),
//                             //   ),
//                             if (e.imagePath != null) const SizedBox(width: 16),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     e.reason,
//                                     style: const TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 4),
//                                   Text(
//                                     DateFormat.yMMMd().add_jm().format(e.date),
//                                     style: TextStyle(
//                                       color: Colors.grey.shade600,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 12,
//                                 vertical: 8,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(8),
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: Colors.black12,
//                                     blurRadius: 4,
//                                     offset: const Offset(0, 2),
//                                   ),
//                                 ],
//                               ),
//                               child: Text(
//                                 '₹${e.amount.toStringAsFixed(2)}',
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _addExpense(context),
//         child: Icon(Icons.add),
//         tooltip: 'Add Expense',
//       ),
//     );
//   }
//
//   void _addExpense(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => AddFriendExpensePage(defaultFriend: friendName),
//       ),
//     );
//   }
// }
