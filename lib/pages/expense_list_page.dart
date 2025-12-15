
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import 'add_expense_page.dart';

class ExpenseListPage extends StatefulWidget {
  final ExpenseType type;
  const ExpenseListPage({Key? key, required this.type}) : super(key: key);

  @override
  State<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  DateTime selectedMonth = DateTime.now();

  Color _colorForPrice(double price) {
    if (price < 100) {
      return Colors.green.shade50;
    } else if (price < 500) {
      return Colors.blue.shade50;
    } else if (price < 1000) {
      return Colors.orange.shade50;
    } else {
      return Colors.pink.shade50;
    }
  }

  void _showImageDialog(String imagePath) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 1.0,
              maxScale: 4.0,
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select Month',
    );
    if (picked != null) {
      setState(() => selectedMonth = DateTime(picked.year, picked.month));
    }
  }

  Future<void> _exportPdf(List<Expense> list) async {
    final doc = pw.Document();
    final total = list.fold<double>(0, (sum, e) => sum + e.price);
    final now = DateTime.now();
    final dateStr = DateFormat.yMMMd().add_jm().format(now);

    final headers = ['Name', 'Category', 'Date/Time', 'Amount'];
    final data = list.map((e) => [
      e.name,
      e.category,
      '${DateFormat.yMMMd().format(e.date)} ${DateFormat.jm().format(e.date)}',
      '₹${e.price.toStringAsFixed(2)}',
    ]).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              '${widget.type == ExpenseType.Room ? 'Room' : 'Personal'} Expenses Report',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Paragraph(text: 'Month: ${DateFormat.yMMM().format(selectedMonth)}'),
          pw.Paragraph(text: 'Generated on $dateStr'),
          pw.Table.fromTextArray(headers: headers, data: data),
          pw.SizedBox(height: 12),
          pw.Text(
            'Total Amount: ₹${total.toStringAsFixed(2)}',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename:
      '${widget.type == ExpenseType.Room ? 'room' : 'personal'}-expenses-${DateFormat.yMMMd().format(selectedMonth)}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ExpenseProvider>();
    final list = prov.monthlyExpenses(widget.type, selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type == ExpenseType.Room
            ? 'Room Expenses'
            : 'Personal Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _pickMonth,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Export PDF',
            onPressed: list.isEmpty ? null : () => _exportPdf(list),
          ),
        ],
      ),
      body: list.isEmpty
          ? Center(
        child: Text(
          'No expenses for ${DateFormat.yMMM().format(selectedMonth)}',
        ),
      )
          : ListView.builder(
        padding:
        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final e = list[i];
          final bgColor = _colorForPrice(e.price);

          return Card(
            color: bgColor,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 8, horizontal: 16),
              leading: e.imagePath != null
                  ? GestureDetector(
                onTap: () => _showImageDialog(e.imagePath!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(e.imagePath!),
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
              )
                  : null,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${e.price.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey.shade800),
                  ),
                ],
              ),
              subtitle: Text(
                '${e.category} • '
                    '${DateFormat.yMMMd().format(e.date)} '
                    '${DateFormat.jm().format(e.date)}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddExpensePage(
                            type: widget.type,
                            editExpense: e,
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete this expense?'),
                          content: Text(e.name),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                prov.deleteExpense(e);
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AddExpensePage(type: widget.type)),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}


