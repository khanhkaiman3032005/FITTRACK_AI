import 'package:flutter/material.dart';

class FitEntrance extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const FitEntrance({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 650),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, animatedChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 22),
            child: animatedChild,
          ),
        );
      },
      child: child,
    );
  }
}

class FitGlowCard extends StatefulWidget {
  final Widget child;
  final Color accent;
  final EdgeInsetsGeometry padding;

  const FitGlowCard({
    super.key,
    required this.child,
    required this.accent,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  State<FitGlowCard> createState() => _FitGlowCardState();
}

class _FitGlowCardState extends State<FitGlowCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.018 : 1,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: widget.padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF18243A),
                const Color(0xFF101827),
                widget.accent.withValues(alpha: 0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: widget.accent.withValues(alpha: _hovered ? 0.65 : 0.20),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accent.withValues(alpha: _hovered ? 0.16 : 0.045),
                blurRadius: _hovered ? 28 : 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class FitAnimatedBar extends StatelessWidget {
  final double value;
  final Color color;

  const FitAnimatedBar({
    super.key,
    required this.value,
    this.color = const Color(0xFF00C2FF),
  });

  @override
  Widget build(BuildContext context) {
    final progress = value.clamp(0.0, 1.0).toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: 9,
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF263247),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress),
                duration: const Duration(milliseconds: 850),
                curve: Curves.easeOutCubic,
                builder: (context, animatedValue, child) {
                  return Container(
                    width: constraints.maxWidth * animatedValue,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.65), color],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.30),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class FitGlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  const FitGlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(24);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF152238).withValues(alpha: 0.95),
            const Color(0xFF101827).withValues(alpha: 0.96),
            const Color(0xFF1A1A35).withValues(alpha: 0.92),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C2FF).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class FitSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accent;

  const FitSectionTitle({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.accent = const Color(0xFF00C2FF),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: Color(0xFF9FB3C8),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class FitBackdrop extends StatelessWidget {
  final Widget child;

  const FitBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF08182A),
                Color(0xFF080D1B),
                Color(0xFF171029),
                Color(0xFF080D19),
              ],
              stops: [0.0, 0.38, 0.75, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -130,
          right: -120,
          child: IgnorePointer(
            child: Container(
              width: 360,
              height: 360,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x3322C5FF), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          left: -130,
          child: IgnorePointer(
            child: Container(
              width: 400,
              height: 400,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x287C3AED), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class FitPageTransitionsBuilder extends PageTransitionsBuilder {
  const FitPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }

    final entrance = animation.drive(CurveTween(curve: Curves.easeOutCubic));

    final background = secondaryAnimation.drive(
      CurveTween(curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: entrance,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.045, 0.025),
          end: Offset.zero,
        ).animate(entrance),
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 0.985).animate(background),
          child: child,
        ),
      ),
    );
  }
}
