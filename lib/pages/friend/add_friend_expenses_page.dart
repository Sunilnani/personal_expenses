// lib/screens/add_friend_expense_page.dart
import 'dart:io';
import 'package:expenses_tracker/models/friend_expense_model.dart';
import 'package:expenses_tracker/providers/expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AddFriendExpensePage extends StatefulWidget {
  final String? defaultFriend;
  final FriendExpense? existingExpense;

  const AddFriendExpensePage({
    Key? key,
    this.defaultFriend,
    this.existingExpense,
  }) : super(key: key);

  @override
  _AddFriendExpensePageState createState() => _AddFriendExpensePageState();
}

class _AddFriendExpensePageState extends State<AddFriendExpensePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String? _friend;
  String? _reason;
  double? _amount;
  late DateTime _date;
  File? _imageFile;

  late final TextEditingController _amountController;
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  bool _isHighAmount = false;

  final ImagePicker _picker = ImagePicker();
  static const _highThreshold = 10000.0;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingExpense;
    _friend = existing?.name ?? widget.defaultFriend;
    _reason = existing?.reason;
    _amount = existing?.amount;
    _date = existing?.date ?? DateTime.now();
    if (existing?.imagePath != null) {
      _imageFile = File(existing!.imagePath!);
    }

    _amountController =
        TextEditingController(text: _amount?.toString() ?? '');
    _amountController.addListener(_onAmountChanged);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Trigger initial animation logic
    WidgetsBinding.instance.addPostFrameCallback((_) => _onAmountChanged());
  }

  void _onAmountChanged() {
    final value = double.tryParse(_amountController.text) ?? 0;
    if (value > _highThreshold) {
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

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (time != null) {
      setState(() {
        _date = DateTime(
            date.year, date.month, date.day, time.hour, time.minute);
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final provider = context.read<ExpenseProvider>();
    final existing = widget.existingExpense;
    // generate a new UUID v4 if we're adding, otherwise keep the existing id
    final id = existing?.id ?? const Uuid().v4();

    final expense = FriendExpense(
      id: id,
      name: _friend!,
      reason: _reason!,
      amount: _amount!,
      date: _date,
      imagePath: _imageFile?.path,
    );

    if (existing != null) {
      provider.updateFriendExpense(expense);
    } else {
      provider.addFriendExpense(expense);
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friends = context.watch<ExpenseProvider>().allFriends();
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          widget.existingExpense != null
              ? 'Edit Expense'
              : 'Add Friend Expense',
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
                // Friend Dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Friend',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  value: _friend,
                  items: friends
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) => setState(() => _friend = v),
                  validator: (v) => v == null ? 'Select a friend' : null,
                ),
                const SizedBox(height: 24),

                // Reason Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextFormField(
                    initialValue: _reason,
                    decoration: const InputDecoration(
                      labelText: 'Reason',
                      prefixIcon: Icon(Icons.note),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                    ),
                    onSaved: (v) => _reason = v,
                    validator: (v) =>
                    v == null || v.isEmpty ? 'Enter reason' : null,
                  ),
                ),
                const SizedBox(height: 16),

                // Amount Field with scale + shadow on high amount
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
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount (₹)',
                        prefixIcon: Icon(Icons.attach_money),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                      ),
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      onSaved: (v) => _amount = double.tryParse(v!),
                      validator: (v) => v == null ||
                          double.tryParse(v) == null
                          ? 'Invalid amount'
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Date & Time Picker
                GestureDetector(
                  onTap: _pickDateTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat.yMMMd().add_jm().format(_date),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Image Picker
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

                // Save/Update Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      widget.existingExpense != null
                          ? 'Update Expense'
                          : 'Save Expense',
                      style: const TextStyle(fontSize: 16),
                    ),
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




// // lib/screens/add_friend_expense_page.dart
// import 'dart:io';
// import 'package:expenses_tracker/models/friend_expense_model.dart';
// import 'package:expenses_tracker/providers/expense_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
//
// class AddFriendExpensePage extends StatefulWidget {
//   final String? defaultFriend;
//   const AddFriendExpensePage({Key? key, this.defaultFriend}) : super(key: key);
//
//   @override
//   _AddFriendExpensePageState createState() => _AddFriendExpensePageState();
// }
//
// class _AddFriendExpensePageState extends State<AddFriendExpensePage>
//     with SingleTickerProviderStateMixin {
//   final _formKey = GlobalKey<FormState>();
//   String? _friend;
//   String? _reason;
//   double? _amount;
//   DateTime _date = DateTime.now();
//   File? _imageFile;
//
//   late final TextEditingController _amountController;
//   late final AnimationController _animationController;
//   late final Animation<double> _scaleAnimation;
//   bool _isHighAmount = false;
//
//   final ImagePicker _picker = ImagePicker();
//   static const _highThreshold = 10000.0;
//
//   @override
//   void initState() {
//     super.initState();
//     _friend = widget.defaultFriend;
//
//     _amountController = TextEditingController();
//     _amountController.addListener(_onAmountChanged);
//
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );
//     _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
//       CurvedAnimation(
//         parent: _animationController,
//         curve: Curves.easeInOut,
//       ),
//     );
//   }
//
//   void _onAmountChanged() {
//     final value = double.tryParse(_amountController.text) ?? 0;
//     if (value > _highThreshold) {
//       if (!_animationController.isAnimating) {
//         _animationController.repeat(reverse: true);
//       }
//       if (!_isHighAmount) setState(() => _isHighAmount = true);
//     } else {
//       if (_animationController.isAnimating) {
//         _animationController.stop();
//         _animationController.reset();
//       }
//       if (_isHighAmount) setState(() => _isHighAmount = false);
//     }
//   }
//
//   Future<void> _pickDateTime() async {
//     final date = await showDatePicker(
//       context: context,
//       initialDate: _date,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2100),
//     );
//     if (date == null) return;
//     final time = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.fromDateTime(_date),
//     );
//     if (time != null) {
//       setState(() {
//         _date = DateTime(date.year, date.month, date.day, time.hour, time.minute);
//       });
//     }
//   }
//
//   Future<void> _pickImage() async {
//     final picked = await _picker.pickImage(
//       source: ImageSource.gallery,
//       imageQuality: 80,
//     );
//     if (picked != null) setState(() => _imageFile = File(picked.path));
//   }
//
//   void _save() {
//     if (!_formKey.currentState!.validate()) return;
//     _formKey.currentState!.save();
//     final expense = FriendExpense(
//       name: _friend!,
//       reason: _reason!,
//       amount: _amount!,
//       date: _date,
//       imagePath: _imageFile?.path,
//     );
//     context.read<ExpenseProvider>().addFriendExpense(expense);
//     Navigator.pop(context);
//   }
//
//   @override
//   void dispose() {
//     _amountController.removeListener(_onAmountChanged);
//     _amountController.dispose();
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final friends = context.watch<ExpenseProvider>().allFriends();
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.black),
//         title: const Text(
//           'Add Friend Expense',
//           style: TextStyle(color: Colors.black),
//         ),
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Friend Dropdown
//                 DropdownButtonFormField<String>(
//                   decoration: InputDecoration(
//                     labelText: 'Friend',
//                     filled: true,
//                     fillColor: Colors.white,
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: BorderSide.none,
//                     ),
//                   ),
//                   value: _friend,
//                   items: friends
//                       .map((f) => DropdownMenuItem(value: f, child: Text(f)))
//                       .toList(),
//                   onChanged: (v) => setState(() => _friend = v),
//                   validator: (v) => v == null ? 'Select a friend' : null,
//                 ),
//                 const SizedBox(height: 24),
//
//                 // Reason Field
//                 Container(
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: TextFormField(
//                     decoration: const InputDecoration(
//                       labelText: 'Reason',
//                       prefixIcon: Icon(Icons.note),
//                       border: InputBorder.none,
//                       contentPadding:
//                       EdgeInsets.symmetric(horizontal: 12, vertical: 16),
//                     ),
//                     onSaved: (v) => _reason = v,
//                     validator: (v) => v == null || v.isEmpty
//                         ? 'Enter reason'
//                         : null,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//
//                 // Amount Field with scale + shadow on high amount
//                 ScaleTransition(
//                   scale: _scaleAnimation,
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: _isHighAmount
//                           ? [
//                         BoxShadow(
//                           color: Colors.red.withOpacity(0.4),
//                           blurRadius: 8,
//                           spreadRadius: 1,
//                           offset: const Offset(0, 2),
//                         ),
//                       ]
//                           : [],
//                     ),
//                     child: TextFormField(
//                       controller: _amountController,
//                       decoration: const InputDecoration(
//                         labelText: 'Amount (₹)',
//                         prefixIcon: Icon(Icons.attach_money),
//                         border: InputBorder.none,
//                         contentPadding:
//                         EdgeInsets.symmetric(horizontal: 12, vertical: 16),
//                       ),
//                       keyboardType:
//                       const TextInputType.numberWithOptions(decimal: true),
//                       onSaved: (v) => _amount = double.tryParse(v!),
//                       validator: (v) => v == null || double.tryParse(v) == null
//                           ? 'Invalid amount'
//                           : null,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//
//                 // Date & Time Picker
//                 GestureDetector(
//                   onTap: _pickDateTime,
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                         vertical: 16, horizontal: 12),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Row(
//                       children: [
//                         const Icon(Icons.calendar_today, color: Colors.grey),
//                         const SizedBox(width: 12),
//                         Text(
//                           DateFormat.yMMMd().add_jm().format(_date),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//
//                 // Image Picker
//                 GestureDetector(
//                   onTap: _pickImage,
//                   child: Container(
//                     height: 200,
//                     width: double.infinity,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[200],
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: _imageFile != null
//                         ? ClipRRect(
//                       borderRadius: BorderRadius.circular(12),
//                       child: Image.file(_imageFile!, fit: BoxFit.cover),
//                     )
//                         : const Center(child: Icon(Icons.camera_alt, size: 48)),
//                   ),
//                 ),
//                 const SizedBox(height: 32),
//
//                 // Save Button
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: _save,
//                     style: ElevatedButton.styleFrom(
//                       padding:
//                       const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12)),
//                     ),
//                     child: const Text('Save Expense',
//                         style: TextStyle(fontSize: 16)),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
