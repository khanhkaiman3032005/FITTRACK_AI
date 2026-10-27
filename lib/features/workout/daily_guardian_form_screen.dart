import 'package:flutter/material.dart';

import '../../services/daily_guardian_service.dart';
import 'health_guardian_profile_screen.dart';

class DailyGuardianFormScreen extends StatefulWidget {
  final VoidCallback onSaved;
  final bool editing;
  const DailyGuardianFormScreen({
    super.key,
    required this.onSaved,
    this.editing = false,
  });

  @override
  State<DailyGuardianFormScreen> createState() =>
      _DailyGuardianFormScreenState();
}

class _DailyGuardianFormScreenState extends State<DailyGuardianFormScreen> {
  bool? _symptoms;
  bool? _tired;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final today = await DailyGuardianService.loadToday();
      if (!mounted) return;
      setState(() {
        _symptoms = today?.symptoms;
        _tired = today?.tired;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _editProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HealthGuardianProfileScreen()),
    );
    if (mounted) await _load();
  }

  Future<void> _submit() async {
    if (_saving || _symptoms == null || _tired == null) return;
    setState(() => _saving = true);
    try {
      final decision = await DailyGuardianService.saveToday(
        symptoms: _symptoms!,
        tired: _tired!,
      );
      if (!mounted) return;
      if (widget.editing) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đã lưu tình trạng hiện tại. Lịch sử cảnh báo vẫn được giữ.',
            ),
          ),
        );
      }
      if (!decision.canStart) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Health Guardian — Cảnh báo'),
            content: Text(decision.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đã hiểu'),
              ),
            ],
          ),
        );
      }
      if (mounted) widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không lưu được phiếu hoặc chưa có hồ sơ sức khỏe: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _choice(String question, bool? selected, ValueChanged<bool> set) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: [
              ChoiceChip(
                label: const Text('Có'),
                selected: selected == true,
                onSelected: (_) => set(true),
              ),
              ChoiceChip(
                label: const Text('Không'),
                selected: selected == false,
                onSelected: (_) => set(false),
              ),
            ],
          ),
          const SizedBox(height: 25),
        ],
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF080D19),
    appBar: AppBar(
      title: Text(
        widget.editing ? 'Cập nhật sức khỏe hôm nay' : 'Phiếu sức khỏe hôm nay',
      ),
      backgroundColor: const Color(0xFF0D1728),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Chỉ cần khai báo khi vào Luyện tập lần đầu mỗi ngày. '
                    'Bạn có thể chủ động cập nhật từ mục Hồ sơ. '
                    'Đây không phải kiểm tra xác nhận đủ điều kiện y tế.',
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: _editProfile,
                    icon: const Icon(Icons.health_and_safety_outlined),
                    label: const Text('Xem / sửa hồ sơ bệnh lý lâu dài'),
                  ),
                  const SizedBox(height: 20),
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.orangeAccent),
                    ),
                    TextButton(onPressed: _load, child: const Text('Thử lại')),
                  ] else ...[
                    _choice(
                      'Hôm nay bạn có đau ngực, khó thở bất thường, chóng mặt, '
                      'muốn ngất, tim đập bất thường hoặc triệu chứng đáng lo?',
                      _symptoms,
                      (v) => setState(() => _symptoms = v),
                    ),
                    _choice(
                      'Hôm nay bạn mệt nhiều hoặc chưa hồi phục?',
                      _tired,
                      (v) => setState(() => _tired = v),
                    ),
                    const Text(
                      'Bạn có thể cập nhật cảm giác hiện tại trong ngày. '
                      'Những triệu chứng đáng lo từng được ghi nhận '
                      'vẫn giữ trong lịch sử và có thể tiếp tục chặn tập. '
                      'Mệt mỏi hiện tại được đánh giá lại mỗi lần lưu.',
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: _saving || _symptoms == null || _tired == null
                          ? null
                          : _submit,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          _saving ? 'Đang lưu...' : 'Lưu phiếu hôm nay',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
  );
}
