import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../widgets/fittrack_auth_design.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_WelcomePage> _pages = const [
    _WelcomePage(
      icon: Icons.fitness_center_rounded,
      title: 'Luyện tập\nthông minh.',
      eyebrow: '01 / SMART WORKOUT',
      description:
          'Khám phá các bài tập phù hợp với thể trạng, '
          'theo dõi tiến độ và xây dựng thói quen '
          'luyện tập mỗi ngày.',
      color: FitAuthColors.mint,
    ),
    _WelcomePage(
      icon: Icons.restaurant_menu_rounded,
      title: 'Dinh dưỡng\nkhoa học.',
      eyebrow: '02 / SMART NUTRITION',
      description:
          'Theo dõi calories, các dưỡng chất '
          'và nhận diện món ăn qua hình ảnh '
          'cùng FITTRACK AI Camera.',
      color: FitAuthColors.cyan,
    ),
    _WelcomePage(
      icon: Icons.auto_awesome_rounded,
      title: 'Khỏe hơn\ncùng AI.',
      eyebrow: '03 / PERSONAL AI COACH',
      description:
          'Nhận gợi ý tập luyện, dinh dưỡng '
          'và phân tích tiến độ cá nhân '
          'dựa trên dữ liệu sức khỏe của bạn.',
      color: FitAuthColors.violet,
    ),
  ];

  void _goToLogin() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  void _nextPage() {
    if (_currentPage == _pages.length - 1) {
      _goToLogin();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070D18),
      body: FitAuthBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final desktop = constraints.maxWidth >= 850;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1160),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      desktop ? 35 : 20,
                      15,
                      desktop ? 35 : 20,
                      22,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const FitAuthLogo(),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'FITTRACK AI',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _goToLogin,
                              child: const Text('Bỏ qua'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _pages.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentPage = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return _buildPage(_pages[index], desktop);
                            },
                          ),
                        ),
                        const SizedBox(height: 13),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_pages.length, (index) {
                            final selected = index == _currentPage;

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 280),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: selected ? 32 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: selected
                                    ? FitAuthColors.cyan
                                    : const Color(0xFF43536B),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 20),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: FitAuthButton(
                            label: _currentPage == _pages.length - 1
                                ? 'Bắt đầu cùng FITTRACK AI'
                                : 'Tiếp tục',
                            icon: Icons.arrow_forward_rounded,
                            onPressed: _nextPage,
                          ),
                        ),
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

  Widget _buildPage(_WelcomePage page, bool desktop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: desktop
                  ? Row(
                      children: [
                        Expanded(child: _illustration(page, 260)),
                        const SizedBox(width: 55),
                        Expanded(child: _pageText(page, true)),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _illustration(page, 156),
                        const SizedBox(height: 32),
                        _pageText(page, false),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _illustration(_WelcomePage page, double size) {
    return Center(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(page.title),
        tween: Tween<double>(begin: 0.85, end: 1),
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                page.color.withValues(alpha: 0.29),
                const Color(0xFF292040),
              ],
            ),
            borderRadius: BorderRadius.circular(size * 0.23),
            border: Border.all(color: page.color.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: page.color.withValues(alpha: 0.19),
                blurRadius: 55,
                spreadRadius: 7,
              ),
            ],
          ),
          child: Icon(page.icon, size: size * 0.42, color: page.color),
        ),
      ),
    );
  }

  Widget _pageText(_WelcomePage page, bool desktop) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: desktop
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(
          page.eyebrow,
          textAlign: desktop ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            color: page.color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 17),
        Text(
          page.title,
          textAlign: desktop ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            fontSize: desktop ? 48 : 30,
            fontWeight: FontWeight.w900,
            height: 1.13,
          ),
        ),
        const SizedBox(height: 17),
        Text(
          page.description,
          textAlign: desktop ? TextAlign.left : TextAlign.center,
          style: const TextStyle(
            color: FitAuthColors.muted,
            fontSize: 14,
            height: 1.65,
          ),
        ),
      ],
    );
  }
}

class _WelcomePage {
  final IconData icon;
  final String title;
  final String eyebrow;
  final String description;
  final Color color;

  const _WelcomePage({
    required this.icon,
    required this.title,
    required this.eyebrow,
    required this.description,
    required this.color,
  });
}
