import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/notification_analytics.dart';
import '../../data/repositories/notification_analytics_repository.dart';

class NotificationAnalyticsScreen extends ConsumerStatefulWidget {
  const NotificationAnalyticsScreen({super.key});

  @override
  ConsumerState<NotificationAnalyticsScreen> createState() =>
      _NotificationAnalyticsScreenState();
}

class _NotificationAnalyticsScreenState
    extends ConsumerState<NotificationAnalyticsScreen> {
  final _repository = NotificationAnalyticsRepository();
  int _selectedDays = 30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Notification Analytics'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          DropdownButton<int>(
            value: _selectedDays,
            items: const [
              DropdownMenuItem(value: 7, child: Text('Last 7 days')),
              DropdownMenuItem(value: 14, child: Text('Last 14 days')),
              DropdownMenuItem(value: 30, child: Text('Last 30 days')),
              DropdownMenuItem(value: 90, child: Text('Last 90 days')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedDays = value);
              }
            },
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Real-time stats cards
          _buildRealTimeStats(),
          const SizedBox(height: 16),
          // Charts and detailed analytics
          Expanded(
            child: _buildAnalyticsContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildRealTimeStats() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _repository.getRealTimeStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data!;
        final totalSent = stats['totalSent'] as int? ?? 0;
        final delivered = stats['delivered'] as int? ?? 0;
        final opened = stats['opened'] as int? ?? 0;
        final clicked = stats['clicked'] as int? ?? 0;
        final failed = stats['failed'] as int? ?? 0;

        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Real-time Statistics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatCard('Total Sent', totalSent, Icons.send, Colors.blue),
                  const SizedBox(width: 12),
                  _buildStatCard('Delivered', delivered, Icons.check_circle, Colors.green),
                  const SizedBox(width: 12),
                  _buildStatCard('Opened', opened, Icons.visibility, Colors.purple),
                  const SizedBox(width: 12),
                  _buildStatCard('Clicked', clicked, Icons.touch_app, Colors.orange),
                  const SizedBox(width: 12),
                  _buildStatCard('Failed', failed, Icons.error, Colors.red),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return FutureBuilder<NotificationMetrics>(
      future: _repository.getOverallMetrics(days: _selectedDays),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final metrics = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rate cards
              _buildRateCards(metrics),
              const SizedBox(height: 24),
              // Charts row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildDeliveryTrendChart(metrics.dailyStats),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildByTypeChart(metrics.byType),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // By category chart
              _buildByCategoryChart(metrics.byCategory),
              const SizedBox(height: 16),
              // Daily stats table
              _buildDailyStatsTable(metrics.dailyStats),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRateCards(NotificationMetrics metrics) {
    return Row(
      children: [
        _buildRateCard('Delivery Rate', metrics.deliveryRate, Colors.green),
        const SizedBox(width: 12),
        _buildRateCard('Open Rate', metrics.openRate, Colors.blue),
        const SizedBox(width: 12),
        _buildRateCard('Click Rate', metrics.clickRate, Colors.purple),
        const SizedBox(width: 12),
        _buildRateCard('Failure Rate', metrics.failureRate, Colors.red),
      ],
    );
  }

  Widget _buildRateCard(String label, double rate, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                '${rate.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: rate / 100,
                color: color,
                backgroundColor: color.withOpacity(0.1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryTrendChart(List<NotificationAnalytics> dailyStats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Trend',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: dailyStats
                          .take(7)
                          .toList()
                          .reversed
                          .map((stat) => FlSpot(
                                dailyStats.indexOf(stat).toDouble(),
                                stat.totalSent.toDouble(),
                              ))
                          .toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: dailyStats
                          .take(7)
                          .toList()
                          .reversed
                          .map((stat) => FlSpot(
                                dailyStats.indexOf(stat).toDouble(),
                                stat.delivered.toDouble(),
                              ))
                          .toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= dailyStats.length) return const Text('');
                          final date = dailyStats.reversed.toList()[index].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${date.day}/${date.month}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildByTypeChart(Map<String, int> byType) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'By Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: byType.entries.map((entry) {
                    final colors = [
                      Colors.blue,
                      Colors.green,
                      Colors.orange,
                      Colors.purple,
                      Colors.red,
                    ];
                    final color = colors[byType.keys.toList().indexOf(entry.key) % colors.length];
                    return PieChartSectionData(
                      value: entry.value.toDouble(),
                      title: '${entry.key}\n${entry.value}',
                      color: color,
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildByCategoryChart(Map<String, int> byCategory) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'By Category',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: byCategory.entries.map((entry) {
                    final colors = [
                      Colors.blue,
                      Colors.green,
                      Colors.orange,
                      Colors.purple,
                      Colors.red,
                    ];
                    final color = colors[byCategory.keys.toList().indexOf(entry.key) % colors.length];
                    return BarChartGroupData(
                      x: byCategory.keys.toList().indexOf(entry.key),
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color: color,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                      showingTooltipIndicators: [0],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyStatsTable(List<NotificationAnalytics> dailyStats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Statistics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Sent')),
                  DataColumn(label: Text('Delivered')),
                  DataColumn(label: Text('Opened')),
                  DataColumn(label: Text('Clicked')),
                  DataColumn(label: Text('Failed')),
                  DataColumn(label: Text('Delivery %')),
                ],
                rows: dailyStats.take(10).map((stat) {
                  return DataRow(
                    cells: [
                      DataCell(Text(_formatDate(stat.date))),
                      DataCell(Text(stat.totalSent.toString())),
                      DataCell(Text(stat.delivered.toString())),
                      DataCell(Text(stat.opened.toString())),
                      DataCell(Text(stat.clicked.toString())),
                      DataCell(Text(stat.failed.toString())),
                      DataCell(Text('${stat.deliveryRate.toStringAsFixed(1)}%')),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}