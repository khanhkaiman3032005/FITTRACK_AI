import 'package:flutter/material.dart';

import '../../features/workout/exercise_detail_screen.dart';
import '../../features/workout/workout_screen.dart';

import '../../features/nutrition/food_detail_screen.dart';
import '../../models/food_data.dart';
import '../../features/nutrition/add_meal_screen.dart';
import '../../features/ai_coach/ai_coach_screen.dart';
import '../../features/ai_camera/ai_camera_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';

  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  static const String dashboard = '/dashboard';
  static const String workout = '/workout';

  static const String exerciseDetail = '/exercise-detail';

  static const String nutrition = '/nutrition';
  static const String foodDetail = '/food-detail';
  static const String addMeal = '/add-meal';

  static const String health = '/health';
  static const String aiCoach = '/ai-coach';
  static const String aiCamera = '/ai-camera';

  static const String weeklyReport = '/weekly-report';

  static const String profile = '/profile';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case exerciseDetail:
        final exercise = settings.arguments as ExerciseData;

        return MaterialPageRoute(
          builder: (_) => ExerciseDetailScreen(exercise: exercise),
        );

      case foodDetail:
        final food = settings.arguments as FoodData;

        return MaterialPageRoute(builder: (_) => FoodDetailScreen(food: food));

      case addMeal:
        final food = settings.arguments as FoodData;

        return MaterialPageRoute(builder: (_) => AddMealScreen(food: food));

      case aiCoach:
        return MaterialPageRoute(builder: (_) => const AiCoachScreen());

      case aiCamera:
        return MaterialPageRoute(builder: (_) => const AiCameraScreen());

      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Không tìm thấy trang'))),
        );
    }
  }
}
