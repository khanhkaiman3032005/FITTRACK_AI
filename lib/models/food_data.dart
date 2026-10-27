class FoodData {
  final String name;
  final String category;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String unit;

  const FoodData({
    required this.name,
    required this.category,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.unit,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'unit': unit,
    };
  }

  factory FoodData.fromJson(Map<String, dynamic> json) {
    return FoodData(
      name: json['name'] as String,
      category: json['category'] as String,
      calories: (json['calories'] as num).toInt(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      unit: json['unit'] as String,
    );
  }
}
