import '../../widgets/fittrack_motion.dart';
import 'workout_design.dart';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'workout_screen.dart';
import 'daily_guardian_gate.dart';
import 'exercise_video_player.dart';

class ExerciseDetailScreen extends StatelessWidget {
  final ExerciseData exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080D19),
      body: WorkoutBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 850;

              return SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? 32 : 18),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(context),
                        const SizedBox(height: 24),
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    FitEntrance(child: _buildHero()),
                                    const SizedBox(height: 18),
                                    ExerciseVideoPanel(
                                      exerciseName: exercise.name,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 22),
                              Expanded(child: _buildInformation(context)),
                            ],
                          )
                        else ...[
                          FitEntrance(child: _buildHero()),
                          const SizedBox(height: 18),
                          ExerciseVideoPanel(exerciseName: exercise.name),
                          const SizedBox(height: 22),
                          _buildInformation(context),
                        ],
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
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Chi tiết bài tập',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
        ),
        const Icon(Icons.auto_awesome_rounded, color: WorkoutColors.cyan),
      ],
    );
  }

  Widget _buildHero() {
    return WorkoutHero(
      eyebrow: 'EXERCISE SPOTLIGHT',
      title: exercise.name,
      subtitle:
          '${exercise.category} • ${exercise.difficulty}\n'
          '${exercise.sets} hiệp × ${exercise.repsPerSet} lần mỗi hiệp',
      icon: exercise.icon,
    );
  }

  Widget _buildInformation(BuildContext context) {
    return FitEntrance(
      child: FitGlassPanel(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FitSectionTitle(
              icon: Icons.analytics_outlined,
              title: 'Thông tin bài tập',
              subtitle: 'Chuẩn bị cho buổi luyện tập',
              accent: WorkoutColors.cyan,
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    Icons.schedule_rounded,
                    'Thời gian',
                    exercise.duration,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    Icons.local_fire_department_rounded,
                    'Calories',
                    exercise.calories,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const FitSectionTitle(
              icon: Icons.format_list_numbered_rounded,
              title: 'Hướng dẫn',
              subtitle: 'Ba bước tập luyện an toàn',
              accent: WorkoutColors.purple,
            ),
            const SizedBox(height: 20),
            _buildInstruction(
              1,
              'Chuẩn bị',
              'Giữ cơ thể ở tư thế đúng và ổn định trước khi bắt đầu.',
            ),
            _buildInstruction(
              2,
              'Thực hiện',
              'Thực hiện động tác chậm rãi, kiểm soát chuyển động '
                  'và nhịp thở.',
            ),
            _buildInstruction(
              3,
              'Hoàn thành',
              'Giữ đúng kỹ thuật trong suốt bài tập và nghỉ khi cần thiết.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DailyGuardianExerciseGate(exercise: exercise),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text(
                  'Bắt đầu luyện tập',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: WorkoutColors.cyan,
                  foregroundColor: const Color(0xFF061624),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String title, String value) {
    final accent = title == 'Calories'
        ? WorkoutColors.orange
        : WorkoutColors.cyan;

    return FitGlowCard(
      accent: accent,
      padding: const EdgeInsets.all(15),
      child: SizedBox(
        height: 98,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 23),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(int number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 37,
            height: 37,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D6682), Color(0xFF45347A)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.5,
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
