// lib/screens/add_expense_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';

class AddExpensePage extends StatefulWidget {
  final ExpenseType type;
  final Expense? editExpense;

  const AddExpensePage({Key? key, required this.type, this.editExpense}) : super(key: key);

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String? _category;
  String? _name;
  double? _price;
  DateTime _date = DateTime.now();
  File? _imageFile;

  late final TextEditingController _priceController;
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  bool _isHighAmount = false;

  final ImagePicker _picker = ImagePicker();
  static const _hugeThreshold = 1000.0;

  List<String> get _categories => widget.type == ExpenseType.Room
      ? ['Vegetables', 'Groceries', 'Utilities', 'Others']
      : ['Movie', 'Journey', 'Eating', 'Shopping', 'Others'];

  @override
  void initState() {
    super.initState();
    final e = widget.editExpense;
    if (e != null) {
      _category = e.category;
      _name = e.name;
      _price = e.price;
      _date = e.date;
      if (e.imagePath != null) _imageFile = File(e.imagePath!);
    }

    _priceController = TextEditingController(text: _price?.toString());
    _priceController.addListener(_onPriceChanged);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _onPriceChanged() {
    final val = double.tryParse(_priceController.text) ?? 0;
    if (val > _hugeThreshold) {
      if (!_animationController.isAnimating) {
        _animationController.repeat(reverse: true);
      }
      if (!_isHighAmount) setState(() => _isHighAmount = true);
    } else {
      if (_animationController.isAnimating) {
        _animationController.stop();
        _animationController.reset();
      }
      if (_isHighAmount) setState(() => _isHighAmount = false);
    }
  }

  @override
  void dispose() {
    _priceController.removeListener(_onPriceChanged);
    _priceController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    if (_category == null) return;
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final expense = Expense(
      type: widget.type,
      category: _category!,
      name: _name!,
      price: _price!,
      date: _date,
      imagePath: _imageFile?.path,
    );
    final provider = context.read<ExpenseProvider>();
    if (widget.editExpense != null) {
      provider.updateExpense(widget.editExpense!, expense);
    } else {
      provider.addExpense(expense);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editExpense != null;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          isEdit ? 'Edit Expense' : 'Add Expense',
          style: const TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Category',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  value: _category,
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _category = v),
                  validator: (v) => v == null ? 'Please select category' : null,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Name',
                    prefixIcon: const Icon(Icons.drive_file_rename_outline),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  initialValue: _name,
                  onSaved: (v) => _name = v,
                  validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
                ),
                const SizedBox(height: 16),
                // Animated Amount Field
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _isHighAmount
                          ? [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ]
                          : [],
                    ),
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixIcon: Icon(Icons.attach_money),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onSaved: (v) => _price = double.tryParse(v!),
                      validator: (v) => v == null || double.tryParse(v) == null ? 'Invalid amount' : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text(DateFormat.yMMMd().format(_date)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_imageFile!, fit: BoxFit.cover),
                    )
                        : const Center(child: Icon(Icons.camera_alt, size: 48)),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(isEdit ? 'Update Expense' : 'Save Expense'),
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

