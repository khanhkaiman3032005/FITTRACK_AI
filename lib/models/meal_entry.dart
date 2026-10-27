import 'food_data.dart';

class MealEntry {
  // ID của record trong Supabase.
  // null khi MealEntry vừa được tạo và chưa insert lên Supabase.
  final int? id;

  final FoodData food;
  final String mealType;
  final int quantity;
  final DateTime createdAt;

  const MealEntry({
    this.id,
    required this.food,
    required this.mealType,
    required this.quantity,
    required this.createdAt,
  });

  int get totalCalories => food.calories * quantity;

  double get totalProtein => food.protein * quantity;

  double get totalCarbs => food.carbs * quantity;

  double get totalFat => food.fat * quantity;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'food': food.toJson(),
      'mealType': mealType,
      'quantity': quantity,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MealEntry.fromJson(Map<String, dynamic> json) {
    return MealEntry(
      id: (json['id'] as num?)?.toInt(),
      food: FoodData.fromJson(Map<String, dynamic>.from(json['food'])),
      mealType: json['mealType'] as String,
      quantity: (json['quantity'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
