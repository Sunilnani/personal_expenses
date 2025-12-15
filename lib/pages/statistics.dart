// lib/screens/statistics_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expense_provider.dart';
import '../models/expense_model.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Widget _stagger({required int index, required Widget child}) {
    final start = index * 0.2;
    final end = (start + 0.6).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
      parent: _anim,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ExpenseProvider>();
    final roomData = prov.categoryTotals(ExpenseType.Room);
    final personalData = prov.categoryTotals(ExpenseType.Personal);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Room Pie
            _stagger(
              index: 0,
              child: const SectionHeader(title: 'Room Expenses by Category'),
            ),
            const SizedBox(height: 12),
            _stagger(
              index: 1,
              child: SizedBox(
                height: 250,
                child: AnimatedPieChart(data: roomData),
              ),
            ),

            // Personal Pie
            const SizedBox(height: 32),
            _stagger(
              index: 2,
              child: const SectionHeader(
                  title: 'Personal Expenses by Category'),
            ),
            const SizedBox(height: 12),
            _stagger(
              index: 3,
              child: SizedBox(
                height: 250,
                child: AnimatedPieChart(data: personalData),
              ),
            ),

            // Overall Comparison Bar
            const SizedBox(height: 32),
            _stagger(
              index: 4,
              child: const SectionHeader(title: 'Overall Comparison'),
            ),
            const SizedBox(height: 12),
            _stagger(
              index: 5,
              child: SizedBox(
                height: 320,
                child: const AnimatedBarChart(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({required this.title, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleLarge
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class AnimatedPieChart extends StatefulWidget {
  final Map<String, double> data;
  const AnimatedPieChart({required this.data, Key? key}) : super(key: key);

  @override
  State<AnimatedPieChart> createState() => _AnimatedPieChartState();
}

class _AnimatedPieChartState extends State<AnimatedPieChart> {
  int? _touchedIndex;

  // A richer palette
  static const _palette = [
    Color(0xFF00897B), // teal
    Color(0xFFD84315), // deep orange
    Color(0xFF3949AB), // indigo
    Color(0xFFC2185B), // pink
    Color(0xFF7CB342), // light green
    Color(0xFFFFA000), // amber
  ];

  @override
  Widget build(BuildContext context) {
    final entries = widget.data.entries.toList();
    final total = entries.fold<double>(0, (sum, e) => sum + e.value);

    return Card(
      elevation: 3,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 6,
                  centerSpaceRadius: 48,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, resp) {
                      setState(() {
                        _touchedIndex =
                            resp?.touchedSection?.touchedSectionIndex;
                      });
                    },
                  ),
                  sections: List.generate(entries.length, (i) {
                    final e = entries[i];
                    final isTouched = i == _touchedIndex;
                    final fontSize = isTouched ? 16.0 : 12.0;
                    final radius = isTouched ? 72.0 : 60.0;
                    final color = _palette[i % _palette.length];
                    return PieChartSectionData(
                      color: color,
                      value: e.value,
                      title: isTouched
                          ? '${(e.value / total * 100).toStringAsFixed(1)}%'
                          : '',
                      radius: radius,
                      titleStyle: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }),
                  startDegreeOffset: 180,
                ),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutQuint,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: List.generate(entries.length, (i) {
                final e = entries[i];
                final color = _palette[i % _palette.length];
                final pct =
                (e.value / total * 100).toStringAsFixed(1);
                return LegendItem(color: color, text: '${e.key} ($pct%)');
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  const LegendItem({required this.color, required this.text, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 16,
        height: 16,
        decoration:
        BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      ),
      const SizedBox(width: 4),
      Text(text, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}

class AnimatedBarChart extends StatelessWidget {
  const AnimatedBarChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final prov = context.read<ExpenseProvider>();
    final roomTotal = prov.totalFor(ExpenseType.Room);
    final personalTotal = prov.totalFor(ExpenseType.Personal);
    final friendsTotal = prov.totalFriendsOwed();
    final maxY =
        [roomTotal, personalTotal, friendsTotal].reduce((a, b) => a > b ? a : b) *
            1.3;

    // define gradients for each bar
    final gradients = [
      [Colors.teal.shade300, Colors.teal.shade800],
      [Colors.deepOrange.shade300, Colors.deepOrange.shade800],
      [Colors.indigo.shade300, Colors.indigo.shade800],
    ];

    return Card(
      elevation: 3,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: BarChart(
          BarChartData(
            maxY: maxY,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
               // tooltipBgColor: Colors.grey.shade800,
                getTooltipItem: (group, _, rod, __) {
                  const labels = ['Room', 'Personal', 'Friends'];
                  final label = labels[group.x.toInt()];
                  return BarTooltipItem(
                    '$label\n₹${rod.toY.toStringAsFixed(0)}',
                    const TextStyle(color: Colors.white),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  getTitlesWidget: (value, _) {
                    // skip drawing the very top label
                    if (value >= maxY * 0.99) return Container();
                    return Text(
                      value.toInt().toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, _) {
                    const labels = ['Room', 'Personal', 'Friends'];
                    final text = labels[value.toInt()];
                    return Text(
                      text,
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(3, (i) {
              final heights = [roomTotal, personalTotal, friendsTotal];
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: heights[i],
                    width: 16,
                    gradient: LinearGradient(
                      colors: gradients[i],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  )
                ],
              );
            }),
            alignment: BarChartAlignment.spaceAround,
          ),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutBack,
        ),
      ),
    );
  }
}
