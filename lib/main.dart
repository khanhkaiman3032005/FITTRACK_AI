import 'widgets/guardian_profile_shortcut.dart';

import 'package:flutter/material.dart';

import 'widgets/coach_proactive_wrapper.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'widgets/fittrack_motion.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/workout/workout_screen.dart';
import 'features/nutrition/nutrition_screen.dart';

import 'features/health/health_screen.dart';

import 'services/health_service.dart';
import 'services/nutrition_service.dart';
import 'services/workout_service.dart';
import 'services/daily_history_service.dart';
import 'features/ai_coach/ai_coach_screen.dart';
import 'features/health/weekly_report_screen.dart';

import 'services/profile_service.dart';
import 'features/profile/profile_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/auth_service.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('1. Flutter initialized');

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception(
      'Thiếu SUPABASE_URL hoặc SUPABASE_ANON_KEY trong config/dev.json',
    );
  }

  debugPrint('2. Bat dau Supabase');

  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);

  debugPrint('3. Supabase OK');

  final rememberLogin = await AuthService.getRememberLogin();
  final returningFromGoogle = await AuthService.takeGoogleOAuthPending();

  if (!rememberLogin &&
      !returningFromGoogle &&
      AuthService.currentSession != null) {
    try {
      await AuthService.signOut();
      debugPrint('FITTRACK: Da ket thuc phien khong ghi nho.');
    } catch (e) {
      debugPrint('FITTRACK: Khong the dang xuat phien cu: $e');
    }
  }

  // 1. Load lịch sử trước
  await DailyHistoryService.loadData();
  debugPrint('4. DailyHistory OK');

  // 2. Load dữ liệu hiện tại
  await HealthService.loadData();
  debugPrint('5. Health OK');
  await NutritionService.loadData();
  debugPrint('6. Nutrition OK');

  // 3. Workout để cuối
  await WorkoutService.loadData();
  debugPrint('7. Workout OK');

  await ProfileService.loadData();
  debugPrint('8. Profile OK');

  debugPrint('9. RUN APP');

  runApp(const FitTrackApp());
}

class FitTrackApp extends StatelessWidget {
  const FitTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FITTRACK AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme.copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FitPageTransitionsBuilder(),
            TargetPlatform.iOS: FitPageTransitionsBuilder(),
            TargetPlatform.windows: FitPageTransitionsBuilder(),
            TargetPlatform.macOS: FitPageTransitionsBuilder(),
            TargetPlatform.linux: FitPageTransitionsBuilder(),
            TargetPlatform.fuchsia: FitPageTransitionsBuilder(),
          },
        ),
      ),

      initialRoute: AppRoutes.splash,

      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.onboarding: (context) => const OnboardingScreen(),

        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),
        AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
        AppRoutes.dashboard: (context) =>
            const CoachProactiveWrapper(child: DashboardScreen()),
        AppRoutes.workout: (context) => const WorkoutScreen(),
        AppRoutes.nutrition: (context) => const NutritionScreen(),
        AppRoutes.health: (context) => const HealthScreen(),
        AppRoutes.aiCoach: (context) =>
            const CoachProactiveWrapper(child: AiCoachScreen()),
        AppRoutes.weeklyReport: (context) => const WeeklyReportScreen(),
        AppRoutes.profile: (context) =>
            const GuardianProfileShortcut(child: ProfileScreen()),
      },
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
