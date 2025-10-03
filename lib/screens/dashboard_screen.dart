import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

// Providers
import '../providers/app_providers.dart';

// Routes
import '../app_router.dart';

/// Dashboard screen showing mood trends and session history
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionHistoryProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track your mental wellness journey',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 32),
          _MoodTrendsCard(),
          const SizedBox(height: 24),
          _RecentSessionsCard(sessions: sessions),
          const SizedBox(height: 24),
          const _QuickActionsCard(),
        ],
      ),
    );
  }
}

class _MoodTrendsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.show_chart,
                color: Colors.blue.shade400,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Mood Trends (Last 7 Days)',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: _MoodLineChart(),
          ),
        ],
      ),
    );
  }
}

class _MoodLineChart extends StatelessWidget {
  final List<FlSpot> _moodData = const [
    FlSpot(0, 6.5),
    FlSpot(1, 7.0),
    FlSpot(2, 6.0),
    FlSpot(3, 7.5),
    FlSpot(4, 8.0),
    FlSpot(5, 7.8),
    FlSpot(6, 8.5),
  ];

  final List<String> _dayLabels = const [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < _dayLabels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _dayLabels[index],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 2,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: Colors.white.withOpacity(0.2)),
            bottom: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
        ),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: 10,
        lineBarsData: [
          LineChartBarData(
            spots: _moodData,
            isCurved: true,
            color: Colors.blue.shade400,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 6,
                  color: Colors.blue.shade400,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.shade400.withOpacity(0.2),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  'Mood: ${spot.y.toStringAsFixed(1)}\n${_dayLabels[spot.x.toInt()]}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

class _RecentSessionsCard extends StatelessWidget {
  final List<SessionItem> sessions;

  const _RecentSessionsCard({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final recentSessions = sessions.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                color: Colors.purple.shade400,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Recent Sessions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recentSessions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 48,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No sessions yet',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => AppRoutes.goToChat(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Start your first chat'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...recentSessions.map((session) => _SessionTile(session: session)),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final SessionItem session;

  const _SessionTile({required this.session});

  String _getMoodForSession() {
    final hash = session.id.hashCode % 5;
    return ['😊 Great', '😌 Good', '😐 Okay', '😔 Low', '😟 Struggling'][hash];
  }

  Color _getMoodColor() {
    final mood = _getMoodForSession();
    if (mood.contains('Great')) return Colors.green;
    if (mood.contains('Good')) return Colors.blue;
    if (mood.contains('Okay')) return Colors.yellow;
    if (mood.contains('Low')) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Navigate to chat and load this session
          AppRoutes.goToChat(context);
          // TODO: Add logic to load specific session by ID
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Loading session: ${session.title}'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getMoodColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getMoodColor().withOpacity(0.4),
                  ),
                ),
                child: Text(
                  _getMoodForSession(),
                  style: TextStyle(
                    color: _getMoodColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${session.messageCount} messages • ${_formatDate(session.lastModified)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.white.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${(diff.inDays / 7).floor()} weeks ago';
  }
}

class _QuickActionsCard extends ConsumerWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on,
                color: Colors.amber.shade400,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                AppRoutes.goToChat(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Starting new check-in session...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Start Check-in'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                AppRoutes.goToJournal(context);
              },
              icon: const Icon(Icons.book_outlined),
              label: const Text('View Journal'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
