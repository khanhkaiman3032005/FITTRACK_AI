import 'package:flutter/material.dart';

import '../../services/health_guardian_service.dart';

class PostWorkoutCheckScreen extends StatefulWidget {
  final String exerciseName;

  const PostWorkoutCheckScreen({super.key, required this.exerciseName});

  @override
  State<PostWorkoutCheckScreen> createState() => _PostWorkoutCheckScreenState();
}

class _PostWorkoutCheckScreenState extends State<PostWorkoutCheckScreen> {
  int _rpe = 4;
  bool? _hasSymptoms;
  bool _saving = false;

  Future<void> _submit() async {
    if (_saving) return;

    if (_hasSymptoms == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng trả lời câu hỏi triệu chứng.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final status = _hasSymptoms!
          ? 'stopped'
          : _rpe >= 9
          ? 'high_effort'
          : 'completed';

      await HealthGuardianService.saveCheck(
        exerciseName: widget.exerciseName,
        phase: 'after',
        status: status,
        hasSymptoms: _hasSymptoms!,
        rpe: _rpe,
      );

      if (!mounted) return;

      if (_hasSymptoms!) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Dừng tập và kiểm tra sức khỏe'),
            content: const Text(
              'Bạn đã ghi nhận triệu chứng bất thường. '
              'Không tiếp tục luyện tập. '
              'Hãy tìm hỗ trợ y tế phù hợp; nếu có '
              'dấu hiệu cấp cứu, gọi 115 tại Việt Nam.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Đã hiểu'),
              ),
            ],
          ),
        );
      } else if (_rpe >= 9) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Mức gắng sức rất cao'),
            content: const Text(
              'Bạn đã báo cáo mức gắng sức rất cao. '
              'Hãy chú ý hồi phục và không tự động '
              'tăng cường độ buổi tập tiếp theo.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Đã hiểu'),
              ),
            ],
          ),
        );
      }

      if (!mounted) return;
      Navigator.pop(context, !_hasSymptoms!);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không thể lưu phiếu: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080D19),
      appBar: AppBar(
        title: const Text('Đánh giá sau buổi tập'),
        backgroundColor: const Color(0xFF0D1728),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Bạn cảm thấy thế nào sau '
                  '${widget.exerciseName}?',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                Text(
                  'Mức gắng sức cảm nhận: $_rpe/10',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Slider(
                  value: _rpe.toDouble(),
                  min: 0,
                  max: 10,
                  divisions: 10,
                  label: '$_rpe',
                  onChanged: (value) {
                    setState(() => _rpe = value.round());
                  },
                ),
                const Text(
                  '0 = Không gắng sức; '
                  '10 = Gắng sức tối đa.',
                ),
                const SizedBox(height: 24),
                const Text(
                  'Trong hoặc sau buổi tập, bạn có '
                  'đau ngực, khó thở bất thường, '
                  'chóng mặt, muốn ngất, tim đập '
                  'bất thường hoặc dấu hiệu đáng lo ngại?',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  children: [
                    ChoiceChip(
                      label: const Text('Có'),
                      selected: _hasSymptoms == true,
                      onSelected: (_) {
                        setState(() => _hasSymptoms = true);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Không'),
                      selected: _hasSymptoms == false,
                      onSelected: (_) {
                        setState(() => _hasSymptoms = false);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(_saving ? 'Đang lưu...' : 'Lưu đánh giá'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
