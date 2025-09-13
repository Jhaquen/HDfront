import 'package:flutter/material.dart';
import 'create_chart_screen.dart';
import 'chart_viewer_screen.dart';

class ChartData {
  final String name;
  final double lat;
  final double long;
  final DateTime date;
  final TimeOfDay time;

  ChartData({
    required this.name,
    required this.lat,
    required this.long,
    required this.date,
    required this.time,
  });
}

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  final List<ChartData> _charts = [];

  void _addChart(ChartData chart) {
    setState(() {
      _charts.add(chart);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Charts'),
      ),
      body: ListView.builder(
        itemCount: _charts.length,
        itemBuilder: (context, index) {
          final chart = _charts[index];
          return ListTile(
            title: Text(chart.name),
            subtitle: Text('${chart.lat}, ${chart.long} - ${chart.date.toLocal().toString().split(' ')[0]} ${chart.time.format(context)}'),
            onTap: () {
              // Navigate to view the chart
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChartViewerScreen(chart: chart),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<ChartData>(
            context,
            MaterialPageRoute(builder: (context) => CreateChartScreen()),
          );
          if (result != null) {
            _addChart(result);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
