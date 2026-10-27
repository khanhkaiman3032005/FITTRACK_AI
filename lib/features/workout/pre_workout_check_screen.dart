import 'package:flutter/material.dart';

import '../../services/exercise_safety_engine.dart';
import '../../services/health_guardian_service.dart';
import 'health_guardian_profile_screen.dart';
import 'active_workout_screen.dart';
import 'workout_screen.dart';

class PreWorkoutCheckScreen extends StatefulWidget {
  final ExerciseData exercise;
  const PreWorkoutCheckScreen({super.key, required this.exercise});
  @override
  State<PreWorkoutCheckScreen> createState() => _PreWorkoutCheckScreenState();
}

class _PreWorkoutCheckScreenState extends State<PreWorkoutCheckScreen> {
  GuardianHealthProfile? _profile;
  bool? _symptoms;
  bool? _tired;
  bool _highRpe = false;
  bool _busy = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    HealthGuardianService.clearApproval();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final profile = await HealthGuardianService.loadProfile();
      final high = await HealthGuardianService.hasRecentVeryHighEffort();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _highRpe = high;
        _busy = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _busy = false;
        });
      }
    }
  }

  Future<void> _editProfile() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const HealthGuardianProfileScreen()),
    );
    if (mounted && result == true) await _load();
  }

  Widget _binary(String question, bool? value, ValueChanged<bool> onChange) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              children: [
                ChoiceChip(
                  label: const Text('Có'),
                  selected: value == true,
                  onSelected: (_) => onChange(true),
                ),
                ChoiceChip(
                  label: const Text('Không'),
                  selected: value == false,
                  onSelected: (_) => onChange(false),
                ),
              ],
            ),
          ],
        ),
      );
  Future<void> _show(String text) => showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Health Guardian'),
      content: Text(text),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Đã hiểu'),
        ),
      ],
    ),
  );

  Future<void> _proceed() async {
    if (_saving || _profile == null) return;
    if (_symptoms == null || _tired == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng trả lời đủ hai câu hỏi.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      // Đọc lại hồ sơ ngay trước quyết định để tránh dùng dữ liệu stale.
      final currentProfile = await HealthGuardianService.loadProfile();
      final currentHighRpe =
          await HealthGuardianService.hasRecentVeryHighEffort();
      if (currentProfile == null) throw StateError('Hồ sơ chưa tồn tại.');
      final decision = ExerciseSafetyEngine.assess(
        hasProfile: true,
        hasCondition: currentProfile.hasCondition,
        hasSymptoms: _symptoms!,
        veryTired: _tired!,
        recentVeryHighEffort: currentHighRpe,
      );
      await HealthGuardianService.saveCheck(
        exerciseName: widget.exercise.name,
        phase: 'before',
        status: decision.canStart ? 'recorded' : 'blocked',
        hasSymptoms: _symptoms!,
        isTired: _tired!,
        decisionCode: decision.code,
      );
      if (!mounted) return;
      if (!decision.canStart) {
        await _show(decision.message);
        return;
      }
      HealthGuardianService.approveForOnce(widget.exercise.name);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveWorkoutScreen(exercise: widget.exercise),
        ),
      );
    } catch (e) {
      HealthGuardianService.clearApproval();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể kiểm tra hoặc lưu phiếu: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF080D19),
    appBar: AppBar(
      title: const Text('Kiểm tra trước khi tập'),
      backgroundColor: const Color(0xFF0D1728),
    ),
    body: _busy
        ? const Center(child: CircularProgressIndicator())
        : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Chuẩn bị tập ${widget.exercise.name}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Phiếu giúp ghi nhận rủi ro tự khai báo; không xác nhận đủ điều kiện y tế.',
                  ),
                  const SizedBox(height: 22),
                  if (_error != null) ...[
                    Text(
                      'Không tải được thông tin: $_error',
                      style: const TextStyle(color: Colors.orangeAccent),
                    ),
                    OutlinedButton(
                      onPressed: _load,
                      child: const Text('Tải lại'),
                    ),
                  ] else ...[
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.health_and_safety_outlined),
                        title: Text(
                          _profile == null
                              ? 'Chưa có hồ sơ an toàn'
                              : _profile!.hasCondition
                              ? 'Đã khai báo vấn đề sức khỏe'
                              : 'Hồ sơ không khai báo hạn chế vận động',
                        ),
                        subtitle: const Text(
                          'Chạm để tạo hoặc chỉnh sửa hồ sơ lâu dài',
                        ),
                        trailing: const Icon(Icons.edit),
                        onTap: _editProfile,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_profile == null)
                      const Text('Bạn cần tạo hồ sơ trước khi tiếp tục.')
                    else ...[
                      _binary(
                        'Bạn đang có đau ngực, khó thở bất thường, '
                        'chóng mặt, muốn ngất, tim đập bất thường hoặc triệu chứng đáng lo?',
                        _symptoms,
                        (v) => setState(() => _symptoms = v),
                      ),
                      _binary(
                        'Bạn đang mệt nhiều hoặc chưa hồi phục?',
                        _tired,
                        (v) => setState(() => _tired = v),
                      ),
                      if (_highRpe)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'RPE trong 24 giờ qua rất cao. Ứng dụng đề nghị '
                              'nghỉ và đánh giá lại, không tự động bắt đầu tập.',
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: _saving ? null : _proceed,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            _saving
                                ? 'Đang kiểm tra...'
                                : 'Kiểm tra và tiếp tục',
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
  );
}
