import 'daily_guardian_gate.dart';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

import '../../core/routes/app_routes.dart';
import '../../widgets/fittrack_motion.dart';
import 'workout_design.dart';

class WorkoutCatalogScreen extends StatefulWidget {
  const WorkoutCatalogScreen({super.key});

  @override
  State<WorkoutCatalogScreen> createState() => _WorkoutCatalogScreenState();
}

class _WorkoutCatalogScreenState extends State<WorkoutCatalogScreen> {
  String selectedCategory = 'Tất cả';
  String searchText = '';

  final categories = [
    'Tất cả',
    'Toàn thân',
    'Ngực',
    'Chân',
    'Lưng',
    'Vai',
    'Tay',
    'Core',
  ];

  final exercises = const [
    ExerciseData(
      name: 'Squat',
      category: 'Chân',
      difficulty: 'Cơ bản',
      duration: '12 phút',
      calories: '120 kcal',
      icon: Icons.accessibility_new_rounded,
      sets: 3,
      repsPerSet: 10,
    ),
    ExerciseData(
      name: 'Push Up',
      category: 'Ngực',
      difficulty: 'Cơ bản',
      duration: '10 phút',
      calories: '90 kcal',
      icon: Icons.fitness_center_rounded,
      sets: 3,
      repsPerSet: 12,
    ),
    ExerciseData(
      name: 'Plank',
      category: 'Core',
      difficulty: 'Trung bình',
      duration: '8 phút',
      calories: '70 kcal',
      icon: Icons.timer_outlined,
      sets: 3,
      repsPerSet: 1,
    ),
    ExerciseData(
      name: 'Lunge',
      category: 'Chân',
      difficulty: 'Trung bình',
      duration: '12 phút',
      calories: '110 kcal',
      icon: Icons.directions_walk_rounded,
      sets: 3,
      repsPerSet: 10,
    ),
    ExerciseData(
      name: 'Jumping Jack',
      category: 'Toàn thân',
      difficulty: 'Cơ bản',
      duration: '10 phút',
      calories: '130 kcal',
      icon: Icons.directions_run_rounded,
      sets: 3,
      repsPerSet: 20,
    ),
    ExerciseData(
      name: 'Shoulder Press',
      category: 'Vai',
      difficulty: 'Trung bình',
      duration: '15 phút',
      calories: '100 kcal',
      icon: Icons.sports_gymnastics_rounded,
      sets: 3,
      repsPerSet: 12,
    ),
  ];

  List<ExerciseData> get filteredExercises {
    return exercises.where((exercise) {
      final categoryMatch =
          selectedCategory == 'Tất cả' || exercise.category == selectedCategory;

      final searchMatch = exercise.name.toLowerCase().contains(
        searchText.toLowerCase(),
      );

      return categoryMatch && searchMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080D19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1728),
        elevation: 0,
        title: const Text(
          'Luyện tập',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: WorkoutBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final desktop = constraints.maxWidth >= 900;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  desktop ? 32 : 18,
                  22,
                  desktop ? 32 : 18,
                  42,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FitEntrance(child: _buildHeader()),
                        const SizedBox(height: 27),
                        _buildSearch(),
                        const SizedBox(height: 20),
                        _buildCategories(),
                        const SizedBox(height: 30),
                        _buildSectionTitle(),
                        const SizedBox(height: 18),
                        _buildExerciseGrid(constraints.maxWidth),
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

  Widget _buildHeader() {
    return const WorkoutHero(
      eyebrow: 'FITTRACK TRAINING STUDIO',
      title: 'Mạnh mẽ hơn.\nMỗi ngày một bước.',
      subtitle:
          'Khám phá các bài tập phù hợp với mục tiêu '
          'và xây dựng thói quen vận động cùng FITTRACK AI.',
      icon: Icons.fitness_center_rounded,
    );
  }

  Widget _buildSearch() {
    return TextField(
      onChanged: (value) {
        setState(() {
          searchText = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Tìm bài tập yêu thích...',
        prefixIcon: const Icon(Icons.search_rounded, color: WorkoutColors.cyan),
        filled: true,
        fillColor: const Color(0xFF142039),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: WorkoutColors.cyan.withValues(alpha: 0.18),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: WorkoutColors.cyan, width: 1.5),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: 9);
        },
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = selectedCategory == category;

          return ChoiceChip(
            label: Text(category),
            selected: selected,
            selectedColor: WorkoutColors.cyan,
            backgroundColor: const Color(0xFF152039),
            showCheckmark: false,
            side: BorderSide(
              color: selected
                  ? WorkoutColors.cyan
                  : Colors.white.withValues(alpha: 0.10),
            ),
            labelStyle: TextStyle(
              color: selected ? const Color(0xFF061624) : Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (value) {
              setState(() {
                selectedCategory = category;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle() {
    return FitSectionTitle(
      icon: Icons.grid_view_rounded,
      title: 'Khám phá bài tập',
      subtitle: '${filteredExercises.length} bài tập phù hợp',
      accent: WorkoutColors.cyan,
    );
  }

  Widget _buildExerciseGrid(double width) {
    if (filteredExercises.isEmpty) {
      return const FitGlassPanel(
        child: SizedBox(
          height: 180,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 45,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 12),
                Text('Không tìm thấy bài tập phù hợp'),
              ],
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        int columns = 1;

        if (availableWidth >= 1020) {
          columns = 3;
        } else if (availableWidth >= 640) {
          columns = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredExercises.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 235,
          ),
          itemBuilder: (context, index) {
            return ExerciseCard(exercise: filteredExercises[index]);
          },
        );
      },
    );
  }
}

class ExerciseData {
  final String name;
  final String category;
  final String difficulty;
  final String duration;
  final String calories;
  final IconData icon;

  final int sets;
  final int repsPerSet;

  const ExerciseData({
    required this.name,
    required this.category,
    required this.difficulty,
    required this.duration,
    required this.calories,
    required this.icon,
    required this.sets,
    required this.repsPerSet,
  });

  int get targetReps => sets * repsPerSet;
}

class ExerciseCard extends StatelessWidget {
  final ExerciseData exercise;

  const ExerciseCard({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final accent = WorkoutColors.forCategory(exercise.category);

    return FitEntrance(
      child: FitGlowCard(
        accent: accent,
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.exerciseDetail,
                arguments: exercise,
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 49,
                        height: 49,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(exercise.icon, color: accent, size: 26),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          exercise.difficulty,
                          style: TextStyle(
                            color: accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    exercise.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${exercise.category} • '
                    '${exercise.sets} hiệp × ${exercise.repsPerSet} lần',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 17),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, color: accent, size: 16),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          exercise.duration,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.local_fire_department_rounded,
                        color: WorkoutColors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          exercise.calories,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: accent,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Guard EVERY entrance including direct Navigator routes.
class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});
  @override
  Widget build(BuildContext context) => const DailyGuardianWorkoutGate();
}
