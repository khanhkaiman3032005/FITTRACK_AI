import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../models/food_data.dart';
import '../../models/meal_entry.dart';
import '../../services/health_service.dart';
import '../../services/nutrition_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/fittrack_motion.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'Tất cả';

  final List<String> _categories = [
    'Tất cả',
    'Bữa sáng',
    'Bữa trưa',
    'Bữa tối',
    'Ăn nhẹ',
  ];

  final List<FoodData> _foods = const [
    FoodData(
      name: 'Ức gà & cơm gạo lứt',
      category: 'Bữa trưa',
      calories: 420,
      protein: 38,
      carbs: 45,
      fat: 9,
      unit: '1 phần',
    ),
    FoodData(
      name: 'Yến mạch & chuối',
      category: 'Bữa sáng',
      calories: 310,
      protein: 12,
      carbs: 52,
      fat: 7,
      unit: '1 tô',
    ),
    FoodData(
      name: 'Salad cá hồi',
      category: 'Bữa tối',
      calories: 360,
      protein: 32,
      carbs: 18,
      fat: 17,
      unit: '1 phần',
    ),
    FoodData(
      name: 'Sữa chua Hy Lạp',
      category: 'Ăn nhẹ',
      calories: 150,
      protein: 15,
      carbs: 12,
      fat: 4,
      unit: '1 hộp',
    ),
  ];

  List<FoodData> get _filteredFoods {
    final keyword = _searchController.text.trim().toLowerCase();

    return _foods.where((food) {
      final matchesCategory =
          _selectedCategory == 'Tất cả' || food.category == _selectedCategory;

      final matchesSearch =
          keyword.isEmpty || food.name.toLowerCase().contains(keyword);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _refreshNutrition() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NutritionService.notifier,
      builder: (context, nutritionVersion, child) {
        return ValueListenableBuilder<int>(
          valueListenable: HealthService.notifier,
          builder: (context, healthVersion, child) {
            return Scaffold(
              backgroundColor: const Color(0xFF070C18),
              appBar: AppBar(
                backgroundColor: const Color(0xFF0C1526),
                elevation: 0,
                title: const Text(
                  'Dinh dưỡng',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              body: Stack(
                children: [
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF091C2B),
                            Color(0xFF090F1F),
                            Color(0xFF17102B),
                            Color(0xFF080D19),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -130,
                    top: -120,
                    child: IgnorePointer(
                      child: Container(
                        width: 370,
                        height: 370,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.13),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -140,
                    bottom: -150,
                    child: IgnorePointer(
                      child: Container(
                        width: 410,
                        height: 410,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.secondary.withValues(alpha: 0.12),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth >= 900;

                        return SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            isDesktop ? 32 : 18,
                            22,
                            isDesktop ? 32 : 18,
                            40,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1180),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FitEntrance(child: _buildHero()),
                                  const SizedBox(height: 20),
                                  _buildAiCameraButton(),
                                  const SizedBox(height: 30),
                                  const FitSectionTitle(
                                    icon: Icons.insights_rounded,
                                    title: 'Tổng quan dinh dưỡng',
                                    subtitle: 'Theo dõi mục tiêu mỗi ngày',
                                  ),
                                  const SizedBox(height: 18),
                                  _buildDailySummary(),
                                  const SizedBox(height: 18),
                                  _buildMacroSummary(),
                                  const SizedBox(height: 32),
                                  _buildTodayLog(),
                                  const SizedBox(height: 32),
                                  const FitSectionTitle(
                                    icon: Icons.restaurant_menu_rounded,
                                    title: 'Khám phá thực đơn',
                                    subtitle: 'Lựa chọn món ăn phù hợp với bạn',
                                  ),
                                  const SizedBox(height: 18),
                                  _buildSearchAndFilters(),
                                  const SizedBox(height: 20),
                                  _buildFoodList(_filteredFoods, isDesktop),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHero() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF124A59), Color(0xFF133048), Color(0xFF272044)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.30),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.10),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Positioned(
                  right: -65,
                  top: -80,
                  child: IgnorePointer(
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.28),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(compact ? 22 : 30),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SMART NUTRITION',
                              style: TextStyle(
                                color: Color(0xFF81E9FF),
                                fontSize: 11,
                                letterSpacing: 1.7,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 13),
                            Text(
                              'Ăn uống thông minh.\nSống khỏe mỗi ngày.',
                              style: TextStyle(
                                fontSize: compact ? 23 : 30,
                                height: 1.2,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Theo dõi năng lượng và xây dựng '
                              'thói quen dinh dưỡng lành mạnh.',
                              style: TextStyle(
                                color: Color(0xFFC0D3E2),
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!compact) ...[
                        const SizedBox(width: 24),
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: const Icon(
                            Icons.restaurant_rounded,
                            size: 46,
                            color: Color(0xFF7FE8FF),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAiCameraButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.aiCamera);
        },
        icon: const Icon(Icons.auto_awesome_rounded),
        label: const Text(
          'Nhận diện món ăn bằng AI Camera',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: const Color(0xFF061623),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildDailySummary() {
    final calories = NutritionService.totalCalories;
    final calorieGoal = ProfileService.profile.dailyCalorieGoal;

    final water = HealthService.data.water;
    final waterGoal = ProfileService.profile.dailyWaterGoal;

    final calorieProgress = calorieGoal <= 0
        ? 0.0
        : (calories / calorieGoal).clamp(0.0, 1.0).toDouble();

    final waterProgress = waterGoal <= 0
        ? 0.0
        : (water / waterGoal).clamp(0.0, 1.0).toDouble();

    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            icon: Icons.local_fire_department_rounded,
            title: 'Năng lượng',
            value: '$calories',
            target: '/ $calorieGoal kcal',
            progress: calorieProgress,
            accent: const Color(0xFFFFB15C),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            icon: Icons.water_drop_rounded,
            title: 'Nước uống',
            value: water.toStringAsFixed(1),
            target: '/ ${waterGoal.toStringAsFixed(1)} L',
            progress: waterProgress,
            accent: const Color(0xFF38BDF8),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
    required String target,
    required double progress,
    required Color accent,
  }) {
    return FitEntrance(
      child: FitGlowCard(
        accent: accent,
        padding: const EdgeInsets.all(15),
        child: SizedBox(
          height: 146,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: accent, size: 19),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: Text(
                            value,
                            key: ValueKey(value),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          target,
                          maxLines: 2,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 950),
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedValue, child) {
                      return SizedBox(
                        width: 54,
                        height: 54,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox.expand(
                              child: CircularProgressIndicator(
                                value: animatedValue,
                                strokeWidth: 6,
                                strokeCap: StrokeCap.round,
                                backgroundColor: const Color(0xFF2B344B),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  accent,
                                ),
                              ),
                            ),
                            Text(
                              '${(animatedValue * 100).round()}%',
                              style: const TextStyle(
                                fontSize: 10,
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
              const Spacer(),
              FitAnimatedBar(value: progress, color: accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroSummary() {
    final meals = NutritionService.todayEntries;

    final protein = meals.fold<double>(
      0,
      (sum, entry) => sum + entry.food.protein * entry.quantity,
    );

    final carbs = meals.fold<double>(
      0,
      (sum, entry) => sum + entry.food.carbs * entry.quantity,
    );

    final fat = meals.fold<double>(
      0,
      (sum, entry) => sum + entry.food.fat * entry.quantity,
    );

    return Row(
      children: [
        Expanded(
          child: _macroCard(
            'Protein',
            '${protein.toStringAsFixed(0)} g',
            Icons.fitness_center_rounded,
            const Color(0xFF2DD4BF),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _macroCard(
            'Carb',
            '${carbs.toStringAsFixed(0)} g',
            Icons.grain_rounded,
            const Color(0xFFA78BFA),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _macroCard(
            'Fat',
            '${fat.toStringAsFixed(0)} g',
            Icons.opacity_rounded,
            const Color(0xFFFFB15C),
          ),
        ),
      ],
    );
  }

  Widget _macroCard(String title, String value, IconData icon, Color accent) {
    return FitGlowCard(
      accent: accent,
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: accent),
          const SizedBox(height: 10),
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
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayLog() {
    final meals = NutritionService.todayEntries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FitSectionTitle(
          icon: Icons.history_rounded,
          title: 'Nhật ký hôm nay',
          subtitle: '${meals.length} món đã ghi nhận',
          accent: const Color(0xFF2DD4BF),
        ),
        const SizedBox(height: 16),
        if (meals.isEmpty)
          const FitGlassPanel(
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  children: [
                    Icon(
                      Icons.no_meals_outlined,
                      size: 42,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Chưa có món ăn hôm nay',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'Hãy thêm món ăn để bắt đầu theo dõi dinh dưỡng.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...meals.map(_buildMealEntry),
      ],
    );
  }

  Widget _buildMealEntry(MealEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FitGlowCard(
        accent: const Color(0xFF2DD4BF),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 49,
              height: 49,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF105A62), Color(0xFF12374B)],
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.restaurant_rounded,
                color: Color(0xFF5DE7DA),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.food.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${entry.mealType} • ${entry.quantity} khẩu phần',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${entry.totalCalories} kcal',
                    style: const TextStyle(
                      color: Color(0xFF5DE7DA),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Xóa khỏi nhật ký',
              onPressed: () async {
                await NutritionService.removeMeal(entry);
              },
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFFF7185),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: 'Tìm kiếm món ăn yêu thích...',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: const Color(0xFF142039),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((category) {
              final selected = category == _selectedCategory;

              return Padding(
                padding: const EdgeInsets.only(right: 9),
                child: ChoiceChip(
                  label: Text(category),
                  selected: selected,
                  selectedColor: AppColors.primary,
                  backgroundColor: const Color(0xFF152039),
                  side: BorderSide(
                    color: selected
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.10),
                  ),
                  labelStyle: TextStyle(
                    color: selected ? const Color(0xFF061624) : Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onSelected: (value) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFoodList(List<FoodData> foods, bool isDesktop) {
    if (foods.isEmpty) {
      return const FitGlassPanel(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 36),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 42,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 10),
                Text('Không tìm thấy món ăn phù hợp'),
              ],
            ),
          ),
        ),
      );
    }

    if (isDesktop) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: foods.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.6,
        ),
        itemBuilder: (context, index) {
          return _foodCard(foods[index]);
        },
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: foods.length,
      separatorBuilder: (context, index) {
        return const SizedBox(height: 12);
      },
      itemBuilder: (context, index) {
        return _foodCard(foods[index]);
      },
    );
  }

  Widget _foodCard(FoodData food) {
    return FitGlowCard(
      accent: AppColors.primary,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF104B60), Color(0xFF142E4A)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  food.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${food.category} • ${food.unit}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    _nutritionValue('${food.calories} kcal'),
                    _nutritionValue('P ${food.protein.toStringAsFixed(0)}g'),
                    _nutritionValue('C ${food.carbs.toStringAsFixed(0)}g'),
                    _nutritionValue('F ${food.fat.toStringAsFixed(0)}g'),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Xem món ăn',
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                AppRoutes.foodDetail,
                arguments: food,
              );

              if (result == true && mounted) {
                _refreshNutrition();
              }
            },
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.primary,
              size: 17,
            ),
          ),
        ],
      ),
    );
  }

  Widget _nutritionValue(String value) {
    return Text(
      value,
      style: const TextStyle(
        color: Color(0xFF81DFFF),
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
