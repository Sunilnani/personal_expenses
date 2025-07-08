// lib/screens/home_page.dart
import 'package:expenses_tracker/pages/expense_list_page.dart';
import 'package:expenses_tracker/pages/statistics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:expenses_tracker/providers/expense_provider.dart';
import 'package:expenses_tracker/models/expense_model.dart';
import 'package:expenses_tracker/pages/friend/friends_list_page.dart';

/// Main dashboard with animated amounts, personalized greeting, and vibrant expense tiles
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
      return Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
          .animate(
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

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ExpenseProvider>();

    return Scaffold(
      body: Stack(
        children: [
          // Light airy gradient background
          // Container(
          //   decoration: const BoxDecoration(
          //     gradient: LinearGradient(
          //       colors: [Color(0xFFB3E5FC), Color(0xFFE1F5FE)],
          //       begin: Alignment.topCenter,
          //       end: Alignment.bottomCenter,
          //     ),
          //   ),
          // ),
          Positioned(
            top: -50,
            right: -100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildSummary(prov),
                const SizedBox(height: 20),
                Expanded(child: _buildGrid(context, prov)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final greeting = _getGreeting();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/expenses.png',
            height: 60,
            width: 60,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, $greeting Sunil',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat.yMMMMd().format(DateTime.now()),
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(ExpenseProvider prov) {
    final total = prov.totalFor(ExpenseType.Room)
        + prov.totalFor(ExpenseType.Personal)
        + prov.totalFriendsOwed();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => StatisticsPage(),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(
              opacity: anim,
              child: child,
            ),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.show_chart, size: 30, color: Colors.white),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overall Total',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: total),
                    duration: const Duration(seconds: 1),
                    builder: (context, value, _) => Text(
                      '₹${value.toStringAsFixed(1)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, ExpenseProvider prov) {
    final cards = [
      _cardConfig(
        title: 'Room Expenses',
        amount: prov.totalFor(ExpenseType.Room),
        colors: const [Color(0xFF81C784), Color(0xFFA5D6A7)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ExpenseListPage(type: ExpenseType.Room)),
        ),
      ),
      _cardConfig(
        title: 'Personal Expenses',
        amount: prov.totalFor(ExpenseType.Personal),
        colors: const [Color(0xFFFF8A65), Color(0xFFFFCCBC)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ExpenseListPage(type: ExpenseType.Personal)),
        ),
      ),
      _cardConfig(
        title: 'Friends',
        amount: prov.totalFriendsOwed(),
        colors: const [Color(0xFFBA68C8), Color(0xFFE1BEE7)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FriendListPage()),
        ),
      ),
    ];

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) {
        return FadeTransition(
          opacity: _fadeAnims[i],
          child: SlideTransition(
            position: _slideAnims[i],
            child: cards[i],
          ),
        );
      },
    );
  }

  Widget _cardConfig({
    required String title,
    required double amount,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        splashColor: colors.last.withOpacity(0.3),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: amount),
                duration: const Duration(seconds: 1),
                builder: (context, value, _) => Text(
                  '₹${value.toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text('Updated: ${DateFormat.yMMM().format(DateTime.now())}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
