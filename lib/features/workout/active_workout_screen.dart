import 'rep_camera/camera_rep_counter_screen.dart';
import '../../widgets/fittrack_motion.dart';
import 'workout_design.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import 'workout_screen.dart';
import '../../services/health_service.dart';
import '../../services/workout_service.dart';

import '../../services/daily_history_service.dart';

import '../../services/health_guardian_service.dart';
import 'post_workout_check_screen.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final ExerciseData exercise;

  const ActiveWorkoutScreen({super.key, required this.exercise});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  Timer? _timer;

  int _seconds = 0;
  int _currentSet = 1;
  int _reps = 0;

  // Tổng số reps của tất cả các hiệp
  int _totalReps = 0;
  bool _isRunning = true;
  bool _isFinishing = false;
  bool _guardianAuthorized = false;
  bool _confirmingSafetyStop = false;
  bool _safetyStopping = false;

  @override
  void initState() {
    super.initState();
    try {
      _guardianAuthorized = HealthGuardianService.consumeApproval(
        widget.exercise.name,
      );
    } catch (_) {
      _guardianAuthorized = false;
    }
    if (_guardianAuthorized) _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isRunning && mounted) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  void _toggleTimer() {
    setState(() {
      _isRunning = !_isRunning;
    });
  }

  String get _formattedTime {
    final minutes = _seconds ~/ 60;
    final seconds = _seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  void _increaseRep() {
    setState(() {
      _reps++;
    });
  }

  void _decreaseRep() {
    if (_reps == 0) return;

    setState(() {
      _reps--;
    });
  }

  void _nextSet() {
    if (_isFinishing || _confirmingSafetyStop || _safetyStopping) return;

    if (_currentSet >= widget.exercise.sets) {
      _finishWorkout();
      return;
    }

    _totalReps += _reps;

    setState(() {
      _currentSet++;
      _reps = 0;
    });
  }

  Future<void> _reportSymptomsAndStop() async {
    if (_confirmingSafetyStop || _safetyStopping || !mounted) return;

    // Pause immediately; rep controls and the workout clock must not continue
    // while the user is responding to a possible health emergency.
    final wasRunning = _isRunning;
    setState(() {
      _confirmingSafetyStop = true;
      _isRunning = false;
    });

    bool confirmed = false;
    try {
      confirmed =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Dừng tập vì dấu hiệu bất thường'),
              content: const Text(
                'Nếu có đau ngực, khó thở bất thường, chóng mặt, '
                'muốn ngất hoặc dấu hiệu đáng lo ngại, hãy dừng vận động. '
                'Nếu có dấu hiệu cấp cứu, gọi 115 tại Việt Nam.\n\n'
                'Bạn muốn dừng và ghi nhận cảnh báo?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Quay lại'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Dừng và ghi nhận'),
                ),
              ],
            ),
          ) ??
          false;
    } finally {
      if (mounted) {
        setState(() {
          _confirmingSafetyStop = false;
          if (!confirmed && !_isFinishing && !_safetyStopping) {
            _isRunning = wasRunning;
          }
        });
      }
    }

    if (!confirmed || !mounted) return;

    setState(() {
      _safetyStopping = true;
      _isRunning = false;
      _isFinishing = true;
    });
    _timer?.cancel();

    try {
      await HealthGuardianService.saveCheck(
        exerciseName: widget.exercise.name,
        phase: 'during',
        status: 'stopped',
        hasSymptoms: true,
      );
      if (!mounted) return;
      Navigator.pop(context, false);
    } catch (e) {
      if (!mounted) return;
      // Remain stopped even if the network cannot save the warning.
      setState(() => _isFinishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Buổi tập đã dừng. Không lưu được cảnh báo: $e'),
        ),
      );
    }
  }

  Future<void> _startCameraCounter() async {
    if (_isFinishing ||
        _confirmingSafetyStop ||
        _safetyStopping ||
        !_guardianAuthorized) {
      return;
    }
    // The camera is only entered from the already approved workout session.
    setState(() => _isRunning = false);
    final result = await Navigator.push<CameraWorkoutResult>(
      context,
      MaterialPageRoute(
        builder: (_) => CameraRepCounterScreen(
          exerciseName: widget.exercise.name,
          sets: widget.exercise.sets,
          repsPerSet: widget.exercise.repsPerSet,
        ),
      ),
    );
    if (!mounted) return;
    if (result == null) return; // Return to paused manual controls.
    if (result.stoppedForSymptoms) {
      Navigator.pop(context, false); // No calories, no progress.
      return;
    }
    if (result.perSet.length != widget.exercise.sets) return;
    setState(() {
      _seconds += result.elapsedSeconds;
      _currentSet = widget.exercise.sets;
      _totalReps = result.totalReps - result.perSet.last;
      _reps = result.perSet.last;
    });
    // Existing finish flow prompts for RPE and persists calories/history.
    await _finishWorkout();
  }

  Future<void> _finishWorkout() async {
    if (_isFinishing || _confirmingSafetyStop || _safetyStopping) return;

    setState(() {
      _isFinishing = true;
      _isRunning = false;
    });

    _timer?.cancel();

    final safeToComplete = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PostWorkoutCheckScreen(exerciseName: widget.exercise.name),
      ),
    );

    if (!mounted || _safetyStopping) return;

    if (safeToComplete == false) {
      Navigator.pop(context, false);
      return;
    }

    if (safeToComplete == null) {
      setState(() {
        _isFinishing = false;
        _isRunning = true;
      });
      _startTimer();
      return;
    }

    final targetReps = widget.exercise.targetReps;
    final completedReps = _totalReps + _reps;

    // Lấy calories chuẩn từ chuỗi "120 kcal"
    final maxCalories =
        int.tryParse(
          widget.exercise.calories.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;

    // Tính calories theo reps thực tế
    final caloriesBurned = (maxCalories * (completedReps / targetReps))
        .round()
        .clamp(0, maxCalories);
    // Số phút thực tế đã tập
    // Ít nhất 1 phút để test không bị +0 khi tập vài giây
    final workoutMinutes = (_seconds / 60).ceil();

    // Cộng vào thời gian tập hiện tại
    final currentMinutes = HealthService.data.activeMinutes;

    await HealthService.updateProgress(
      activeMinutes: currentMinutes + workoutMinutes,
    );

    await WorkoutService.completeWorkout(caloriesBurned: caloriesBurned);
    await DailyHistoryService.saveTodaySnapshot();

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16233A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: WorkoutColors.cyan, width: 0.8),
          ),
          title: const Text('Hoàn thành! 🎉'),
          content: Text(
            'Bạn đã hoàn thành ${widget.exercise.name}.\n\n'
            'Thời gian: $_formattedTime\n'
            'Tổng số lần: $completedReps reps\n'
            'Calories đã đốt: $caloriesBurned kcal\n'
            'Đã cộng $workoutMinutes phút vào tiến độ hôm nay.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context, true);
              },
              child: const Text('Hoàn tất'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_guardianAuthorized) {
      return Scaffold(
        backgroundColor: const Color(0xFF080D19),
        appBar: AppBar(title: const Text('Yêu cầu kiểm tra sức khỏe')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 50,
                  color: Colors.orangeAccent,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bạn cần hoàn thành phiếu kiểm tra trước khi bắt đầu tập.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Quay lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final exercise = widget.exercise;

    return Scaffold(
      backgroundColor: const Color(0xFF080D19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1728),
        elevation: 0,
        title: const Text(
          'Đang luyện tập',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: WorkoutBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FitEntrance(
                      child: WorkoutHero(
                        eyebrow: 'LIVE WORKOUT SESSION',
                        title: exercise.name,
                        subtitle:
                            '${exercise.category} • ${exercise.difficulty}\n'
                            '${exercise.sets} hiệp • '
                            '${exercise.repsPerSet} lần mỗi hiệp',
                        icon: exercise.icon,
                      ),
                    ),
                    const SizedBox(height: 20),

                    FitEntrance(
                      child: FitGlowCard(
                        accent: WorkoutColors.cyan,
                        padding: const EdgeInsets.all(25),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  color: WorkoutColors.cyan,
                                  size: 19,
                                ),
                                SizedBox(width: 9),
                                Text(
                                  'THỜI GIAN LUYỆN TẬP',
                                  style: TextStyle(
                                    color: Color(0xFF9DC4D8),
                                    fontSize: 11,
                                    letterSpacing: 1.4,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 280),
                              child: Text(
                                _formattedTime,
                                key: ValueKey(_formattedTime),
                                style: const TextStyle(
                                  color: WorkoutColors.cyan,
                                  fontSize: 52,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _isRunning
                                    ? WorkoutColors.mint.withValues(alpha: 0.13)
                                    : WorkoutColors.orange.withValues(
                                        alpha: 0.13,
                                      ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                _isFinishing
                                    ? 'Đang hoàn thành'
                                    : _isRunning
                                    ? '● Đang đếm thời gian'
                                    : 'Ⅱ Đã tạm dừng',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _isRunning
                                      ? WorkoutColors.mint
                                      : WorkoutColors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    Row(
                      children: [
                        Expanded(
                          child: _InfoCard(
                            title: 'Hiệp hiện tại',
                            value: '$_currentSet / ${exercise.sets}',
                            icon: Icons.repeat_rounded,
                            accent: WorkoutColors.purple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoCard(
                            title: 'Calo tham khảo',
                            value: exercise.calories,
                            icon: Icons.local_fire_department_rounded,
                            accent: WorkoutColors.orange,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    FitEntrance(
                      child: FitGlowCard(
                        accent: WorkoutColors.mint,
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Số lần thực hiện',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Text(
                                  'HIỆP $_currentSet/${exercise.sets}',
                                  style: const TextStyle(
                                    color: WorkoutColors.mint,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            FitAnimatedBar(
                              value: (_currentSet - 1) / exercise.sets,
                              color: WorkoutColors.mint,
                            ),
                            const SizedBox(height: 26),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _RoundButton(
                                  icon: Icons.remove_rounded,
                                  onPressed:
                                      _isFinishing ||
                                          _confirmingSafetyStop ||
                                          _safetyStopping
                                      ? null
                                      : _decreaseRep,
                                ),
                                Expanded(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 220),
                                    transitionBuilder: (child, animation) {
                                      return ScaleTransition(
                                        scale: animation,
                                        child: child,
                                      );
                                    },
                                    child: Text(
                                      '$_reps',
                                      key: ValueKey(_reps),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 53,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                                _RoundButton(
                                  icon: Icons.add_rounded,
                                  onPressed:
                                      _isFinishing ||
                                          _confirmingSafetyStop ||
                                          _safetyStopping
                                      ? null
                                      : _increaseRep,
                                ),
                              ],
                            ),
                            const SizedBox(height: 19),
                            Text(
                              'Mục tiêu: ${exercise.repsPerSet} '
                              'lần mỗi hiệp',
                              style: const TextStyle(
                                color: Color(0xFF9FB5C9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      height: 55,
                      child: FilledButton.icon(
                        onPressed:
                            _isFinishing ||
                                _confirmingSafetyStop ||
                                _safetyStopping
                            ? null
                            : _startCameraCounter,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('AI Camera — Tự đếm bài tập'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF089BC2),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: 55,
                      child: FilledButton.icon(
                        onPressed:
                            _isFinishing ||
                                _confirmingSafetyStop ||
                                _safetyStopping
                            ? null
                            : _toggleTimer,
                        icon: Icon(
                          _isRunning
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(
                          _isRunning ? 'Tạm dừng' : 'Tiếp tục',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF243454),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      height: 56,
                      child: FilledButton.icon(
                        onPressed:
                            _isFinishing ||
                                _confirmingSafetyStop ||
                                _safetyStopping
                            ? null
                            : _nextSet,
                        icon: _isFinishing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _currentSet == exercise.sets
                                    ? Icons.check_circle_rounded
                                    : Icons.skip_next_rounded,
                              ),
                        label: Text(
                          _isFinishing
                              ? 'Đang lưu kết quả...'
                              : _currentSet == exercise.sets
                              ? 'Hoàn thành bài tập'
                              : 'Hoàn thành hiệp $_currentSet',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: WorkoutColors.cyan,
                          foregroundColor: const Color(0xFF061624),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16233A),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFFF9D68).withValues(alpha: 0.38),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.health_and_safety_outlined,
                              color: Color(0xFFFFAD76), size: 19),
                          SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'Báo dấu hiệu bất thường',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Dừng buổi tập và ghi nhận cảnh báo sức khỏe khi cần.',
                        style: TextStyle(color: Color(0xFF9FB5C9), fontSize: 12),
                      ),
                      const SizedBox(height: 11),
                      SizedBox(
                        height: 42,
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _confirmingSafetyStop || _safetyStopping ? null : _reportSymptomsAndStop,
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('Dừng tập an toàn'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF493345),
                            foregroundColor: const Color(0xFFFFD5C3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return FitGlowCard(
      accent: accent,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 108,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 24),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF9FB3C8), fontSize: 11),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _RoundButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF13637B), Color(0xFF43316D)],
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: WorkoutColors.cyan.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: WorkoutColors.cyan.withValues(alpha: 0.11),
            blurRadius: 18,
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: Colors.white,
        iconSize: 28,
        padding: const EdgeInsets.all(15),
      ),
    );
  }
}
