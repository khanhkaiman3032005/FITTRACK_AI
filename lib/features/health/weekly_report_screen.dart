import 'package:flutter/material.dart';

import '../../models/daily_record.dart';
import '../../models/weekly_report.dart';
import '../../services/daily_history_service.dart';

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  @override
  Widget build(BuildContext context) {
    final report = DailyHistoryService.getWeeklyReport();

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF001B2E),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Báo cáo tuần',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Tổng quan hoạt động 7 ngày gần nhất',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
      body: report.daysWithData == 0
          ? _buildEmptyState()
          : _buildReport(report),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bar_chart_rounded,
              size: 64,
              color: Color(0xFF475569),
            ),

            const SizedBox(height: 16),

            const Text(
              'Chưa có dữ liệu báo cáo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Hãy sử dụng FITTRACK để dữ liệu hoạt động '
              'được ghi nhận theo từng ngày.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _loadDemoData,
              icon: const Icon(Icons.science_outlined),
              label: const Text('Nạp dữ liệu Demo 7 ngày'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadDemoData() async {
    await DailyHistoryService.seedDemoLast7Days();

    if (!mounted) return;

    setState(() {});
  }

  Widget _buildReport(WeeklyReport report) {
    final records = DailyHistoryService.getRecentRecords(days: 7);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 800;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 40 : 16,
            vertical: 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryHeader(report),

                  const SizedBox(height: 24),

                  _buildStatGrid(report, isDesktop),

                  const SizedBox(height: 32),

                  const Text(
                    'Hoạt động 7 ngày',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildActivityChart(records),

                  const SizedBox(height: 24),

                  _buildBestDayCard(report),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryHeader(WeeklyReport report) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF083344),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFF00C8F8),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tổng quan tuần',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${report.daysWithData}/7 ngày có dữ liệu',
                  style: const TextStyle(color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(WeeklyReport report, bool isDesktop) {
    final cards = [
      _StatData(
        title: 'Calories đốt',
        value: '${report.totalCaloriesBurned}',
        unit: 'kcal',
        subtitle:
            'TB ${report.averageCaloriesBurned.toStringAsFixed(0)} kcal/ngày',
        icon: Icons.local_fire_department_rounded,
      ),
      _StatData(
        title: 'Bước chân',
        value: '${report.totalSteps}',
        unit: 'bước',
        subtitle: 'TB ${report.averageSteps.toStringAsFixed(0)} bước/ngày',
        icon: Icons.directions_walk_rounded,
      ),
      _StatData(
        title: 'Vận động',
        value: '${report.totalWorkoutMinutes}',
        unit: 'phút',
        subtitle:
            'TB ${report.averageWorkoutMinutes.toStringAsFixed(0)} phút/ngày',
        icon: Icons.timer_outlined,
      ),
      _StatData(
        title: 'Bài tập',
        value: '${report.totalCompletedExercises}',
        unit: 'bài',
        subtitle: '${report.daysWithData} ngày được ghi nhận',
        icon: Icons.fitness_center_rounded,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isDesktop ? 1.45 : 1.05,
      ),
      itemBuilder: (context, index) {
        return _buildStatCard(cards[index]);
      },
    );
  }

  Widget _buildStatCard(_StatData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: const Color(0xFF00C8F8)),
          const Spacer(),
          Text(
            data.title,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  data.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  data.unit,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            data.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart(List<DailyRecord> records) {
    if (records.isEmpty) {
      return const SizedBox.shrink();
    }

    int maxSteps = 1;

    for (final record in records) {
      if (record.steps > maxSteps) {
        maxSteps = record.steps;
      }
    }

    return Container(
      width: double.infinity,
      height: 260,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: records.map((record) {
          final percentage = maxSteps == 0 ? 0.0 : record.steps / maxSteps;

          final barHeight = 140.0 * percentage;

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${record.steps}',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 28,
                  height: barHeight < 8 ? 8 : barHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C8F8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${record.date.day}/${record.date.month}',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBestDayCard(WeeklyReport report) {
    final best = report.mostActiveDay;
    final least = report.leastActiveDay;

    if (best == null || least == null) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 700;

        final bestCard = _buildActivityDayCard(
          icon: Icons.emoji_events_rounded,
          title: 'Ngày hoạt động tốt nhất',
          record: best,
        );

        final leastCard = _buildActivityDayCard(
          icon: Icons.bedtime_outlined,
          title: 'Ngày ít hoạt động nhất',
          record: least,
        );

        if (desktop) {
          return Row(
            children: [
              Expanded(child: bestCard),
              const SizedBox(width: 12),
              Expanded(child: leastCard),
            ],
          );
        }

        return Column(
          children: [bestCard, const SizedBox(height: 12), leastCard],
        );
      },
    );
  }

  Widget _buildActivityDayCard({
    required IconData icon,
    required String title,
    required DailyRecord record,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00C8F8), size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${record.date.day.toString().padLeft(2, '0')}/'
                  '${record.date.month.toString().padLeft(2, '0')}/'
                  '${record.date.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${record.steps} bước • '
                  '${record.workoutMinutes} phút • '
                  '${record.caloriesBurned} kcal',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatData {
  final String title;
  final String value;
  final String unit;
  final String subtitle;
  final IconData icon;

  const _StatData({
    required this.title,
    required this.value,
    required this.unit,
    required this.subtitle,
    required this.icon,
  });
}
