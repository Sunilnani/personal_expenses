

import 'package:expenses_tracker/pages/statistics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/expense_provider.dart';
import '../models/expense_model.dart';
import 'expense_list_page.dart';
import 'friend/friends_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;

  DateTime _selectedMonth = DateTime.now();
  int _monthlyLimit = 18000;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();

    _fadeAnims = List.generate(3, (i) {
      final start = i * 0.1;
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, start + 0.5, curve: Curves.easeIn),
        ),
      );
    });
    _slideAnims = List.generate(3, (i) {
      final start = i * 0.1;
      return Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, start + 0.5, curve: Curves.easeOut),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _prevMonth() => setState(() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
  });
  void _nextMonth() => setState(() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
  });

  Future<void> _editLimitDialog() async {
    final controller = TextEditingController(text: '$_monthlyLimit');
    final formKey = GlobalKey<FormState>();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Set Monthly Limit'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(prefixText: '₹ '),
            keyboardType: TextInputType.number,
            validator: (s) =>
            s != null && int.tryParse(s) != null ? null : 'Enter a valid number',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                setState(() => _monthlyLimit = int.parse(controller.text));
                Navigator.pop(context);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ExpenseProvider>();
    final spent = prov.totalFor(ExpenseType.Room) +
        prov.totalFor(ExpenseType.Personal) +
        prov.totalFriendsOwed();
    final monthLabel = DateFormat.yMMMM().format(_selectedMonth);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // ─── HEADER ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blue.shade100,
                    child: Image.asset('assets/images/expenses.png', height: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getGreeting()}, Sunil',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat.yMMMMd().format(DateTime.now()),
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─── MONTH SELECTOR ───────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  IconButton(onPressed: _prevMonth, icon: Icon(Icons.chevron_left)),
                  Expanded(
                    child: Text(
                      monthLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(onPressed: _nextMonth, icon: Icon(Icons.chevron_right)),
                ],
              ),
            ),

            // ─── SUMMARY CARD ────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 600),
                  pageBuilder: (_, anim, __) => FadeTransition(
                    opacity: anim,
                    child: const StatisticsPage(),
                  ),
                )),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.show_chart, size: 28, color: Colors.white),
                          const SizedBox(width: 12),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: spent),
                            duration: const Duration(seconds: 1),
                            builder: (_, val, __) => Text(
                              '₹${val.toStringAsFixed(1)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '₹${spent.toStringAsFixed(0)} / ₹$_monthlyLimit',
                              style: const TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white70),
                            onPressed: _editLimitDialog,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Overall Total',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── GRID CARDS ──────────────────────
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.9,
                ),
                itemCount: 3,
                itemBuilder: (_, i) {
                  final configs = [
                    _CardConfig(
                      title: 'Room',
                      amount: prov.totalFor(ExpenseType.Room),
                      colors: [Colors.green.shade400, Colors.green.shade200],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ExpenseListPage(type: ExpenseType.Room)),
                      ),
                    ),
                    _CardConfig(
                      title: 'Personal',
                      amount: prov.totalFor(ExpenseType.Personal),
                      colors: [Colors.orange.shade400, Colors.orange.shade200],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ExpenseListPage(type: ExpenseType.Personal)),
                      ),
                    ),
                    _CardConfig(
                      title: 'Friends',
                      amount: prov.totalFriendsOwed(),
                      colors: [Colors.purple.shade400, Colors.purple.shade200],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => FriendListPage()),
                      ),
                    ),
                  ];
                  final cfg = configs[i];
                  return FadeTransition(
                    opacity: _fadeAnims[i],
                    child: SlideTransition(
                      position: _slideAnims[i],
                      child: _buildTile(cfg),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(_CardConfig cfg) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: cfg.onTap,
        splashColor: cfg.colors.last.withOpacity(0.3),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: cfg.colors),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${cfg.title} Expenses',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: cfg.amount),
                duration: const Duration(milliseconds: 800),
                builder: (_, val, __) => Text(
                  '₹${val.toStringAsFixed(1)}',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Updated ${DateFormat.yMMM().format(DateTime.now())}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardConfig {
  final String title;
  final double amount;
  final List<Color> colors;
  final VoidCallback onTap;
  _CardConfig({required this.title, required this.amount, required this.colors, required this.onTap});
}


