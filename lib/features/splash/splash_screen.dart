import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../widgets/fittrack_auth_design.dart';
import '../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      final nextRoute = AuthService.isLoggedIn
          ? AppRoutes.dashboard
          : AppRoutes.onboarding;

      Navigator.pushReplacementNamed(context, nextRoute);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070D18),
      body: FitAuthBackdrop(
        child: SafeArea(
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 25 * (1 - value)),
                    child: Transform.scale(
                      scale: 0.8 + value * 0.2,
                      child: child,
                    ),
                  ),
                );
              },
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FitAuthLogo(large: true),
                  SizedBox(height: 29),
                  Text(
                    'FITTRACK AI',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2.1,
                    ),
                  ),
                  SizedBox(height: 11),
                  Text(
                    'TRAIN SMARTER • LIVE HEALTHIER',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: FitAuthColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 53),
                  SizedBox(
                    width: 130,
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      backgroundColor: Color(0xFF23364C),
                      color: FitAuthColors.cyan,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Đang khởi động trải nghiệm...',
                    style: TextStyle(color: FitAuthColors.muted, fontSize: 12),
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
