import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../models/food_data.dart';

class FoodDetailScreen extends StatelessWidget {
  final FoodData food;

  const FoodDetailScreen({super.key, required this.food});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chi tiết món ăn',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;

            return SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 32 : 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: isDesktop
                      ? _buildDesktop(context)
                      : _buildMobile(context),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildFoodHero()),

        const SizedBox(width: 30),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitle(),
              const SizedBox(height: 24),
              _buildNutritionGrid(),
              const SizedBox(height: 30),
              _buildDescription(),
              const SizedBox(height: 30),
              _buildAddButton(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobile(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFoodHero(),

        const SizedBox(height: 24),

        _buildTitle(),

        const SizedBox(height: 20),

        _buildNutritionGrid(),

        const SizedBox(height: 26),

        _buildDescription(),

        const SizedBox(height: 30),

        _buildAddButton(context),
      ],
    );
  }

  Widget _buildFoodHero() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.35),
            AppColors.primary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              color: AppColors.primary,
              size: 45,
            ),
          ),

          const SizedBox(height: 22),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              food.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '${food.category} • ${food.unit}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Thông tin dinh dưỡng',
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildNutritionGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _nutritionCard(
          Icons.local_fire_department_rounded,
          'Calories',
          '${food.calories}',
          'kcal',
        ),
        _nutritionCard(
          Icons.fitness_center_rounded,
          'Protein',
          food.protein.toStringAsFixed(0),
          'g',
        ),
        _nutritionCard(
          Icons.grain_rounded,
          'Carbs',
          food.carbs.toStringAsFixed(0),
          'g',
        ),
        _nutritionCard(
          Icons.water_drop_rounded,
          'Chất béo',
          food.fat.toStringAsFixed(0),
          'g',
        ),
      ],
    );
  }

  Widget _nutritionCard(
    IconData icon,
    String title,
    String value,
    String unit,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF101827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary),

          const SizedBox(height: 8),

          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 4),

          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 4,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF101827),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 10),

          Text(
            'Giá trị dinh dưỡng được tính theo khẩu phần '
            'đã chọn. Bạn có thể thêm món ăn này vào '
            'nhật ký dinh dưỡng trong ngày.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            AppRoutes.addMeal,
            arguments: food,
          );

          if (result == true && context.mounted) {
            Navigator.pop(context, true);
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Thêm vào bữa ăn',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
