import 'package:flutter/material.dart';

class FitAuthColors {
  static const cyan = Color(0xFF12C9F5);
  static const violet = Color(0xFFA78BFA);
  static const mint = Color(0xFF2DD4BF);
  static const muted = Color(0xFFA6BED0);
}

class FitAuthBackdrop extends StatefulWidget {
  final Widget child;

  const FitAuthBackdrop({super.key, required this.child});

  @override
  State<FitAuthBackdrop> createState() => _FitAuthBackdropState();
}

class _FitAuthBackdropState extends State<FitAuthBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        final t = _animation.value;

        return Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF071E2D),
                      Color(0xFF080F20),
                      Color(0xFF1C1334),
                      Color(0xFF070C18),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -160 + 55 * t,
              right: -130 + 40 * t,
              child: const IgnorePointer(
                child: _AuthGlow(size: 440, color: Color(0x3A00CBF5)),
              ),
            ),
            Positioned(
              bottom: -170 + 40 * t,
              left: -150 + 50 * t,
              child: const IgnorePointer(
                child: _AuthGlow(size: 460, color: Color(0x329B76FA)),
              ),
            ),
            Positioned.fill(child: child!),
          ],
        );
      },
    );
  }
}

class _AuthGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _AuthGlow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

class FitAuthLogo extends StatelessWidget {
  final bool large;

  const FitAuthLogo({super.key, this.large = false});

  @override
  Widget build(BuildContext context) {
    final size = large ? 102.0 : 51.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF087D9D), Color(0xFF4A3588)],
        ),
        borderRadius: BorderRadius.circular(large ? 29 : 16),
        border: Border.all(
          color: const Color(0xFF6AEAFF).withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: FitAuthColors.cyan.withValues(alpha: 0.23),
            blurRadius: large ? 38 : 18,
            spreadRadius: large ? 3 : 0,
          ),
        ],
      ),
      child: Icon(
        Icons.monitor_heart_rounded,
        size: large ? 55 : 28,
        color: Colors.white,
      ),
    );
  }
}

class FitAuthCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const FitAuthCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(26),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xEF17273C), Color(0xF0141B31), Color(0xEE241A3B)],
        ),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: FitAuthColors.cyan.withValues(alpha: 0.21)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class FitAuthButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;

  const FitAuthButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: FilledButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        label: Text(
          loading ? 'Đang xử lý...' : label,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: FitAuthColors.cyan,
          foregroundColor: const Color(0xFF061624),
          disabledBackgroundColor: const Color(0xFF245269),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class FitAuthAppearance extends StatelessWidget {
  final Widget child;

  const FitAuthAppearance({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0E1C30),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 18,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: FitAuthColors.cyan.withValues(alpha: 0.19),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: FitAuthColors.cyan, width: 1.6),
          ),
        ),
      ),
      child: child,
    );
  }
}
