import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/food_data.dart';
import '../../models/meal_entry.dart';
import '../../services/nutrition_service.dart';

class AddMealScreen extends StatefulWidget {
  final FoodData food;

  const AddMealScreen({super.key, required this.food});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  String _selectedMeal = 'Bữa trưa';
  int _quantity = 1;

  final List<String> _mealTypes = ['Bữa sáng', 'Bữa trưa', 'Bữa tối', 'Ăn nhẹ'];

  int get totalCalories => widget.food.calories * _quantity;

  double get totalProtein => widget.food.protein * _quantity;

  double get totalCarbs => widget.food.carbs * _quantity;

  double get totalFat => widget.food.fat * _quantity;

  void _increaseQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decreaseQuantity() {
    if (_quantity <= 1) return;

    setState(() {
      _quantity--;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thêm vào bữa ăn',
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
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFoodCard(),

                      const SizedBox(height: 28),

                      const Text(
                        'Chọn bữa ăn',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 14),

                      _buildMealSelector(),

                      const SizedBox(height: 30),

                      const Text(
                        'Số khẩu phần',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 14),

                      _buildQuantitySelector(),

                      const SizedBox(height: 30),

                      const Text(
                        'Tổng dinh dưỡng',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 14),

                      _buildNutritionSummary(),

                      const SizedBox(height: 32),

                      _buildAddButton(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFoodCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF101827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.food.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '${widget.food.calories} kcal • ${widget.food.unit}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _mealTypes.map((meal) {
        final selected = meal == _selectedMeal;

        return ChoiceChip(
          label: Text(meal),
          selected: selected,
          onSelected: (_) {
            setState(() {
              _selectedMeal = meal;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF101827),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _quantityButton(
            icon: Icons.remove_rounded,
            onPressed: _decreaseQuantity,
          ),

          const SizedBox(width: 30),

          Column(
            children: [
              Text(
                '$_quantity',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'khẩu phần',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),

          const SizedBox(width: 30),

          _quantityButton(
            icon: Icons.add_rounded,
            onPressed: _increaseQuantity,
          ),
        ],
      ),
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 50,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
        ),
        child: Icon(icon),
      ),
    );
  }

  Widget _buildNutritionSummary() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _nutritionItem(
          'Calories',
          '$totalCalories kcal',
          Icons.local_fire_department_rounded,
        ),
        _nutritionItem(
          'Protein',
          '${totalProtein.toStringAsFixed(0)} g',
          Icons.fitness_center_rounded,
        ),
        _nutritionItem(
          'Carbs',
          '${totalCarbs.toStringAsFixed(0)} g',
          Icons.grain_rounded,
        ),
        _nutritionItem(
          'Chất béo',
          '${totalFat.toStringAsFixed(0)} g',
          Icons.water_drop_rounded,
        ),
      ],
    );
  }

  Widget _nutritionItem(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF101827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),

          const SizedBox(height: 6),

          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _addMeal,
        icon: const Icon(Icons.check_circle_outline_rounded),
        label: const Text(
          'Thêm vào nhật ký',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _addMeal() async {
    final entry = MealEntry(
      food: widget.food,
      mealType: _selectedMeal,
      quantity: _quantity,
      createdAt: DateTime.now(),
    );

    await NutritionService.addMeal(entry);

    if (!mounted) return;

    Navigator.pop(context, true);
  }
}
