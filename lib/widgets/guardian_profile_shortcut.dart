import 'package:flutter/material.dart';

import '../features/workout/daily_guardian_form_screen.dart';
import '../features/workout/health_guardian_profile_screen.dart';

/// Add a compact access point without replacing the current Profile UI.
class GuardianProfileShortcut extends StatelessWidget {
  final Widget child;
  const GuardianProfileShortcut({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      child,
      Positioned(
        right: 14,
        bottom: 92,
        child: SafeArea(
          child: FloatingActionButton.extended(
            heroTag: 'guardian-profile-shortcut',
            backgroundColor: const Color(0xFF0D6682),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.health_and_safety_outlined),
            label: const Text('Hồ sơ sức khỏe'),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (sheetContext) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Wrap(
                    children: [
                      ListTile(
                        title: const Text('Hồ sơ bệnh lý lâu dài'),
                        leading: const Icon(Icons.health_and_safety_outlined),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const HealthGuardianProfileScreen(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        title: const Text('Cập nhật tình trạng hôm nay'),
                        leading: const Icon(Icons.event_note),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (screenContext) =>
                                  DailyGuardianFormScreen(
                                    editing: true,
                                    onSaved: () => Navigator.pop(screenContext),
                                  ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
