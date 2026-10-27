import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/nutrition_service.dart';
import '../../services/health_service.dart';
import '../../services/workout_service.dart';
import '../../services/daily_history_service.dart';
import '../../widgets/fittrack_auth_design.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  bool _googleRequested = false;
  bool _completingGoogleLogin = false;

  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();

    _loadRememberPreference();

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        if (_googleRequested &&
            data.event == AuthChangeEvent.signedIn &&
            data.session != null) {
          _completeGoogleLogin();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Google Auth error: $error');
      },
    );
  }

  Future<void> _loadRememberPreference() async {
    final remember = await AuthService.getRememberLogin();

    if (!mounted) return;

    setState(() {
      _rememberMe = remember;
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithGoogle() async {
    if (_isLoading) return;

    _googleRequested = true;

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.setRememberLogin(_rememberMe);
      await AuthService.markGoogleOAuthPending();

      final started = await AuthService.signInWithGoogle();

      if (!started) {
        _googleRequested = false;
        await AuthService.clearGoogleOAuthPending();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở đăng nhập Google.')),
        );
      }
    } catch (e) {
      _googleRequested = false;
      await AuthService.clearGoogleOAuthPending();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể đăng nhập Google: $e')));
    } finally {
      if (mounted && !_completingGoogleLogin) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _completeGoogleLogin() async {
    if (_completingGoogleLogin || !mounted) return;

    _completingGoogleLogin = true;
    _googleRequested = false;

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.clearGoogleOAuthPending();

      await ProfileService.loadData();
      await HealthService.loadData();
      await NutritionService.loadData();
      await WorkoutService.loadData();
      await DailyHistoryService.loadData();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.dashboard,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải dữ liệu tài khoản: $e')),
      );
    } finally {
      _completingGoogleLogin = false;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      _googleRequested = false;

      await AuthService.clearGoogleOAuthPending();
      await AuthService.setRememberLogin(_rememberMe);

      final response = await AuthService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null) {
        // Sau khi đăng nhập thành công,
        // tải lại toàn bộ dữ liệu của đúng tài khoản hiện tại.

        await ProfileService.loadData();
        await HealthService.loadData();
        await NutritionService.loadData();
        await WorkoutService.loadData();
        await DailyHistoryService.loadData();

        if (!mounted) return;

        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.dashboard,
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;

      String message = 'Đăng nhập thất bại. Vui lòng thử lại.';

      final error = e.toString().toLowerCase();

      if (error.contains('invalid login credentials')) {
        message = 'Email hoặc mật khẩu không chính xác.';
      } else if (error.contains('email not confirmed')) {
        message = 'Bạn chưa xác nhận email. Vui lòng kiểm tra hộp thư.';
      } else if (error.contains('invalid email')) {
        message = 'Email không hợp lệ.';
      } else if (error.contains('network') ||
          error.contains('socket') ||
          error.contains('connection')) {
        message = 'Không thể kết nối máy chủ. Vui lòng kiểm tra mạng.';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070D18),
      body: FitAuthBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final desktop = constraints.maxWidth >= 950;

              final form = Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: desktop ? 32 : 18,
                    vertical: 25,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 490),
                    child: FitAuthAppearance(
                      child: FitAuthCard(child: _buildLoginForm()),
                    ),
                  ),
                ),
              );

              if (!desktop) return form;

              return Row(
                children: [
                  Expanded(flex: 11, child: _buildDesktopBanner()),
                  Expanded(flex: 10, child: form),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopBanner() {
    return Padding(
      padding: const EdgeInsets.all(36),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF11475C), Color(0xFF172C49), Color(0xFF302044)],
          ),
          borderRadius: BorderRadius.circular(29),
          border: Border.all(color: FitAuthColors.cyan.withValues(alpha: 0.27)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FitAuthLogo(large: true),
            const SizedBox(height: 30),
            const Text(
              'FITTRACK AI',
              style: TextStyle(
                color: FitAuthColors.cyan,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Mỗi ngày một\nphiên bản tốt hơn.',
              style: TextStyle(
                fontSize: 39,
                height: 1.18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Một không gian để theo dõi tập luyện, '
              'dinh dưỡng và sức khỏe — được hỗ trợ bởi AI.',
              style: TextStyle(
                fontSize: 14,
                height: 1.7,
                color: Color(0xFFC7D9E6),
              ),
            ),
            const SizedBox(height: 35),
            _feature(Icons.fitness_center_rounded, 'Luyện tập theo mục tiêu'),
            const SizedBox(height: 14),
            _feature(Icons.restaurant_menu_rounded, 'Dinh dưỡng thông minh'),
            const SizedBox(height: 14),
            _feature(Icons.auto_awesome_rounded, 'Trợ lý sức khỏe AI'),
          ],
        ),
      ),
    );
  }

  Widget _feature(IconData icon, String title) {
    return Row(
      children: [
        Container(
          width: 37,
          height: 37,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: FitAuthColors.cyan, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMobileLogo(),

          const SizedBox(height: 35),

          const Text(
            'Chào mừng trở lại!',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          const Text(
            'Đăng nhập để tiếp tục hành trình sức khỏe của bạn.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 35),

          const Text('Email', style: TextStyle(fontWeight: FontWeight.w600)),

          const SizedBox(height: 10),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              hintText: 'example@gmail.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập email';
              }

              final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

              if (!emailRegex.hasMatch(value.trim())) {
                return 'Email không hợp lệ';
              }

              return null;
            },
          ),

          const SizedBox(height: 22),

          const Text('Mật khẩu', style: TextStyle(fontWeight: FontWeight.w600)),

          const SizedBox(height: 10),

          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              hintText: 'Nhập mật khẩu',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập mật khẩu';
              }

              if (value.length < 6) {
                return 'Mật khẩu phải có ít nhất 6 ký tự';
              }

              return null;
            },
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
              ),
              const Text('Ghi nhớ đăng nhập'),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.forgotPassword);
                },
                child: const Text('Quên mật khẩu?'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          FitAuthButton(
            label: 'Đăng nhập',
            icon: Icons.login_rounded,
            loading: _isLoading,
            onPressed: _login,
          ),

          const SizedBox(height: 28),

          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'Hoặc',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),

          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _loginWithGoogle,
              icon: const Icon(Icons.g_mobiledata_rounded, size: 30),
              label: const Text('Tiếp tục với Google'),
            ),
          ),

          const SizedBox(height: 30),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Chưa có tài khoản?',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.register);
                },
                child: const Text(
                  'Đăng ký',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLogo() {
    return const Row(
      children: [
        FitAuthLogo(),
        SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FITTRACK AI',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'YOUR PERSONAL FITNESS SPACE',
                style: TextStyle(
                  color: FitAuthColors.muted,
                  fontSize: 9,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
