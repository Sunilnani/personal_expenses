// lib/main.dart
import 'package:expenses_tracker/providers/expense_provider.dart';
import 'package:expenses_tracker/utils/storage_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/home_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageDir = await getStorageDirectory();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ExpenseProvider(storageDir),
      child: const ExpenseApp(),
    ),
  );
}

class ExpenseApp extends StatelessWidget {
  const ExpenseApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.teal,
        ).copyWith(secondary: Colors.amber),
      ),
      home: const HomePage(),
    );
  }
}
