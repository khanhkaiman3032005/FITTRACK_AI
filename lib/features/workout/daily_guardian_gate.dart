import 'package:flutter/material.dart';

import '../../services/daily_guardian_service.dart';
import 'active_workout_screen.dart';
import 'daily_guardian_form_screen.dart';
import 'health_guardian_profile_screen.dart';
import 'workout_screen.dart';

/// One daily check on entering the Workout section. Reevaluate current
/// profile and any current-day workout symptoms on every entrance.
class DailyGuardianWorkoutGate extends StatefulWidget {
  const DailyGuardianWorkoutGate({super.key});
  @override
  State<DailyGuardianWorkoutGate> createState() =>
      _DailyGuardianWorkoutGateState();
}

class _DailyGuardianWorkoutGateState extends State<DailyGuardianWorkoutGate> {
  DailyGuardianState? _state;
  String? _error;
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final result = await DailyGuardianService.evaluateToday();
      if (mounted) {
        setState(() {
          _state = result;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _waiting('Đang kiểm tra phiếu sức khỏe hôm nay...');
    if (_error != null) {
      return _blocked('Không tải được dữ liệu sức khỏe: $_error');
    }
    if (_state!.needsForm) {
      return DailyGuardianFormScreen(onSaved: _refresh);
    }
    if (!_state!.canStart) return _blocked(_state!.decision!.message);
    return const WorkoutCatalogScreen();
  }

  Widget _waiting(String message) => Scaffold(
    backgroundColor: const Color(0xFF080D19),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message),
        ],
      ),
    ),
  );

  Widget _blocked(String message) => Scaffold(
    backgroundColor: const Color(0xFF080D19),
    appBar: AppBar(title: const Text('An toàn luyện tập')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.shield_outlined,
                color: Colors.orangeAccent,
                size: 54,
              ),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HealthGuardianProfileScreen(),
                    ),
                  );
                  if (mounted) await _refresh();
                },
                icon: const Icon(Icons.edit_note),
                label: const Text('Xem / cập nhật hồ sơ sức khỏe'),
              ),
              TextButton.icon(
                onPressed: () async {
                  await Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (screenContext) => DailyGuardianFormScreen(
                        editing: true,
                        onSaved: () => Navigator.pop(screenContext),
                      ),
                    ),
                  );
                  if (mounted) await _refresh();
                },
                icon: const Icon(Icons.event_note_outlined),
                label: const Text('Cập nhật tình trạng hôm nay'),
              ),
              TextButton(
                onPressed: _refresh,
                child: const Text('Kiểm tra lại'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Called from each exercise detail, including deep links to detail pages.
/// It never asks the questionnaire again if today's record exists.
class DailyGuardianExerciseGate extends StatefulWidget {
  final ExerciseData exercise;
  const DailyGuardianExerciseGate({super.key, required this.exercise});
  @override
  State<DailyGuardianExerciseGate> createState() =>
      _DailyGuardianExerciseGateState();
}

class _DailyGuardianExerciseGateState extends State<DailyGuardianExerciseGate> {
  DailyGuardianState? _state;
  String? _error;
  bool _loading = true;
  bool _authorized = false;

  @override
  void initState() {
    super.initState();
    _verify();
  }

  Future<void> _verify() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final result = await DailyGuardianService.authorizeExercise(
        widget.exercise.name,
      );
      if (!mounted) return;
      setState(() {
        _state = result;
        _authorized = result.canStart;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return _blocked('Không xác minh được phiếu hôm nay: $_error');
    }
    if (_state!.needsForm) return DailyGuardianFormScreen(onSaved: _verify);
    if (!_authorized) return _blocked(_state!.decision!.message);
    return ActiveWorkoutScreen(exercise: widget.exercise);
  }

  Widget _blocked(String message) => Scaffold(
    appBar: AppBar(title: const Text('Chưa thể bắt đầu luyện tập')),
    backgroundColor: const Color(0xFF080D19),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orangeAccent,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _verify,
                child: const Text('Kiểm tra lại'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Quay về bài tập'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
