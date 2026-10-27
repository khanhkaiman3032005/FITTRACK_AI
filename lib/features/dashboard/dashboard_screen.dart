import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/fittrack_motion.dart';

import '../../core/routes/app_routes.dart';
import '../../services/health_service.dart';
import '../../services/nutrition_service.dart';
import '../../services/workout_service.dart';
import '../../services/daily_history_service.dart';
import '../../models/daily_record.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B16),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF08182A),
                    Color(0xFF080D1B),
                    Color(0xFF171029),
                    Color(0xFF080D19),
                  ],
                  stops: [0.0, 0.38, 0.75, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: -140,
            right: -100,
            child: IgnorePointer(
              child: Container(
                width: 440,
                height: 440,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -170,
            left: 100,
            child: IgnorePointer(
              child: Container(
                width: 480,
                height: 480,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondary.withValues(alpha: 0.13),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 900;

                if (isDesktop) {
                  return Row(
                    children: [
                      const _Sidebar(),
                      Expanded(child: _DashboardContent(isDesktop: true)),
                    ],
                  );
                }

                return const _DashboardContent(isDesktop: false);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 900
          ? const _MobileNavigation()
          : null,
    );
  }
}

class _DashboardContent extends StatefulWidget {
  final bool isDesktop;

  const _DashboardContent({required this.isDesktop});

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    await DailyHistoryService.loadData();

    if (!mounted) return;

    setState(() {});
  }

  bool get _isToday {
    final now = DateTime.now();

    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: HealthService.notifier,
      builder: (context, _, _) {
        return ValueListenableBuilder<int>(
          valueListenable: NutritionService.notifier,
          builder: (context, _, _) {
            return ValueListenableBuilder<int>(
              valueListenable: WorkoutService.notifier,
              builder: (context, _, _) {
                return SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      widget.isDesktop ? 30 : 18,
                      widget.isDesktop ? 30 : 20,
                      widget.isDesktop ? 30 : 18,
                      36,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1280),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(context),

                            const SizedBox(height: 30),

                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isMobile = constraints.maxWidth < 600;

                                final title = Text(
                                  _isToday
                                      ? 'Tổng quan hôm nay'
                                      : 'Tổng quan ngày ${_selectedDate.day}/${_selectedDate.month}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    color: Color(0xFFF1F7FF),
                                  ),
                                );

                                // Khi đang xem ngày cũ thì chỉ hiện tiêu đề.
                                if (!_isToday) {
                                  return title;
                                }

                                // Android / màn hình nhỏ
                                if (isMobile) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      title,
                                      const SizedBox(height: 12),
                                      _buildWeeklyReportButton(context),
                                    ],
                                  );
                                }

                                // Web / màn hình lớn
                                return Row(
                                  children: [
                                    Expanded(child: title),
                                    const SizedBox(width: 16),
                                    _buildWeeklyReportButton(context),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 18),

                            _buildDateSelector(),

                            const SizedBox(height: 22),

                            _buildStats(),

                            const SizedBox(height: 32),

                            _buildMainContent(),

                            const SizedBox(height: 30),

                            _buildAiCoach(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildWeeklyReportButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        Navigator.pushNamed(context, AppRoutes.weeklyReport);
      },
      icon: const Icon(Icons.bar_chart_rounded, size: 18),
      label: const Text('Xem báo cáo tuần'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF00C8F8),
        side: const BorderSide(color: Color(0xFF164E63)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;

    return FitEntrance(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF10374A), Color(0xFF132743), Color(0xFF211B40)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.24)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.10),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Positioned(
                right: -65,
                top: -85,
                child: IgnorePointer(
                  child: Container(
                    width: 230,
                    height: 230,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.23),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 80,
                bottom: -100,
                child: IgnorePointer(
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.secondary.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(compact ? 20 : 30),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2DD4BF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 9),
                              const Flexible(
                                child: Text(
                                  'YOUR FITNESS COMMAND CENTER',
                                  style: TextStyle(
                                    color: Color(0xFF80E7FF),
                                    fontSize: 10,
                                    letterSpacing: 1.4,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Mỗi ngày một\nphiên bản tốt hơn.',
                            style: TextStyle(
                              fontSize: compact ? 24 : 33,
                              fontWeight: FontWeight.w800,
                              height: 1.16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Theo dõi hành trình của bạn cùng FITTRACK AI.',
                            style: TextStyle(
                              color: Color(0xFFB5CCDF),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.16),
                            ),
                          ),
                          child: IconButton(
                            tooltip: 'Hồ sơ cá nhân',
                            onPressed: () {
                              Navigator.pushNamed(context, AppRoutes.profile);
                            },
                            icon: const Icon(
                              Icons.person_outline_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFF80E7FF),
                          size: 28,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    final now = DateTime.now();

    final dates = List.generate(
      7,
      (index) => now.add(Duration(days: index - 3)),
    );

    const weekDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return FitEntrance(
      child: SizedBox(
        height: 92,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: dates.length,
          separatorBuilder: (context, index) {
            return const SizedBox(width: 12);
          },
          itemBuilder: (context, index) {
            final date = dates[index];

            final isSelected = DateUtils.isSameDay(date, _selectedDate);

            final isToday = DateUtils.isSameDay(date, now);

            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                setState(() {
                  _selectedDate = date;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: 68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: isSelected
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF65E8FF), Color(0xFF00A9F4)],
                        )
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1D2940), Color(0xFF121B2E)],
                        ),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF8CEEFF)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.30),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      weekDays[date.weekday - 1],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? const Color(0xFF092032)
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        color: isSelected
                            ? const Color(0xFF051522)
                            : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isToday
                            ? (isSelected
                                  ? const Color(0xFF051522)
                                  : AppColors.primary)
                            : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  Widget _buildStats() {
    final health = HealthService.data;

    int caloriesIntake;
    int caloriesBurned;
    int steps;
    int workoutMinutes;
    double bmi;
    String bmiStatus;

    if (_isToday) {
      // HÔM NAY -> lấy dữ liệu realtime
      caloriesIntake = NutritionService.totalCalories;
      caloriesBurned = WorkoutService.caloriesBurnedToday;
      steps = health.steps;
      workoutMinutes = health.activeMinutes;
      bmi = health.bmi;
      bmiStatus = health.bmiStatus;
    } else {
      // NGÀY KHÁC -> lấy dữ liệu đã lưu
      final DailyRecord record = DailyHistoryService.getRecordOrEmpty(
        _selectedDate,
      );

      caloriesIntake = record.caloriesIntake;
      caloriesBurned = record.caloriesBurned;
      steps = record.steps;
      workoutMinutes = record.workoutMinutes;
      bmi = record.bmi;

      if (bmi <= 0) {
        bmiStatus = '--';
      } else if (bmi < 18.5) {
        bmiStatus = 'Thiếu cân';
      } else if (bmi < 25) {
        bmiStatus = 'Bình thường';
      } else if (bmi < 30) {
        bmiStatus = 'Thừa cân';
      } else {
        bmiStatus = 'Béo phì';
      }
    }

    final stats = [
      _StatData(
        title: 'Calories nạp',
        value: _formatNumber(caloriesIntake),
        unit: 'kcal',
        icon: Icons.restaurant_rounded,
      ),
      _StatData(
        title: 'Calories đốt',
        value: _formatNumber(caloriesBurned),
        unit: 'kcal',
        icon: Icons.local_fire_department_rounded,
      ),
      _StatData(
        title: 'Bước chân',
        value: _formatNumber(steps),
        unit: 'bước',
        icon: Icons.directions_walk_rounded,
      ),
      _StatData(
        title: 'Thời gian tập',
        value: workoutMinutes.toString(),
        unit: 'phút',
        icon: Icons.timer_outlined,
      ),
      _StatData(
        title: 'BMI',
        value: bmi > 0 ? bmi.toStringAsFixed(1) : '--',
        unit: bmiStatus,
        icon: Icons.monitor_weight_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int count;

        if (constraints.maxWidth >= 800) {
          count = 5;
        } else if (constraints.maxWidth >= 550) {
          count = 3;
        } else if (constraints.maxWidth >= 350) {
          count = 2;
        } else {
          count = 1;
        }

        final width = (constraints.maxWidth - ((count - 1) * 14)) / count;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: stats.map((item) {
            return SizedBox(
              width: width,
              child: _StatCard(data: item),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMainContent() {
    final DailyRecord? selectedRecord = _isToday
        ? null
        : DailyHistoryService.getRecordOrEmpty(_selectedDate);

    if (widget.isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: _TodayWorkout(isToday: _isToday, record: selectedRecord),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: _DailyGoal(isToday: _isToday, record: selectedRecord),
          ),
        ],
      );
    }

    return Column(
      children: [
        _TodayWorkout(isToday: _isToday, record: selectedRecord),
        const SizedBox(height: 20),
        _DailyGoal(isToday: _isToday, record: selectedRecord),
      ],
    );
  }

  Widget _buildAiCoach() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;

        final iconBox = Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
            ),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.primary,
            size: 29,
          ),
        );

        const description = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FITTRACK AI COACH',
              style: TextStyle(
                color: Color(0xFF76E4FF),
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 7),
            Text(
              'Trợ lý sức khỏe của riêng bạn',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 6),
            Text(
              'Phân tích tiến độ, luyện tập và dinh dưỡng '
              'dựa trên dữ liệu cá nhân.',
              style: TextStyle(
                color: Color(0xFFACC8D9),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        );

        final action = FilledButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.aiCoach);
          },
          icon: const Icon(Icons.arrow_forward_rounded),
          label: const Text('Khám phá AI Coach'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: const Color(0xFF061320),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );

        return FitEntrance(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF123F54),
                  Color(0xFF112A43),
                  Color(0xFF251C48),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.09),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          iconBox,
                          const SizedBox(width: 14),
                          const Expanded(child: description),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(width: double.infinity, child: action),
                    ],
                  )
                : Row(
                    children: [
                      iconBox,
                      const SizedBox(width: 18),
                      const Expanded(child: description),
                      const SizedBox(width: 16),
                      action,
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _StatData {
  final String title;
  final String value;
  final String unit;
  final IconData icon;

  const _StatData({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
  });
}

class _StatCard extends StatelessWidget {
  final _StatData data;

  const _StatCard({required this.data});

  Color get _accent {
    switch (data.title) {
      case 'Calories nạp':
        return const Color(0xFFFFB15C);
      case 'Calories đốt':
        return const Color(0xFFFF7087);
      case 'Bước chân':
        return const Color(0xFF2DD4BF);
      case 'Thời gian tập':
        return const Color(0xFFA78BFA);
      case 'BMI':
        return const Color(0xFF38BDF8);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FitEntrance(
      child: FitGlowCard(
        accent: _accent,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(data.icon, color: _accent, size: 23),
                ),
                Icon(
                  Icons.north_east_rounded,
                  size: 17,
                  color: _accent.withValues(alpha: 0.8),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              data.title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Text(
                data.value,
                key: ValueKey(data.value),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              data.unit,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _accent.withValues(alpha: 0.95),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayWorkout extends StatelessWidget {
  final bool isToday;
  final DailyRecord? record;

  const _TodayWorkout({required this.isToday, required this.record});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: WorkoutService.notifier,
      builder: (context, value, child) {
        final int completedExercises = isToday
            ? WorkoutService.completedToday
            : (record?.completedExercises ?? 0);

        final int workoutGoal = WorkoutService.dailyWorkoutGoal;

        final double progress = workoutGoal <= 0
            ? 0.0
            : (completedExercises / workoutGoal).clamp(0.0, 1.0).toDouble();

        return FitEntrance(
          child: FitGlowCard(
            accent: const Color(0xFF00C2FF),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isToday ? 'Bài tập hôm nay' : 'Bài tập ngày đã chọn',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FULL BODY',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Full Body Workout',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$completedExercises / $workoutGoal bài hoàn thành',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      builder: (context, animatedProgress, child) {
                        return SizedBox(
                          width: 82,
                          height: 82,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox.expand(
                                child: CircularProgressIndicator(
                                  value: animatedProgress,
                                  strokeWidth: 8,
                                  strokeCap: StrokeCap.round,
                                  backgroundColor: const Color(0xFF29354B),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        AppColors.primary,
                                      ),
                                ),
                              ),
                              Text(
                                '${(animatedProgress * 100).round()}%',
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FitAnimatedBar(value: progress, color: AppColors.primary),
                if (isToday) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await Navigator.pushNamed(context, AppRoutes.workout);
                        WorkoutService.notifier.value++;
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Bắt đầu tập luyện'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: const Color(0xFF071321),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DailyGoal extends StatelessWidget {
  final bool isToday;
  final DailyRecord? record;

  const _DailyGoal({required this.isToday, required this.record});

  @override
  Widget build(BuildContext context) {
    final health = HealthService.data;
    final profile = ProfileService.profile;

    final int calorieGoal = profile.dailyCalorieGoal;
    final int stepGoal = profile.dailyStepGoal;
    final double waterGoal = profile.dailyWaterGoal;
    final int activeMinutesGoal = profile.dailyActiveMinutesGoal;

    final int calories = isToday
        ? NutritionService.totalCalories
        : (record?.caloriesIntake ?? 0);

    final int steps = isToday ? health.steps : (record?.steps ?? 0);

    final double water = isToday ? health.water : (record?.water ?? 0.0);

    final int activeMinutes = isToday
        ? health.activeMinutes
        : (record?.workoutMinutes ?? 0);

    final double calorieProgress = calorieGoal <= 0
        ? 0.0
        : (calories / calorieGoal).clamp(0.0, 1.0).toDouble();

    final double stepProgress = stepGoal <= 0
        ? 0.0
        : (steps / stepGoal).clamp(0.0, 1.0).toDouble();

    final double waterProgress = waterGoal <= 0
        ? 0.0
        : (water / waterGoal).clamp(0.0, 1.0).toDouble();

    final double activeMinutesProgress = activeMinutesGoal <= 0
        ? 0.0
        : (activeMinutes / activeMinutesGoal).clamp(0.0, 1.0).toDouble();

    return FitEntrance(
      child: FitGlowCard(
        accent: const Color(0xFFA78BFA),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFFA78BFA).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.track_changes_rounded,
                    color: Color(0xFFA78BFA),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isToday ? 'Mục tiêu hôm nay' : 'Tiến độ ngày đã chọn',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            const Text(
              'Hành trình của bạn, từng bước một.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 25),
            _goal(
              Icons.local_fire_department_rounded,
              'Calories',
              '${_formatNumber(calories)} / ${_formatNumber(calorieGoal)} kcal',
              calorieProgress,
              const Color(0xFFFFB15C),
            ),
            const SizedBox(height: 19),
            _goal(
              Icons.directions_walk_rounded,
              'Bước chân',
              '${_formatNumber(steps)} / ${_formatNumber(stepGoal)}',
              stepProgress,
              const Color(0xFF2DD4BF),
            ),
            const SizedBox(height: 19),
            _goal(
              Icons.water_drop_outlined,
              'Nước',
              '${water.toStringAsFixed(1)} / ${waterGoal.toStringAsFixed(1)} L',
              waterProgress,
              const Color(0xFF38BDF8),
            ),
            const SizedBox(height: 19),
            _goal(
              Icons.timer_outlined,
              'Vận động',
              '$activeMinutes / $activeMinutesGoal phút',
              activeMinutesProgress,
              const Color(0xFFA78BFA),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  Widget _goal(
    IconData icon,
    String title,
    String value,
    double progress,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FitAnimatedBar(value: progress, color: color),
      ],
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF132338), Color(0xFF0C1729), Color(0xFF161229)],
        ),
        border: Border(
          right: BorderSide(color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(5, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.secondary.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.16),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.monitor_heart_rounded,
                      color: AppColors.primary,
                      size: 27,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'FITTRACK AI',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 45),

              _item(context, Icons.dashboard_rounded, 'Tổng quan', true),

              _item(
                context,
                Icons.fitness_center_rounded,
                'Luyện tập',
                false,
                onTap: () async {
                  await Navigator.pushNamed(context, AppRoutes.workout);

                  WorkoutService.notifier.value++;
                },
              ),

              _item(
                context,
                Icons.restaurant_rounded,
                'Dinh dưỡng',
                false,
                onTap: () async {
                  await Navigator.pushNamed(context, AppRoutes.nutrition);

                  NutritionService.notifier.value++;
                },
              ),

              _item(
                context,
                Icons.monitor_heart_outlined,
                'Sức khỏe',
                false,
                onTap: () async {
                  await Navigator.pushNamed(context, AppRoutes.health);
                },
              ),

              _item(
                context,
                Icons.camera_alt_outlined,
                'AI Camera',
                false,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.aiCamera);
                },
              ),

              _item(
                context,
                Icons.auto_awesome_rounded,
                'AI Coach',
                false,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.aiCoach);
                },
              ),

              const Spacer(),

              _item(
                context,
                Icons.person_outline_rounded,
                'Hồ sơ',
                false,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.profile);
                },
              ),

              _item(
                context,
                Icons.logout_rounded,
                'Đăng xuất',
                false,
                onTap: () async {
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) {
                      return AlertDialog(
                        title: const Text('Đăng xuất'),
                        content: const Text(
                          'Bạn có chắc chắn muốn đăng xuất khỏi FITTRACK AI?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(dialogContext, false);
                            },
                            child: const Text('Hủy'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(dialogContext, true);
                            },
                            child: const Text('Đăng xuất'),
                          ),
                        ],
                      );
                    },
                  );

                  if (shouldLogout != true) return;

                  try {
                    await AuthService.signOut();

                    if (!context.mounted) return;

                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (route) => false,
                    );
                  } catch (e) {
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Không thể đăng xuất. Vui lòng thử lại.'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String title,
    bool active, {
    VoidCallback? onTap,
  }) {
    return _SidebarMenuTile(
      icon: icon,
      title: title,
      active: active,
      onTap: onTap,
    );
  }
}

class _SidebarMenuTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool active;
  final VoidCallback? onTap;

  const _SidebarMenuTile({
    required this.icon,
    required this.title,
    required this.active,
    this.onTap,
  });

  @override
  State<_SidebarMenuTile> createState() => _SidebarMenuTileState();
}

class _SidebarMenuTileState extends State<_SidebarMenuTile> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.active || _hovered || _pressed;

    final foreground = widget.active
        ? const Color(0xFF061A28)
        : highlighted
        ? Colors.white
        : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: AnimatedScale(
        scale: _pressed
            ? 0.975
            : _hovered
            ? 1.018
            : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: widget.active
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF72EDFF), Color(0xFF08B6ED)],
                  )
                : LinearGradient(
                    colors: highlighted
                        ? [
                            AppColors.primary.withValues(alpha: 0.17),
                            AppColors.secondary.withValues(alpha: 0.13),
                          ]
                        : [Colors.transparent, Colors.transparent],
                  ),
            border: Border.all(
              color: widget.active
                  ? const Color(0xFF83F0FF)
                  : highlighted
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : Colors.transparent,
            ),
            boxShadow: highlighted
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                        alpha: widget.active ? 0.23 : 0.11,
                      ),
                      blurRadius: widget.active ? 23 : 16,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onHover: (value) {
                if (_hovered == value) return;
                setState(() => _hovered = value);
              },
              onHighlightChanged: (value) {
                if (_pressed == value) return;
                setState(() => _pressed = value);
              },
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 3,
                      height: 25,
                      decoration: BoxDecoration(
                        color: highlighted
                            ? widget.active
                                  ? const Color(0xFF073349)
                                  : AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: highlighted && !widget.active
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.45,
                                  ),
                                  blurRadius: 9,
                                ),
                              ]
                            : [],
                      ),
                    ),
                    const SizedBox(width: 11),
                    AnimatedScale(
                      scale: highlighted ? 1.12 : 1.0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        widget.icon,
                        size: 21,
                        color: widget.active
                            ? const Color(0xFF061A28)
                            : highlighted
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: highlighted
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: foreground,
                        ),
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: highlighted ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: widget.active
                            ? const Color(0xFF061A28)
                            : AppColors.primary,
                        size: 19,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileNavigation extends StatefulWidget {
  const _MobileNavigation();

  @override
  State<_MobileNavigation> createState() => _MobileNavigationState();
}

class _MobileNavigationState extends State<_MobileNavigation> {
  bool _openingPage = false;

  Future<void> _openPage(int index) async {
    if (_openingPage || index == 0) return;

    String? route;

    switch (index) {
      case 1:
        route = AppRoutes.workout;
        break;
      case 2:
        route = AppRoutes.nutrition;
        break;
      case 3:
        route = AppRoutes.health;
        break;
      case 4:
        route = AppRoutes.aiCoach;
        break;
    }

    if (route == null) return;

    setState(() {
      _openingPage = true;
    });

    try {
      await Navigator.pushNamed(context, route);

      if (index == 1) {
        WorkoutService.notifier.value++;
      }
    } finally {
      if (mounted) {
        setState(() {
          _openingPage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const icons = [
      Icons.dashboard_rounded,
      Icons.fitness_center_rounded,
      Icons.restaurant_rounded,
      Icons.monitor_heart_rounded,
      Icons.auto_awesome_rounded,
    ];

    const labels = ['Trang chủ', 'Tập luyện', 'Dinh dưỡng', 'Sức khỏe', 'AI'];

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF132F43), Color(0xFF121D35), Color(0xFF221634)],
        ),
        border: Border(
          top: BorderSide(color: AppColors.primary.withValues(alpha: 0.28)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 26,
            offset: const Offset(0, -7),
          ),
          const BoxShadow(
            color: Color(0x55000000),
            blurRadius: 25,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(7, 9, 7, 5),
          child: Row(
            children: List.generate(5, (index) {
              return Expanded(
                child: _MobileNavTile(
                  icon: icons[index],
                  label: labels[index],
                  selected: index == 0,
                  onTap: _openingPage || index == 0
                      ? null
                      : () => _openPage(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _MobileNavTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _MobileNavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_MobileNavTile> createState() => _MobileNavTileState();
}

class _MobileNavTileState extends State<_MobileNavTile> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final highlighted = selected || _hovered;
    final cyan = AppColors.primary;

    return Tooltip(
      message: widget.label,
      child: MouseRegion(
        onEnter: (_) {
          if (mounted) setState(() => _hovered = true);
        },
        onExit: (_) {
          if (mounted) setState(() => _hovered = false);
        },
        child: AnimatedScale(
          scale: _pressed ? 0.91 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      colors: [
                        cyan.withValues(alpha: 0.24),
                        const Color(0xFFA78BFA).withValues(alpha: 0.16),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: selected
                    ? cyan.withValues(alpha: 0.32)
                    : Colors.transparent,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onHighlightChanged: (pressed) {
                  if (mounted) {
                    setState(() {
                      _pressed = pressed;
                    });
                  }
                },
                borderRadius: BorderRadius.circular(15),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 1,
                    vertical: 7,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 270),
                        height: 3,
                        width: selected ? 26 : (_hovered ? 15 : 5),
                        decoration: BoxDecoration(
                          color: selected
                              ? cyan
                              : _hovered
                              ? cyan.withValues(alpha: 0.65)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedScale(
                        scale: highlighted ? 1.12 : 1.0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        child: Icon(
                          widget.icon,
                          size: 22,
                          color: selected
                              ? cyan
                              : highlighted
                              ? const Color(0xFFB3EFFF)
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: selected
                              ? FontWeight.w900
                              : FontWeight.w500,
                          color: selected
                              ? cyan
                              : highlighted
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
