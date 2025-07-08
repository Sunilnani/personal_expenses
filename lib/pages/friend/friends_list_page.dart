// lib/screens/friend_list_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/expense_provider.dart';
import 'friend_expenses_detail_page.dart';

/// A polished, color-coded list of friends sorted by total spent
class FriendListPage extends StatelessWidget {
  const FriendListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ExpenseProvider>();
    final friends = prov.friendsWithTotals();
    friends.sort((a, b) => b.total.compareTo(a.total));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Friends',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: friends.isEmpty
            ? Center(
          child: Text(
            'No friends yet. Tap + to add one!',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        )
            : ListView.builder(
          itemCount: friends.length,
          itemBuilder: (ctx, i) {
            final f = friends[i];
            final bgColor = f.total < 100
                ? Colors.green.shade50
                : f.total < 500
                ? Colors.blue.shade50
                : f.total < 1000
                ? Colors.amber.shade50
                : Colors.pink.shade50;

            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FriendExpenseDetailPage(friendName: f.name),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor.withOpacity(0.7),
                            Theme.of(context).primaryColor.withOpacity(0.7),
                           //Theme.of(context).canvasColor.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          f.name[0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total spent: ₹${f.total.toStringAsFixed(2)}',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFriendSheet(context),
        child: const Icon(Icons.person_add_alt_1),
        tooltip: 'Add Friend',
      ),
    );
  }

  void _showAddFriendSheet(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String? _newFriend;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Add New Friend', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Friend Name',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter a name' : null,
                  onSaved: (v) => _newFriend = v?.trim(),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;
                      _formKey.currentState!.save();
                      if (_newFriend != null) {
                        context.read<ExpenseProvider>().addFriend(_newFriend!);
                      }
                      Navigator.pop(ctx);
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
