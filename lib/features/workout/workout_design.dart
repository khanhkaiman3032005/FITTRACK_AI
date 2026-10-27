import 'package:flutter/material.dart';

class WorkoutBackdrop extends StatelessWidget {
  final Widget child;

  const WorkoutBackdrop({super.key, required this.child});

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
                  Color(0xFF081E30),
                  Color(0xFF090F1F),
                  Color(0xFF1D1234),
                  Color(0xFF080D19),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -140,
          right: -130,
          child: IgnorePointer(
            child: Container(
              width: 370,
              height: 370,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x3300D3FF), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -160,
          left: -140,
          child: IgnorePointer(
            child: Container(
              width: 420,
              height: 420,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x338B5CF6), Colors.transparent],
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

class WorkoutHero extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;

  const WorkoutHero({
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
        final compact = constraints.maxWidth < 520;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 22 : 30),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF104D63), Color(0xFF172C49), Color(0xFF30204F)],
            ),
            borderRadius: BorderRadius.circular(27),
            border: Border.all(
              color: const Color(0xFF00D1FF).withValues(alpha: 0.30),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C2FF).withValues(alpha: 0.10),
                blurRadius: 30,
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
                        color: Color(0xFF83E9FF),
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 13),
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 24 : 32,
                        fontWeight: FontWeight.w900,
                        height: 1.17,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFFC5D7E8),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: compact ? 58 : 92,
                height: compact ? 58 : 92,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF80E9FF),
                  size: compact ? 29 : 46,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class WorkoutColors {
  static const cyan = Color(0xFF00C9F5);
  static const purple = Color(0xFFA78BFA);
  static const mint = Color(0xFF2DD4BF);
  static const orange = Color(0xFFFFB15C);
  static const pink = Color(0xFFFF7185);

  static Color forCategory(String category) {
    switch (category) {
      case 'Chân':
        return mint;
      case 'Ngực':
        return pink;
      case 'Core':
        return purple;
      case 'Vai':
        return orange;
      case 'Toàn thân':
        return cyan;
      default:
        return cyan;
    }
  }
}
