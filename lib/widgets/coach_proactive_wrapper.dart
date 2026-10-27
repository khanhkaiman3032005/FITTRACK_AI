import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/coach_checkin_service.dart';

/// Shows one contextual, non-Gemini check-in per local day, per user,
/// when opening Dashboard or AI Coach. Not an OS push notification.
class CoachProactiveWrapper extends StatefulWidget {
  final Widget child;
  const CoachProactiveWrapper({super.key, required this.child});

  @override
  State<CoachProactiveWrapper> createState() => _CoachProactiveWrapperState();
}

class _CoachProactiveWrapperState extends State<CoachProactiveWrapper> {
  static final Set<String> _pendingKeys = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeGreet());
  }

  Future<void> _maybeGreet() async {
    debugPrint('AI COACH: _maybeGreet STARTED');
    final uid = Supabase.instance.client.auth.currentUser?.id;

    debugPrint('AI COACH: Authenticated = ${uid != null}');
    debugPrint('AI COACH: Mounted = $mounted');

    if (uid == null || !mounted) {
      debugPrint('AI COACH: SKIPPED - no user or unmounted');
      return;
    }
    final now = DateTime.now();
    final day = '${now.year}-${now.month}-${now.day}';
    final key = 'hg21_checkin_${uid}_$day';
    if (_pendingKeys.contains(key)) return;
    _pendingKeys.add(key);
    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyShown = prefs.getBool(key) == true;

      debugPrint('AI COACH USER: $uid');
      debugPrint('AI COACH DATE: $day');
      debugPrint('AI COACH ALREADY SHOWN: $alreadyShown');

      if (alreadyShown) return;
      final message = await CoachCheckInService.loadForCurrentUser();
      debugPrint('AI COACH MESSAGE: ${message?.title}');
      if (!mounted ||
          message == null ||
          Supabase.instance.client.auth.currentUser?.id != uid) {
        return;
      }
      if (!mounted || Supabase.instance.client.auth.currentUser?.id != uid) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.favorite_outline, color: Colors.cyanAccent),
              const SizedBox(width: 8),
              Expanded(child: Text(message.title)),
            ],
          ),
          content: Text(message.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      );
      await prefs.setBool(key, true);
      debugPrint('AI COACH: Check-in shown and saved');
    } catch (e, stackTrace) {
      debugPrint('AI COACH CHECK-IN ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _pendingKeys.remove(key);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
