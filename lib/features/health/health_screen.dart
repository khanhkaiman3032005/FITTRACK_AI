import 'package:flutter/material.dart';

import '../../models/health_data.dart';
import '../../services/health_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/fittrack_motion.dart';
import 'health_design.dart';
import 'update_health_screen.dart';
import 'update_progress_screen.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  static const Color _cyan = Color(0xFF11BFF3);
  static const Color _mint = Color(0xFF2DD4BF);
  static const Color _purple = Color(0xFFA78BFA);
  static const Color _orange = Color(0xFFFFB15C);
  static const Color _secondary = Color(0xFF94A3B8);

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  Future<void> _openProgress() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const UpdateProgressScreen()),
    );

    if (updated == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _openHealthUpdate() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const UpdateHealthScreen()),
    );

    if (updated == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: HealthService.notifier,
      builder: (context, version, child) {
        final health = HealthService.data;

        return Scaffold(
          backgroundColor: const Color(0xFF080D19),
          appBar: AppBar(
            title: const Text(
              'Sức khỏe',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            backgroundColor: const Color(0xFF0D1728),
            elevation: 0,
          ),
          body: HealthBackdrop(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 820;

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      isDesktop ? 32 : 18,
                      22,
                      isDesktop ? 32 : 18,
                      42,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FitEntrance(
                              child: HealthHero(
                                eyebrow: 'HEALTH ANALYTICS',
                                title: 'Sức khỏe của bạn.\nHành trình của bạn.',
                                subtitle:
                                    'Theo dõi các chỉ số cơ thể và tiến độ '
                                    'mỗi ngày cùng FITTRACK AI.',
                                icon: Icons.favorite_rounded,
                              ),
                            ),
                            const SizedBox(height: 29),
                            const FitSectionTitle(
                              icon: Icons.monitor_heart_rounded,
                              title: 'Tổng quan sức khỏe',
                              subtitle: 'Các chỉ số cơ thể hiện tại',
                              accent: _cyan,
                            ),
                            const SizedBox(height: 17),
                            _buildMetrics(health),
                            const SizedBox(height: 28),
                            LayoutBuilder(
                              builder: (context, innerConstraints) {
                                if (innerConstraints.maxWidth >= 800) {
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _buildProgressCard(health),
                                      ),
                                      const SizedBox(width: 18),
                                      Expanded(child: _buildBodyCard(health)),
                                    ],
                                  );
                                }

                                return Column(
                                  children: [
                                    _buildProgressCard(health),
                                    const SizedBox(height: 18),
                                    _buildBodyCard(health),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: FilledButton.icon(
                                onPressed: _openHealthUpdate,
                                icon: const Icon(Icons.edit_rounded),
                                label: const Text(
                                  'Cập nhật chỉ số cơ thể',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: _cyan,
                                  foregroundColor: const Color(0xFF071523),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetrics(HealthData health) {
    final profile = ProfileService.profile;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final count = width >= 830
            ? 4
            : width >= 310
            ? 2
            : 1;
        final cardWidth = (width - (count - 1) * 12) / count;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              [
                _metric(
                  Icons.monitor_weight_rounded,
                  'BMI',
                  health.bmi.toStringAsFixed(1),
                  health.bmiStatus,
                  _purple,
                ),
                _metric(
                  Icons.scale_rounded,
                  'Cân nặng',
                  '${health.weight.toStringAsFixed(0)} kg',
                  'Mục tiêu ${profile.targetWeight.toStringAsFixed(0)} kg',
                  _orange,
                ),
                _metric(
                  Icons.favorite_border_rounded,
                  'Nhịp tim',
                  '${health.heartRate} bpm',
                  health.heartRate > 0 ? 'Đã ghi nhận' : 'Chưa cập nhật',
                  const Color(0xFFFF7185),
                ),
                _metric(
                  Icons.directions_walk_rounded,
                  'Bước chân',
                  _formatNumber(health.steps),
                  '/ ${_formatNumber(profile.dailyStepGoal)} bước',
                  _mint,
                ),
              ].map((card) {
                return SizedBox(width: cardWidth, child: card);
              }).toList(),
        );
      },
    );
  }

  Widget _metric(
    IconData icon,
    String title,
    String value,
    String subtitle,
    Color color,
  ) {
    return FitEntrance(
      child: FitGlowCard(
        accent: color,
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 136,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(color: _secondary, fontSize: 12),
              ),
              const SizedBox(height: 5),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: FittedBox(
                  key: ValueKey(value),
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color.withValues(alpha: 0.85),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(HealthData health) {
    final profile = ProfileService.profile;

    final stepGoal = profile.dailyStepGoal;
    final waterGoal = profile.dailyWaterGoal;
    final activeGoal = profile.dailyActiveMinutesGoal;

    final stepsProgress = stepGoal <= 0
        ? 0.0
        : (health.steps / stepGoal).clamp(0.0, 1.0).toDouble();

    final waterProgress = waterGoal <= 0
        ? 0.0
        : (health.water / waterGoal).clamp(0.0, 1.0).toDouble();

    final activeProgress = activeGoal <= 0
        ? 0.0
        : (health.activeMinutes / activeGoal).clamp(0.0, 1.0).toDouble();

    return FitEntrance(
      child: FitGlowCard(
        accent: _cyan,
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FitSectionTitle(
              icon: Icons.track_changes_rounded,
              title: 'Tiến độ hôm nay',
              subtitle: 'Mục tiêu sức khỏe mỗi ngày',
              accent: _cyan,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: HealthRing(
                    label: 'Bước chân',
                    progress: stepsProgress,
                    color: _mint,
                  ),
                ),
                Expanded(
                  child: HealthRing(
                    label: 'Nước',
                    progress: waterProgress,
                    color: _cyan,
                  ),
                ),
                Expanded(
                  child: HealthRing(
                    label: 'Vận động',
                    progress: activeProgress,
                    color: _purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _progress(
              'Bước chân',
              '${_formatNumber(health.steps)} / ${_formatNumber(stepGoal)}',
              stepsProgress,
              _mint,
            ),
            const SizedBox(height: 19),
            _progress(
              'Nước',
              '${health.water.toStringAsFixed(1)} / ${waterGoal.toStringAsFixed(1)} L',
              waterProgress,
              _cyan,
            ),
            const SizedBox(height: 19),
            _progress(
              'Vận động',
              '${health.activeMinutes} / $activeGoal phút',
              activeProgress,
              _purple,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openProgress,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Cập nhật tiến độ'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _cyan,
                  side: const BorderSide(color: _cyan),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progress(String title, String value, double progress, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(color: _secondary, fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FitAnimatedBar(value: progress, color: color),
      ],
    );
  }

  Widget _buildBodyCard(HealthData health) {
    final sleepHours = health.sleepHours.floor();
    final sleepMinutes = ((health.sleepHours - sleepHours) * 60).round();

    final sleepText = sleepMinutes == 0
        ? '$sleepHours giờ'
        : '$sleepHours giờ $sleepMinutes phút';

    return FitEntrance(
      child: FitGlowCard(
        accent: _purple,
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FitSectionTitle(
              icon: Icons.accessibility_new_rounded,
              title: 'Chỉ số cơ thể',
              subtitle: 'Thông tin sức khỏe cá nhân',
              accent: _purple,
            ),
            const SizedBox(height: 25),
            _bodyRow(
              Icons.height_rounded,
              'Chiều cao',
              '${health.height.toStringAsFixed(0)} cm',
            ),
            const Divider(height: 30),
            _bodyRow(
              Icons.scale_outlined,
              'Cân nặng',
              '${health.weight.toStringAsFixed(0)} kg',
            ),
            const Divider(height: 30),
            _bodyRow(
              Icons.monitor_weight_outlined,
              'BMI',
              health.bmi.toStringAsFixed(1),
            ),
            const Divider(height: 30),
            _bodyRow(Icons.bedtime_rounded, 'Giấc ngủ', sleepText),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget _bodyRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: _purple.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: _purple, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: _secondary, fontSize: 13),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ],
    );
  }
}
