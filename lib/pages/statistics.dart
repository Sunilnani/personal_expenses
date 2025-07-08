// lib/screens/statistics_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expense_provider.dart';
import '../models/expense_model.dart';

/// Shows expense breakdown as pie charts and a bar chart comparison
class StatisticsPage extends StatelessWidget {
  const StatisticsPage({Key? key}) : super(key: key);

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
            Text('Room Expenses by Category', style: Theme.of(context).textTheme.titleSmall),
             SizedBox(height: 200, child: _PieChart(data: roomData)),
            const SizedBox(height: 24),
            Text('Personal Expenses by Category', style: Theme.of(context).textTheme.titleSmall),
             SizedBox(height: 200, child: _PieChart(data: personalData)),
            const SizedBox(height: 24),
            Text('Overall Comparison', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 200, child: _BarChart()),
          ],
        ),
      ),
    );
  }
}

class _PieChart extends StatelessWidget {
  final Map<String, double> data;
  const _PieChart({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sections = data.entries.map((e) {
      final color = Colors.primaries[data.keys.toList().indexOf(e.key) % Colors.primaries.length];
      return PieChartSectionData(
        value: e.value,
        title: '${e.key}\n₹${e.value.toStringAsFixed(0)}',
        color: color,
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return PieChart(PieChartData(
      sections: sections,
      centerSpaceRadius: 40,
      sectionsSpace: 4,
    ));
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final prov = context.read<ExpenseProvider>();
    final roomTotal = prov.totalFor(ExpenseType.Room);
    final personalTotal = prov.totalFor(ExpenseType.Personal);
    final friendsTotal = prov.totalFriendsOwed();

    return BarChart(BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: [roomTotal, personalTotal, friendsTotal].reduce((a, b) => a > b ? a : b) * 1.2,
      barGroups: [
        BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: roomTotal, color: Colors.teal)]),
        BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: personalTotal, color: Colors.amber)]),
        BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: friendsTotal, color: Colors.pink)]),
      ],
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, _) {
            const labels = ['Room', 'Personal', 'Friends'];
            return Text(labels[value.toInt()]);
          }),
        ),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(show: false),
      borderData: FlBorderData(show: false),
    ));
  }
}
