import 'package:flutter/material.dart';

class HealthBackdrop extends StatelessWidget {
  final Widget child;

  const HealthBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF081C2B),
                  Color(0xFF090F1E),
                  Color(0xFF1A1130),
                  Color(0xFF080D19),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -150,
          right: -130,
          child: IgnorePointer(
            child: Container(
              width: 380,
              height: 380,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x3322C7FF), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -140,
          left: -110,
          child: IgnorePointer(
            child: Container(
              width: 360,
              height: 360,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x288B5CF6), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class HealthHero extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;

  const HealthHero({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 550;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 21 : 30),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF124554), Color(0xFF172A47), Color(0xFF2B1F49)],
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: const Color(0xFF35D6FF).withValues(alpha: 0.28),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C8F8).withValues(alpha: 0.09),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: const TextStyle(
                        color: Color(0xFF84E9FF),
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: compact ? 23 : 29,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFC2D4E2),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Container(
                width: compact ? 53 : 78,
                height: compact ? 53 : 78,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Icon(
                  icon,
                  size: compact ? 28 : 39,
                  color: const Color(0xFF72E4FF),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class HealthRing extends StatelessWidget {
  final String label;
  final double progress;
  final Color color;

  const HealthRing({
    super.key,
    required this.label,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = progress.clamp(0.0, 1.0).toDouble();

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: normalized),
      duration: const Duration(milliseconds: 1050),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 66,
              height: 66,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: animatedValue,
                      strokeWidth: 7,
                      strokeCap: StrokeCap.round,
                      backgroundColor: const Color(0xFF293449),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  Text(
                    '${(animatedValue * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFB8CBDE),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }
}

class HealthInput extends StatelessWidget {
  final String title;
  final String unit;
  final IconData icon;
  final Color accent;
  final TextEditingController controller;
  final bool decimal;

  const HealthInput({
    super.key,
    required this.title,
    required this.unit,
    required this.icon,
    required this.controller,
    required this.accent,
    this.decimal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: accent),
            suffixText: unit,
            suffixStyle: const TextStyle(color: Color(0xFF9FB3C8)),
            filled: true,
            fillColor: const Color(0xFF0E1A2D),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 18,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: accent.withValues(alpha: 0.20)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: accent, width: 1.6),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }
}
